#include "vtkHyperStreamlineDTMRI.h"

#include "vtkCellArray.h"
#include "vtkDataSet.h"
#include "vtkFloatArray.h"
#include "vtkMath.h"
#include "vtkObjectFactory.h"
#include "vtkPointData.h"
#include "vtkPolyData.h"
// the superclass had these classes in the vtkHyperStreamline.cxx file:
//#include "vtkHyperPointandArray.cxx"

vtkCxxRevisionMacro(vtkHyperStreamlineDTMRI, "$Revision: 1.6 $");
vtkStandardNewMacro(vtkHyperStreamlineDTMRI);

// Construct object with initial starting position (0,0,0); integration step 
// length 0.2; step length 0.01; forward integration; terminal eigenvalue 0.0;
// number of sides 6; radius 0.5; and logarithmic scaling off.
vtkHyperStreamlineDTMRI::vtkHyperStreamlineDTMRI()
{
  // defaults copied from superclass for now:
  this->StartFrom = VTK_START_FROM_POSITION;
  this->StartPosition[0] = this->StartPosition[1] = this->StartPosition[2] = 0.0;

  this->StartCell = 0;
  this->StartSubId = 0;
  this->StartPCoords[0] = this->StartPCoords[1] = this->StartPCoords[2] = 0.5;

  this->Streamers = NULL;

  this->MaximumPropagationDistance = 100.0;
  this->IntegrationStepLength = 0.2;
  this->StepLength = 0.01;
  this->IntegrationDirection = VTK_INTEGRATE_FORWARD;
  this->TerminalEigenvalue = 0.0;
  this->NumberOfSides = 6;
  this->Radius = 0.5;
  this->LogScaling = 0;
  this->IntegrationEigenvector = VTK_INTEGRATE_MAJOR_EIGENVECTOR;

}

vtkHyperStreamlineDTMRI::~vtkHyperStreamlineDTMRI()
{

}

// copied from superclass
// Make sure coordinate systems are consistent
static void FixVectors(float **prev, float **current, int iv, int ix, int iy)
{
  float p0[3], p1[3], p2[3];
  float v0[3], v1[3], v2[3];
  float temp[3];
  int i;

  for (i=0; i<3; i++)
    {
    v0[i] = current[i][iv];
    v1[i] = current[i][ix];
    v2[i] = current[i][iy];
    }

  if ( prev == NULL ) //make sure coord system is right handed
    {
    vtkMath::Cross(v0,v1,temp);
    if ( vtkMath::Dot(v2,temp) < 0.0 )
      {
      for (i=0; i<3; i++)
        {
        current[i][iy] *= -1.0;
        }
      }
    }

  else //make sure vectors consistent from one point to the next
    {
    for (i=0; i<3; i++)
      {
      p0[i] = prev[i][iv];
      p1[i] = prev[i][ix];
      p2[i] = prev[i][iy];
      }
    if ( vtkMath::Dot(p0,v0) < 0.0 )
      {
      for (i=0; i<3; i++)
        {
        current[i][iv] *= -1.0;
        }
      }
    if ( vtkMath::Dot(p1,v1) < 0.0 )
      {
      for (i=0; i<3; i++)
        {
        current[i][ix] *= -1.0;
        }
      }
    if ( vtkMath::Dot(p2,v2) < 0.0 )
      {
      for (i=0; i<3; i++)
        {
        current[i][iy] *= -1.0;
        }
      }
    }
}

void vtkHyperStreamlineDTMRI::Execute()
{
  vtkDataSet *input = this->GetInput();
  vtkPointData *pd=input->GetPointData();
  vtkDataArray *inScalars;
  vtkDataArray *inTensors;
  vtkFloatingPointType *tensor;
  vtkHyperPoint *sNext, *sPtr;
  int i, j, k, ptId, subId, iv, ix, iy;
  vtkCell *cell;
  float ev[3];
  vtkFloatingPointType xNext[3];
  vtkFloatingPointType d, step, dir, tol2, p[3];
  vtkFloatingPointType *w;
  vtkFloatingPointType dist2;
  vtkFloatingPointType closestPoint[3];
  float *m[3], *v[3];
  float m0[3], m1[3], m2[3];
  float v0[3], v1[3], v2[3];
  vtkDataArray *cellTensors;
  vtkDataArray *cellScalars;
  int pointCount;
  vtkHyperPoint *sPrev, *sPrevPrev;
  float kv1[3], kv2[3], ku1[3], ku2[3], kl1, kl2, kn[3], K;
  // set up working matrices
  v[0] = v0; v[1] = v1; v[2] = v2; 
  m[0] = m0; m[1] = m1; m[2] = m2; 
  
  vtkDebugMacro(<<"Generating hyperstreamline(s)");
  this->NumberOfStreamers = 0;

  if ( ! (inTensors=pd->GetTensors()) )
    {
    vtkErrorMacro(<<"No tensor data defined!");
    return;
    }
  w = new vtkFloatingPointType[input->GetMaxCellSize()];

  inScalars = pd->GetScalars();

  cellTensors = vtkDataArray::CreateDataArray(inTensors->GetDataType());
  cellScalars = vtkDataArray::CreateDataArray(inScalars->GetDataType());
  int numComp;
  if (inTensors)
    {
    numComp = inTensors->GetNumberOfComponents();
    cellTensors->SetNumberOfComponents(numComp);
    cellTensors->SetNumberOfTuples(VTK_CELL_SIZE);
    }
  if (inScalars)
    {
    numComp = inScalars->GetNumberOfComponents();
    cellScalars->SetNumberOfComponents(numComp);
    cellScalars->SetNumberOfTuples(VTK_CELL_SIZE);
    }
  
  
  tol2 = input->GetLength() / 1000.0;
  tol2 = tol2 * tol2;
  iv = this->IntegrationEigenvector;
  ix = (iv + 1) % 3;
  iy = (iv + 2) % 3;
  //
  // Create starting points
  //
  this->NumberOfStreamers = 1;
 
  if ( this->IntegrationDirection == VTK_INTEGRATE_BOTH_DIRECTIONS )
    {
    this->NumberOfStreamers *= 2;
    }

  this->Streamers = new vtkHyperArray[this->NumberOfStreamers];

  if ( this->StartFrom == VTK_START_FROM_POSITION )
    {
    sPtr = this->Streamers[0].InsertNextHyperPoint();
    for (i=0; i<3; i++)
      {
      sPtr->X[i] = this->StartPosition[i];
      }
    sPtr->CellId = input->FindCell(this->StartPosition, NULL, (-1), 0.0, 
                                   sPtr->SubId, sPtr->P, w);
    }

  else //VTK_START_FROM_LOCATION
    {
    sPtr = this->Streamers[0].InsertNextHyperPoint();
    cell =  input->GetCell(sPtr->CellId);
    cell->EvaluateLocation(sPtr->SubId, sPtr->P, sPtr->X, w);
    }
  //
  // Finish initializing each hyperstreamline
  //
  this->Streamers[0].Direction = 1.0;
  sPtr = this->Streamers[0].GetHyperPoint(0);
  sPtr->D = 0.0;
  if ( sPtr->CellId >= 0 ) //starting point in dataset
    {
    cell = input->GetCell(sPtr->CellId);
    cell->EvaluateLocation(sPtr->SubId, sPtr->P, xNext, w);

    inTensors->GetTuples(cell->PointIds, cellTensors);

    // interpolate tensor, compute eigenfunctions
    for (j=0; j<3; j++)
      {
      for (i=0; i<3; i++)
        {
        m[i][j] = 0.0;
        }
      }
    for (k=0; k < cell->GetNumberOfPoints(); k++)
      {
      tensor = cellTensors->GetTuple(k);
      for (j=0; j<3; j++) 
        {
        for (i=0; i<3; i++) 
          {
          m[i][j] += tensor[i+3*j] * w[k];
          }
        }
      }

    vtkMath::Jacobi(m, sPtr->W, sPtr->V);
    FixVectors(NULL, sPtr->V, iv, ix, iy);

    if ( inScalars ) 
      {
      inScalars->GetTuples(cell->PointIds, cellScalars);
      for (sPtr->S=0, i=0; i < cell->GetNumberOfPoints(); i++)
        {
          sPtr->S += cellScalars->GetTuple(i)[0] * w[i];
          // for curvature coloring for debugging purposes:
          //sPtr->S =0;
        }
      }

    if ( this->IntegrationDirection == VTK_INTEGRATE_BOTH_DIRECTIONS )
      {
      this->Streamers[1].Direction = -1.0;
      sNext = this->Streamers[1].InsertNextHyperPoint();
      *sNext = *sPtr;
      }
    else if ( this->IntegrationDirection == VTK_INTEGRATE_BACKWARD )
      {
      this->Streamers[0].Direction = -1.0;
      }
    } //for hyperstreamline in dataset

  //
  // For each hyperstreamline, integrate in appropriate direction (using RK2).
  //
  for (ptId=0; ptId < this->NumberOfStreamers; ptId++)
    {
    //get starting step
    sPtr = this->Streamers[ptId].GetHyperPoint(0);
    if ( sPtr->CellId < 0 )
      {
      continue;
      }

    dir = this->Streamers[ptId].Direction;
    cell = input->GetCell(sPtr->CellId);
    cell->EvaluateLocation(sPtr->SubId, sPtr->P, xNext, w);
    step = this->IntegrationStepLength * sqrt((double)cell->GetLength2());
    inTensors->GetTuples(cell->PointIds, cellTensors);
    if ( inScalars ) {inScalars->GetTuples(cell->PointIds, cellScalars);}


    // This is the only modification from the superclass Execute.
    // Test here for the angle between the last two tangent vectors.
    // Stop if high.
    int integrationAngleGood =1;
    // init index for curvature calculation 
    pointCount=0;
      
    //integrate until distance has been exceeded
    while ( sPtr->CellId >= 0 && fabs(sPtr->W[0]) > this->TerminalEigenvalue &&
            sPtr->D < this->MaximumPropagationDistance &&
            integrationAngleGood)
      {
        // Test curvature
        if ( pointCount > 2 )
          {
 
           // v2=p3-p2;  % vector from point 2 to point 3
            // v1=p2-p1;  % vector from point 1 to point 2
            // u2=v2/norm(v2);  % unit vector in the direction of v2
            // u1=v1/norm(v1);  % unit vector in the direciton of v1
            
            // kn is curvature times the unit normal vector
            // it's the change in the unit normal over half the distance 
            // from p1 to p3
            // kn=2*(u2-u1)/(norm(v1)+norm(v2));
            // absk=norm(kn);  % absolute value of the curvature

            sPrev = this->Streamers[ptId].GetHyperPoint(pointCount-1);
            sPrevPrev = this->Streamers[ptId].GetHyperPoint(pointCount-2);
            kl2=0;
            kl1=0;
            for (i=0; i<3; i++)
              {
                // vectors
                kv2[i]=sPrevPrev->X[i] - sPrev->X[i];
                kv1[i]=sPrev->X[i] - sPtr->X[i];
                // lengths
                kl2+=kv2[i]*kv2[i];
                kl1+=kv1[i]*kv1[i];
              }           
            kl2=sqrt(kl2);
            kl1=sqrt(kl1);
            // normalize
            for (i=0; i<3; i++)
              {
                // unit vectors
                ku2[i]=kv2[i]/kl2;
                ku1[i]=kv1[i]/kl1;
              }
            // compute curvature
            for (i=0; i<3; i++)
              {
                kn[i]=2*(ku2[i]-ku1[i])/(kl1+kl2);
                K+=kn[i]*kn[i];
              }
            K=sqrt(K);
            // units are radians per mm.
            //vtkDebugMacro(<<K);
            //cout << pointCount << "    " << K << endl;

            if (K > this->MaxCurvature) 
              {
                integrationAngleGood=0;
              }
          }
        else 
          {
            K=0;
          }


        
      //compute updated position using this step (Euler integration)
      for (i=0; i<3; i++)
        {
        xNext[i] = sPtr->X[i] + dir * step * sPtr->V[i][iv];
        }

      //compute updated position using updated step
      cell->EvaluatePosition(xNext, closestPoint, subId, p, dist2, w);

      //interpolate tensor
      for (j=0; j<3; j++)
        {
        for (i=0; i<3; i++)
          {
          m[i][j] = 0.0;
          }
        }
      for (k=0; k < cell->GetNumberOfPoints(); k++)
        {
        tensor = cellTensors->GetTuple(k);
        for (j=0; j<3; j++) 
          {
          for (i=0; i<3; i++) 
            {
            m[i][j] += tensor[i+3*j] * w[k];
            }
          }
        }

      vtkMath::Jacobi(m, ev, v);
      FixVectors(sPtr->V, v, iv, ix, iy);

      //now compute final position
      for (i=0; i<3; i++)
        {
        xNext[i] = sPtr->X[i] + 
                   dir * (step/2.0) * (sPtr->V[i][iv] + v[i][iv]);
        }
      sNext = this->Streamers[ptId].InsertNextHyperPoint();

      if ( cell->EvaluatePosition(xNext, closestPoint, sNext->SubId, 
      sNext->P, dist2, w) )
        { //integration still in cell
        for (i=0; i<3; i++)
          {
          sNext->X[i] = closestPoint[i];
          }
        sNext->CellId = sPtr->CellId;
        sNext->SubId = sPtr->SubId;
        }
      else
        { //integration has passed out of cell
        sNext->CellId = input->FindCell(xNext, cell, sPtr->CellId, tol2, 
                                        sNext->SubId, sNext->P, w);
        if ( sNext->CellId >= 0 ) //make sure not out of dataset
          {
          for (i=0; i<3; i++)
            {
            sNext->X[i] = xNext[i];
            }
          cell = input->GetCell(sNext->CellId);
          inTensors->GetTuples(cell->PointIds, cellTensors);
          if (inScalars){inScalars->GetTuples(cell->PointIds, cellScalars);}
          step = this->IntegrationStepLength * sqrt((double)cell->GetLength2());
          }
        }

      if ( sNext->CellId >= 0 )
        {
        cell->EvaluateLocation(sNext->SubId, sNext->P, xNext, w);
        for (j=0; j<3; j++)
          {
          for (i=0; i<3; i++)
            {
            m[i][j] = 0.0;
            }
          }
        for (k=0; k < cell->GetNumberOfPoints(); k++)
          {
          tensor = cellTensors->GetTuple(k);
          for (j=0; j<3; j++) 
            {
            for (i=0; i<3; i++) 
              {
              m[i][j] += tensor[i+3*j] * w[k];
              }
            }
          }

        vtkMath::Jacobi(m, sNext->W, sNext->V);
        FixVectors(sPtr->V, sNext->V, iv, ix, iy);

        if ( inScalars )
          {
          for (sNext->S=0.0, i=0; i < cell->GetNumberOfPoints(); i++)
            {
              sNext->S += cellScalars->GetTuple(i)[0] * w[i];
              // for curvature coloring for debugging purposes:
              //sNext->S =K;

            }
          }
        d = sqrt((double)vtkMath::Distance2BetweenPoints(sPtr->X,sNext->X));
        sNext->D = sPtr->D + d;
        }

      sPtr = sNext;

      pointCount++;

      }//for elapsed time

    } //for each hyperstreamline

  this->BuildTube();

  delete [] w;
  cellTensors->Delete();
  cellScalars->Delete();  
}

void vtkHyperStreamlineDTMRI::PrintSelf(ostream& os, vtkIndent indent)
{
  this->Superclass::PrintSelf(os,indent);
}


