/*=auto=========================================================================
Copyright (c) 2000 Surgical Planning Lab, Brigham and Women's Hospital
 
Direct all questions on this copyright to slicer@ai.mit.edu.
The following terms apply to all files associated with the software unless
explicitly disclaimed in individual files.   

The authors hereby grant permission to use, copy (but NOT distribute) this
software and its documentation for any NON-COMMERCIAL purpose, provided
that existing copyright notices are retained verbatim in all copies.
The authors grant permission to modify this software and its documentation 
for any NON-COMMERCIAL purpose, provided that such modifications are not 
distributed without the explicit consent of the authors and that existing
copyright notices are retained in all copies. Some of the algorithms
implemented by this software are patented, observe all applicable patent law.

IN NO EVENT SHALL THE AUTHORS OR DISTRIBUTORS BE LIABLE TO ANY PARTY FOR
DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
OF THE USE OF THIS SOFTWARE, ITS DOCUMENTATION, OR ANY DERIVATIVES THEREOF,
EVEN IF THE AUTHORS HAVE BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

THE AUTHORS AND DISTRIBUTORS SPECIFICALLY DISCLAIM ANY WARRANTIES, INCLUDING,
BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
PARTICULAR PURPOSE, AND NON-INFRINGEMENT.  THIS SOFTWARE IS PROVIDED ON AN
'AS IS' BASIS, AND THE AUTHORS AND DISTRIBUTORS HAVE NO OBLIGATION TO PROVIDE
MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
=========================================================================auto=*/
#include <math.h>
#include "vtkObject.h"
#include "vtkMath.h"
#include "vtkTransform.h"
#include "vtkMathUtils.h"

// Description:
// The center of mass is computed from the Points and (optionally) Weights.
// The covariance matrix is then computed and solved for principal axes
// and moments.
// The fourth vector in "Vectors" is the center of mass.

int vtkMathUtils::PrincipalMomentsAndAxes( vtkPoints *Points,
                                           vtkScalars *Weights,
                                           vtkScalars *Values,
                                           vtkVectors *Vectors )
  {
  int numPts, id, ii, jj, status;
  float *covar[3], cov0[3], cov1[3], cov2[3], tmp,
        mean[3], *p, pw[3], weight, totalWeight;
  float *eigenVecs[3], eV0[3], eV1[3], eV2[3], eigenVals[3];

  mean[0] = mean[1] = mean[2] = 0.0;
  weight = 1.0;
  totalWeight = 0.0;
  covar[0] = cov0; covar[1] = cov1; covar[2] = cov2;

  // First - compute weighted means
  numPts = Points->GetNumberOfPoints();
  for ( id=0; id<numPts; id++ )
    {
    p = Points->GetPoint(id);
    if ( Weights != NULL )
      {
      weight = Weights->GetScalar(id);
      }
    mean[0] += p[0]*weight;
    mean[1] += p[1]*weight;
    mean[2] += p[2]*weight;
    totalWeight += weight;
    }

  for ( jj=0; jj<3; jj++ )
    {
    mean[jj] /= totalWeight;
    cov0[jj] = cov1[jj] = cov2[jj] = 0.0;
    }

  // Second - compute covariance matrix
  for ( id=0; id<numPts; id++ )
    {
    p = Points->GetPoint(id);
    if ( Weights != NULL )
      {
      weight = Weights->GetScalar(id);
      }
    pw[0] = p[0]*weight - mean[0];
    pw[1] = p[1]*weight - mean[1];
    pw[2] = p[2]*weight - mean[2];
    for ( jj=0; jj<3; jj++ )
      {
      cov0[jj] += pw[0] * pw[jj];
      cov1[jj] += pw[1] * pw[jj];
      cov2[jj] += pw[2] * pw[jj];
      }
    }
  for ( jj=0; jj<3; jj++ )
    {
    cov0[jj] /= totalWeight;
    cov1[jj] /= totalWeight;
    cov2[jj] /= totalWeight;
    }

  // Third - solve eigenvectors and eigenvalues from covariance matrix
  eigenVecs[0] = eV0; eigenVecs[1] = eV1; eigenVecs[2] = eV2;
  status = vtkMath::JacobiN( covar, 3, eigenVals, eigenVecs );

  // Fourth - copy result to output
  Values->SetNumberOfScalars( 3 );
  Vectors->SetNumberOfVectors( 4 );
  for ( jj=0; jj<3; jj++ )
    {
    Values->SetScalar( jj, eigenVals[jj] );
    for ( ii=jj+1; ii<3; ii++ )
      {
      tmp = eigenVecs[jj][ii];
      eigenVecs[jj][ii] = eigenVecs[ii][jj];
      eigenVecs[ii][jj] = tmp;
      }
    Vectors->SetVector( jj, eigenVecs[jj] );
    }
  Vectors->SetVector( 3, mean );
  return status;
  }

//
// Find the least-squares solution to p' = Rp + T
// where R is a rotation matrix and T is a translation matrix
// using singular value decomposition.
//
int vtkMathUtils::AlignPoints( vtkPoints *Data, vtkPoints *Ref,
                           vtkMatrix4x4 *Xform )
  {
  int nPts, ii, jj, status;
  float *p, *p1;
  float cmData[3] = { 0.0, 0.0, 0.0 },
         cmRef[3] = { 0.0, 0.0, 0.0 },
         H[3][3] = { 0.0, 0.0, 0.0,
                     0.0, 0.0, 0.0,
                     0.0, 0.0, 0.0 };
  float (*q1)[3], (*q)[3];
  float sing[3], U[3][3], V[3][3], translate[3];
  vtkTransform *tmpXform = vtkTransform::New();

  nPts = Data->GetNumberOfPoints();
  if ( Ref->GetNumberOfPoints() != nPts )
    {
    vtkGenericWarningMacro(<< "Point numbers don't match.");
    return( -1 );
    }

  q = new float [nPts][3];
  q1 = new float [nPts][3];
  for ( ii=0; ii<nPts; ii++ )
    {
    p = Data->GetPoint( ii );
    p1 = Ref->GetPoint( ii );
    for ( jj=0; jj<3; jj++ )
      {
      cmData[jj] += p[jj];
      cmRef[jj] += p1[jj];
      q[ii][jj] = p[jj];
      q1[ii][jj] = p1[jj];
      }
    }

  for ( jj=0; jj<3; jj++ )
    {
    cmData[jj] /= nPts;
    cmRef[jj] /= nPts;
    }

  for ( ii=0; ii<nPts; ii++ )
    {
    for ( jj=0; jj<3; jj++ )
      {
      q[ii][jj] -= cmData[jj];
      q1[ii][jj] -= cmRef[jj];
      }
    for ( jj=0; jj<3; jj++ )
      {
      H[jj][0] += q[ii][jj] * q1[ii][0];
      H[jj][1] += q[ii][jj] * q1[ii][1];
      H[jj][2] += q[ii][jj] * q1[ii][2];
      }
    }

  vtkMathUtils:SVD3x3( H, U, sing, V );

  for ( ii=0; ii<3; ii++ )
    {
    for ( jj=0; jj<3; jj++ )
      {
      tmpXform->GetMatrixPointer()->SetElement( ii, jj, U[ii][jj] );
      Xform->SetElement( ii, jj, V[jj][ii] ); // V transpose
      }
    }
  tmpXform->Concatenate( Xform );
  tmpXform->MultiplyPoint( cmRef, translate );
  Xform->DeepCopy( tmpXform->GetMatrixPointer() );
  for ( ii=0; ii<3; ii++ )
    {
    Xform->SetElement( ii, 3, cmData[ii] - translate[ii] );
    }

  delete [] q;
  delete [] q1;
  tmpXform->Delete();

  return( 0 );
  }

extern "C" { // SVD from Numerical Recipes in C
void svdcmp( float **a, int m, int n, float w[], float **v );
}

// 
// Singular value decomposition: A = U*diag(W)*Vt
//
void vtkMathUtils::SVD3x3( float A[][3], float U[][3], float W[], float V[][3] )
  {
  int ii, jj;
  float *U1[3], *V1[3], *W1;

  // Convert the input into format compatible with foolish 1-based arrays
  // used in Numerical Recipes in C. (sneaky pointer arithmetic)
  //
  for ( ii=0; ii<3; ii++ )
    {
    for ( jj=0; jj<3; jj++ )
      {
      U[ii][jj] = A[ii][jj];
      }
    U1[ii] = &U[ii][0] - 1;
    V1[ii] = &V[ii][0] - 1;
    }
  W1 = &W[0] - 1;

  svdcmp( &U1[0]-1, 3, 3, W1, &V1[0]-1 );
  }
