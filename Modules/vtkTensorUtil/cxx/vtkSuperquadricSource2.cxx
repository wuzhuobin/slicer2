/*=========================================================================

  Program:   Visualization Toolkit
  Module:    $RCSfile: vtkSuperquadricSource2.cxx,v $

  Copyright (c) Ken Martin, Will Schroeder, Bill Lorensen
  All rights reserved.
  See Copyright.txt or http://www.kitware.com/Copyright.htm for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.  See the above copyright notice for more information.

=========================================================================*/
/* vtkSuperquadric originally written by Us, 
   Brigham and Women's Hospital, July 1998.

   Based on "Rigid physically based superquadrics", A. H. Barr,
   in "Graphics Gems III", David Kirk, ed., Academic Press, 1992.
*/
#include "vtkSuperquadricSource2.h"

#include "vtkCellArray.h"
#include "vtkFloatArray.h"
#include "vtkMath.h"
#include "vtkObjectFactory.h"
#include "vtkPointData.h"
#include "vtkPoints.h"
#include "vtkPolyData.h"

#include <math.h>

vtkCxxRevisionMacro(vtkSuperquadricSource2, "$Revision: 1.1 $");
vtkStandardNewMacro(vtkSuperquadricSource2);

static void evalSuperquadric2(double u, double v, 
                             double du, double dv,
                             double n, double e, 
                             double dims[3],  
                             double xyz[3], 
                             double nrm[3]);
  
// Description:
vtkSuperquadricSource2::vtkSuperquadricSource2(int res)
{
  res = res < 4 ? 4 : res;

  this->AxisOfSymmetry = 2; //z-axis symmetry
  this->Thickness = 0.3333;
  this->PhiRoundness = 0.0;
  this->SetPhiRoundness(1.0);
  this->ThetaRoundness = 0.0;
  this->SetThetaRoundness(1.0);
  this->Center[0] = this->Center[1] = this->Center[2] = 0.0;
  this->Scale[0] = this->Scale[1] = this->Scale[2] = 1.0;
  this->Size = .5;
  this->ThetaResolution = 0;
  this->SetThetaResolution(res);
  this->PhiResolution = 0;
  this->SetPhiResolution(res);
}

void vtkSuperquadricSource2::SetPhiResolution(int i)
{
  if(i < 4)
    {
    i = 4;
    }
  i = (i+3)/4*4;  // make it divisible by 4
  if(i > VTK_MAX_SUPERQUADRIC_RESOLUTION)
    {
    i =  VTK_MAX_SUPERQUADRIC_RESOLUTION;
    }
  
  if (this->PhiResolution != i)
    {
    this->PhiResolution = i;
    this->Modified ();
    }
}

void vtkSuperquadricSource2::SetThetaResolution(int i)
{
  if(i < 8)
    {
    i = 8;
    }
  i = (i+7)/8*8; // make it divisible by 8
  if(i > VTK_MAX_SUPERQUADRIC_RESOLUTION)
    {
    i =  VTK_MAX_SUPERQUADRIC_RESOLUTION;
    }
  
  if (this->ThetaResolution != i)
    {
    this->ThetaResolution = i;
    this->Modified ();
    }
}

void vtkSuperquadricSource2::SetThetaRoundness(double e) 
{
  if(e < VTK_MIN_SUPERQUADRIC_ROUNDNESS)
    {
    e = VTK_MIN_SUPERQUADRIC_ROUNDNESS;
    }

  if (this->ThetaRoundness != e)
    {
    this->ThetaRoundness = e;
    this->Modified();
    }
}

void vtkSuperquadricSource2::SetPhiRoundness(double e) 
{
  if(e < VTK_MIN_SUPERQUADRIC_ROUNDNESS)
    {
    e = VTK_MIN_SUPERQUADRIC_ROUNDNESS;
    }

  if (this->PhiRoundness != e)
    {
    this->PhiRoundness = e;
    this->Modified();
    }
}

static const double SQ_SMALL_OFFSET = 0.01;

void vtkSuperquadricSource2::Execute()
{
  int i, j;
  vtkIdType numPts;
  vtkPoints *newPoints; 
  vtkFloatArray *newNormals;
  vtkFloatArray *newTCoords;
  vtkCellArray *newPolys;
  vtkIdType *ptidx;
  double pt[3], nv[3], dims[3];
  double len;
  double alpha;
  double deltaPhi, deltaTheta, phi, theta;
  double phiLim[2], thetaLim[2];
  double deltaPhiTex, deltaThetaTex;
  int base, pbase;
  vtkIdType numStrips;
  int ptsPerStrip;
  int phiSubsegs, thetaSubsegs, phiSegs, thetaSegs;
  int iq, jq, rowOffset;
  double thetaOffset, phiOffset;
  double texCoord[2];
  double tmp;

  vtkPolyData *output = this->GetOutput();

  dims[0] = this->Scale[0] * this->Size;
  dims[1] = this->Scale[1] * this->Size;
  dims[2] = this->Scale[2] * this->Size;

   //Ellipsoidal
   phiLim[0] = 0.0;
   phiLim[1] =  vtkMath::Pi();

   thetaLim[0] = 0.0;
   thetaLim[1] =  2*vtkMath::Pi();

   alpha = 0.0;
 

  deltaPhi = (phiLim[1] - phiLim[0]) / this->PhiResolution;
  deltaPhiTex = 1.0 / this->PhiResolution;
  deltaTheta = (thetaLim[1] - thetaLim[0]) / this->ThetaResolution;
  deltaThetaTex = 1.0 / this->ThetaResolution;
  
  phiSegs = 4;
  thetaSegs = 8;

  phiSubsegs = this->PhiResolution / phiSegs;
  thetaSubsegs = this->ThetaResolution / thetaSegs;


  numPts = (this->PhiResolution + phiSegs)*(this->ThetaResolution + thetaSegs);
  // creating triangles
  numStrips = this->PhiResolution * thetaSegs;
  ptsPerStrip = thetaSubsegs*2 + 2;

  //
  // Set things up; allocate memory
  //
  newPoints = vtkPoints::New();
  newPoints->Allocate(numPts);
  newNormals = vtkFloatArray::New();
  newNormals->SetNumberOfComponents(3);
  newNormals->Allocate(3*numPts);
  newNormals->SetName("Normals");
  newTCoords = vtkFloatArray::New();
  newTCoords->SetNumberOfComponents(2);
  newTCoords->Allocate(2*numPts);
  newTCoords->SetName("TextureCoords");

  newPolys = vtkCellArray::New();
  newPolys->Allocate(newPolys->EstimateSize(numStrips,ptsPerStrip));

  // generate!
  for(iq = 0; iq < phiSegs; iq++) {
    for(i = 0; i <= phiSubsegs; i++) {
      phi = phiLim[0] + deltaPhi*(i + iq*phiSubsegs);
      texCoord[1] = deltaPhiTex*(i + iq*phiSubsegs);

      // SQ_SMALL_OFFSET makes sure that the normal vector isn't 
      // evaluated exactly on a crease;  if that were to happen, 
      // large shading errors can occur.
      if(i == 0)
        {
        phiOffset =  SQ_SMALL_OFFSET*deltaPhi;
        }
      else if (i == phiSubsegs)
        {
        phiOffset = -SQ_SMALL_OFFSET*deltaPhi;
        }
      else
        {
        phiOffset =  0.0;
        }
      
      for(jq = 0; jq < thetaSegs; jq++) {
        for(j = 0; j <= thetaSubsegs; j++) {
          theta = thetaLim[0] + deltaTheta*(j + jq*thetaSubsegs);
          texCoord[0] = deltaThetaTex*(j + jq*thetaSubsegs);
          
          if(j == 0)
            {
            thetaOffset =  SQ_SMALL_OFFSET*deltaTheta;
            }
          else if (j == thetaSubsegs)
            {
            thetaOffset = -SQ_SMALL_OFFSET*deltaTheta;
            }
          else
            {
            thetaOffset =  0.0;
            }

          //This give you superquadric with axis of symmetry: z
          evalSuperquadric2(theta, phi, 
                           thetaOffset, phiOffset, 
                           this->ThetaRoundness, this->PhiRoundness,
                           dims, pt, nv);
          switch (this->AxisOfSymmetry) {
            case 0:
              //x-axis
              tmp = pt[0];
              pt[0] = pt[2];
              pt[2] = tmp;
              pt[1] = -pt[1];
            
              tmp = nv[0];
              nv[0]=nv[2];
              nv[2]=tmp;
              nv[1]=-nv[1];
              break;
            case 1:
              //y-axis
              //PENDING
              
              break;
          }                   
                         
          if((len = vtkMath::Norm(nv)) == 0.0)
            {
            len = 1.0;
            }
          nv[0] /= len; nv[1] /= len; nv[2] /= len;

          if(((iq == 0 && i == 0) || (iq == (phiSegs-1) && i == phiSubsegs))) {

            // we're at a pole:
            // make sure the pole is at the same location for all evals
            // (the superquadric evaluation is numerically unstable
            // at the poles)

            //pt[0] = pt[2] = 0.0;
          }
          
          pt[0] += this->Center[0];
          pt[1] += this->Center[1];
          pt[2] += this->Center[2];
          
          newPoints->InsertNextPoint(pt);
          newNormals->InsertNextTuple(nv);
          newTCoords->InsertNextTuple(texCoord);
        }
      }
    }
  }

  // mesh!
  // build triangle strips for efficiency....
  ptidx = new vtkIdType[ptsPerStrip];
  
  rowOffset = this->ThetaResolution+thetaSegs;
  
  for(iq = 0; iq < phiSegs; iq++) {
    for(i = 0; i < phiSubsegs; i++) {
      pbase = rowOffset*(i +iq*(phiSubsegs+1));
      for(jq = 0; jq < thetaSegs; jq++) {
        base = pbase + jq*(thetaSubsegs+1);
        for(j = 0; j <= thetaSubsegs; j++) {
          ptidx[2*j] = base + rowOffset + j;
          ptidx[2*j+1] = base + j;
        }
        newPolys->InsertNextCell(ptsPerStrip, ptidx);
      }
    }
  }
  delete[] ptidx;

  output->SetPoints(newPoints);
  newPoints->Delete();

  output->GetPointData()->SetNormals(newNormals);
  newNormals->Delete();

  output->GetPointData()->SetTCoords(newTCoords);
  newTCoords->Delete();

  output->SetStrips(newPolys);
  newPolys->Delete();
}

void vtkSuperquadricSource2::PrintSelf(ostream& os, vtkIndent indent)
{
  this->Superclass::PrintSelf(os,indent);

  os << indent << "Size: " << this->Size << "\n";
  os << indent << "Thickness: " << this->Thickness << "\n";
  os << indent << "Theta Resolution: " << this->ThetaResolution << "\n";
  os << indent << "Theta Roundness: " << this->ThetaRoundness << "\n";
  os << indent << "Phi Resolution: " << this->PhiResolution << "\n";
  os << indent << "Phi Roundness: " << this->PhiRoundness << "\n";
  os << indent << "Center: (" << this->Center[0] << ", " 
     << this->Center[1] << ", " << this->Center[2] << ")\n";
  os << indent << "Scale: (" << this->Scale[0] << ", " 
     << this->Scale[1] << ", " << this->Scale[2] << ")\n";
}

static double cf(double w, double m) 
{
  double c;
  double sgn;

  c = cos(w);
  sgn = c < 0.0 ? -1.0 : 1.0;
  return sgn*pow(sgn*c, m);
}

static double sf(double w, double m) 
{
  double s;
  double sgn;

  s = sin(w);
  sgn = s < 0.0 ? -1.0 : 1.0;
  return sgn*pow(sgn*s, m);
}

static void evalSuperquadric2(double theta, double phi,  // parametric coords
                             double dtheta, double dphi, // offsets for normals
                             double alpha, double beta,  // roundness params
                             double dims[3],     // x, y, z dimensions
                             double xyz[3],      // output coords
                             double nrm[3])      // output normals
  
{
  double sf1,sf2;

  sf1 = sf(phi, beta);
  xyz[0] = dims[0] * cf(theta,alpha) * sf1;
  xyz[1] = dims[1] * sf(theta,alpha) * sf1;
  xyz[2] = dims[2] * cf(phi,beta);

  sf2 = sf(phi+dphi,2.0-beta);
  nrm[2] = 1.0/dims[2] *cf(phi+dphi,2.0-beta);
  nrm[1] =1.0/dims[1]  *sf(theta+dtheta,2.0-alpha) * sf2;
  nrm[0] =1.0/dims[0]  *cf(theta+dtheta,2.0-alpha) * sf2;
}
