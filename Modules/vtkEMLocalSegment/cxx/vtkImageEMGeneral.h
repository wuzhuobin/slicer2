/*=auto=========================================================================

(c) Copyright 2001 Massachusetts Institute of Technology

Permission is hereby granted, without payment, to copy, modify, display 
and distribute this software and its documentation, if any, for any purpose, 
provided that the above copyright notice and the following three paragraphs 
appear on all copies of this software.  Use of this software constitutes 
acceptance of these terms and conditions.

IN NO EVENT SHALL MIT BE LIABLE TO ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, 
INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE 
AND ITS DOCUMENTATION, EVEN IF MIT HAS BEEN ADVISED OF THE POSSIBILITY OF 
SUCH DAMAGE.

MIT SPECIFICALLY DISCLAIMS ANY EXPRESS OR IMPLIED WARRANTIES INCLUDING, 
BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR 
A PARTICULAR PURPOSE, AND NON-INFRINGEMENT.

THE SOFTWARE IS PROVIDED "AS IS."  MIT HAS NO OBLIGATION TO PROVIDE 
MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.

=========================================================================auto=*/
// .NAME vtkImageEMGeneral
 
// The idea of vtkImageEMGeneral is to include all the tools we need for the 
// different EM Segmentation tools. The tool is put together in four parts
// - the special made header files
// - files needed so it is a vtk filter
// - Genral Math Functions 

// ------------------------------------
// Standard EM necessaties
// ------------------------------------
#ifndef __vtkImageEMGeneral_h
#define __vtkImageEMGeneral_h
#include <vtkEMLocalSegmentConfigure.h>
#include <math.h>
#include <cmath>
#include "vtkMath.h"
#include "vtkImageMultipleInputFilter.h"
#include "vtkImageThreshold.h"
#include "vtkImageMathematics.h"
#include "vtkImageAccumulate.h"
#include "vtkImageData.h"
// Just made for vtkImageEMGeneral and its kids
#include "vtkThread.h"
#include "vtkDataTimeDef.h"
#include "vtkFileOps.h" 

// ------------------------------------
// Definitions for gauss calculations
// ------------------------------------
// Abuse the type system.
//BTX
#define COERCE(x, type) (*((type *)(&(x))))
// Some constants having to do with the way single
// floats are represented on alphas and sparcs
#define EMSEGMENT_MANTSIZE (23)
#define EMSEGMENT_SIGNBIT (1 << 31)
#define EMSEGMENT_EXPMASK (255 << EMSEGMENT_MANTSIZE)
#define EMSEGMENT_MENTMASK ((~EMSEGMENT_EXPMASK)&(~EMSEGMENT_SIGNBIT))
#define EMSEGMENT_PHANTOM_BIT (1 << EMSEGMENT_MANTSIZE)
#define EMSEGMENT_EXPBIAS 127
#define EMSEGMENT_SHIFTED_BIAS (EMSEGMENT_EXPBIAS << EMSEGMENT_MANTSIZE)
#define EMSEGMENT_SHIFTED_BIAS_COMP ((~ EMSEGMENT_SHIFTED_BIAS) + 1)
#define EMSEGMENT_ONE_OVER_2_PI 0.5/3.14159265358979
#define EMSEGMENT_ONE_OVER_ROOT_2_PI sqrt(EMSEGMENT_ONE_OVER_2_PI)
#define EMSEGMENT_MINUS_ONE_OVER_2_LOG_2 ((float) -.72134752)

// Definitions for Markof Field Approximation
#define EMSEGMENT_NORTH     1 
#define EMSEGMENT_SOUTH     2
#define EMSEGMENT_EAST      4 
#define EMSEGMENT_WEST      8 
#define EMSEGMENT_FIRST    16
#define EMSEGMENT_LAST     32 
#define EMSEGMENT_DEFINED  64
#define EMSEGMENT_NOTROI  128


//Definitions For Gauss Lookuptable
#define EMSEGMENT_TABLE_SIZE          64000   // For one image version
#define EMSEGMENT_TABLE_SIZE_MULTI    10000   // For multiple images
#define EMSEGMENT_TABLE_EPSILON       1e-4    // Cut of for smallest eps value: x < Eps  => GausTable(x) = 0
#define EMSEGMENT_TABLE_EPSILON_MULTI 1e-3    // Cut of for smallest eps value: x < Eps  => GausTable(x) = 0
//ETX
class VTK_EMLOCALSEGMENT_EXPORT vtkImageEMGeneral : public vtkImageMultipleInputFilter
{
  public:
  // -------------------------------
  // General vtk Functions
  // -------------------------------
  static vtkImageEMGeneral *New();
  vtkTypeMacro(vtkImageEMGeneral,vtkObject);
  void PrintSelf(ostream& os) { };
//Kilian
//BTX
  void SetInputIndex(int index, vtkImageData *image) {this->SetInput(index,image);}

  void PrintMatrix(double **mat, int yMax,int xMax); 
  void PrintMatrix3D(double ***mat, int zMax,int yMax,int xMax); 

  // Description:
  // Calculated the determinant for a dim dimensional matrix -> the value is returned 
  static double determinant(double **mat,int dim); 

  // Description:
  // Inverts the matrix -> Retrns 0 if it could not do it 
  static int InvertMatrix(double **mat, double **inv_mat,int dim);

  // Description:
  // Just squares the matrix 
  static void SquareMatrix(double **Input,double **Output,int dim);

  // Description:
  // Multiplies the Matrix mat with the vector vec => res = mat * vec 
  static void MatrixVectorMulti(double **mat,double *vec,double *res,int dim);

  // Description :
  // Smoothes  3D-Matrix -> w(k) = sum(u(j)*v(k+1-j)) -> returns Matrix of size r_m
  // void smoothConv(double ***mat3D, int mat3DZlen, int mat3DYlen, int mat3DXlen, double v[],int vLen);

  // Description :
  // -------------------------------------------------------------------------------------------------------------------
  // CalculateLogMeanandLogCovariance - for multiple Image
  //
  // Input: Mu                  = Matrix with Mean values for every tissue class (row) and image (column) => [NumberOfClasses]x[NumberOfInputImages]
  //        CovMatrix           = Covariance matrix's diagonal for every tissue class (row) and image (column) => [NumberOfClasses]x[NumberOfInputImages]x[NumberOfInputImages]
  //        LogMu               = Log Mean Values calculated by the function
  //        LogCov              = Log Covariance Values calculated by the function
  //        NumberOfInputImages = Number of Input Images 
  //        NumberOfClasses     = Number of Classes 
  //        SequenceMax         = Maximum "grey value" for every image the mean and sigma value should be computed
  // 
  // Output: If return value is 0 => could not invert coveriance matrix  
  //     
  // Idea: Calculates the MuLog Vecotr and CovarianceLog Matrix given mu and CovDiag for every tissue class. To calculate MuLog 
  //       and LogCovariance we normally need samples from the image. In our case we do not have any samples, because we do not 
  //       know how the image is segmented to get around it we generate a Testsequence T where
  //       T[i] =  p(i)*log(i+1) with  
  //       p(i) = the probability that grey value i appears in the image given sigma and mu = Gauss(i, Sigma, Mu)
  //       and i ranges from [0,SequenceMax]   
  // -------------------------------------------------------------------------------------------------------------------
  static int CalculateLogMeanandLogCovariance(double **Mu, double ***CovMatrix, double **LogMu, double ***LogCov,int NumberOfInputImages, int  NumberOfClasses, int SequenceMax); 

  // Description:
  // -------------------------------------------------------------------------------------------------------------------
  // CalculateLogMeanandLogCovariance - for 1 Image
  //
  // Input: mu              = Vector with Mean values for every tissue class
  //        Sigma           = Vector with Sigma values for every tissue class
  //        logmu           = Log Mean Values calculated by the function
  //        logSigma        = Log Sigma Values calculated by the function - this case is standard deviation
  //                          or sqrt(variation)
  //        NumberOfClasses = Number of classes
  //        SequenceMax     = Maximum "grey value" the mean and sigma value should be computed
  //        
  // Idea: Calculates the MuLog and SigmaLog values given mu and sigma. To calculate MuLog and SigmaLog we 
  //       normally need samples from the image. In our case we do not have any samples, because we do not 
  //       know how the image is segmented to get around it we generate a Testsequence T where
  //       T[i] =  p(i)*log(i+1) with  
  //       p(i) = the probability that grey value i appears in the image given sigma and mu = Gauss(i, Sigma, Mu)
  //       and i ranges from [0,SequenceMax]   
  // -------------------------------------------------------------------------------------------------------------------
  static void CalculateLogMeanandLogCovariance(double *mu, double *Sigma, double *LogMu, double *LogSigma, int NumberOfClasses, int SequenceMax);

  // Description:
  // -------------------------------------------------------------------------------------------------------------------
  // CalculatingPJointDistribution
  //
  // Input: x                = set input values, x has to be of size numvar and the set variables have to be defined,
  //                           e.g. index n and m are set => y[n] and y[m] have to be defined
  //        Vleft            = all the vairables that are flexible => e.g Vleft = [1,...,n-1,n+1, .., m-1, m+1 ,..., numvar]
  //        mu               = Mean Values of the distribution of size numvar
  //        invcov           = The covariance Matrix's inverse of the distribution - has to be of size numvarxnumvar  
  //        inv_sqrt_det_cov = The covariance Matrix' determinant squared and inverted
  //        SequenceMax      = Test sequence for the different images - has to be of size numvar
  //        setvar           = How many veriable are allready fixed 
  //        numvar           = Size of Varaible Space V
  //        
  // Idea: Calculates the joint probability of the  P(i= V/Vleft: y[i] =x[i]) , e.g. P(y[n] = x[n], y[m] = x[m])  
  // Explanation: V = {y[1] ... y[numvar]}, V~ = Vleft = V / {y[n],y[m]}, and y = X <=> y element of X 
  //              =>  P(y[n] = x[n],y[m] = x[m]) = \sum{k = V~} (\sum{ l = [0..seq[y]]} P(y[n] = x[n],y[m] = x[m],y[k] = l,V~\{ y[k]}) 
  // -------------------------------------------------------------------------------------------------------------------
  static double CalculatingPJointDistribution(float* x,int *Vleft,double *mu, double **inv_cov, double inv_sqrt_det_cov,int SequenceMax, int setvar,int numvar);
  
  // -------------------------------
  // Gauss Functions
  // -------------------------------
  // Description :
  // Normal Gauss Function - pritty slow 
  static double GeneralGauss(double x,double m,double s);
  // Description :
  // Normal Gauss Function for 3D - pritty slow 
  // Input: 
  // x                = Value Vector of dimension n
  // mu               = Mean Value Vector of dimension n
  // inv_cov          = The inverse of the coveriance Matrix
  // inv_sqrt_det_cov = The covariance matrix's determinant sqrt and inverted = sqrt(inv_cov)
  static double GeneralGauss(float *x,double *mu,double **inv_cov, double inv_sqrt_det_cov,int n);

  // Description :
  // 3xfaster Gauss Function written by Sandy
  static double FastGauss(double inverse_sigma, double x);
  static double FastGaussTest(double inverse_sigma, double x);
  static float FastGauss2(double inverse_sqrt_det_covariance, float *x ,double *mu,  double **inv_cov);
  // Description :
  // Same as FastGauss - just for multi dimensional input ->  x = (vec - mu) * InvCov *(vec - mu)
  static float FastGaussMulti(double inverse_sqrt_det_covariance, float x,int dim);
  // Description :
  // Same as FastGauss - just for multi dimensional input 
  static float FastGaussMulti(double inverse_sqrt_det_covariance, float* x,double *mu, double **inv_cov, int dim);

  // Description :
  // Fastes Gauss Function (jep I wrote it) - just look in a predifend lookup table 
  static double LookupGauss(double* table, double lbound, double ubound, double resolution,double value);
  static double LookupGauss(double* table, double *lbound, double *ubound, double *resolution,double *value,int NumberOfInputImages);
  // Description:
  // Calculate the Gauss-Lookup-Table for one tissue class 
  static int CalculateGaussLookupTable(double *GaussLookupTable,double **ValueTable,double **InvCovMatrix, double InvSqrtDetCovMatrix, 
                                       double *ValueVec,int GaussTableIndex,int TableSize,int NumberOfInputImages, int index);
  // Description :
  // Calculates DICE and Jakobian Simularity Measure 
  // Value defines the vooxel with those label to be measured
  // Returns  Dice sim measure
  static float CalcSimularityMeasure (vtkImageData *Image1, vtkImageData *Image2,float val, int PrintRes);
//Kilian
//ETX
protected:
  vtkImageEMGeneral() {};
  vtkImageEMGeneral(const vtkImageEMGeneral&) {};
  ~vtkImageEMGeneral() {};

  void DeleteVariables();
  void operator=(const vtkImageEMGeneral&) {};
  void ThreadedExecute(vtkImageData **inData, vtkImageData *outData,int outExt[6], int id){};
//Kilian
//BTX
  // -------------------------------
  // Matrix Functions
  // -------------------------------
  // Description:
  // Writes Vector to file in Matlab format if name is specified otherwise just 
  // writes the values in the file
  // void WriteVectorToFile (FILE *f,char *name, double *vec, int xMax) const;

  // Description:
  // Writes Matrix to file in Matlab format if name is specified otherwise just 
  // writes the values in the file
  // void WriteMatrixToFile (FILE *f,char *name,double **mat, int imgY, int imgX) const;

  // Description:
  // Convolution and polynomial multiplication . 
  // This is assuming u and 'this' have the same dimension
  static void convMatrix3D(double*** mat3D, double*** U,int mat3DZlen, int mat3DYlen, int mat3DXlen, double v[],int vLen);

  // Description:
  // Convolution and polynomial multiplication . 
  // This is assuming u and 'this' have the same dimension
  // Convolution and polynomial multiplication . 
  // This is assuming u and 'this' have the same dimension
  // static void convMatrix(double** mat, double** U, int matYlen, int matXlen, double v[], int vLen);

  // Description:
  // Same just v is a row vector instead of column one
  // We use the following equation :
  // conv(U,v) = conv(U',v')' => conv(U,v') = conv(U',v)';
  // static void convMatrixT(double** mat, double** U, int matYlen, int matXlen, double v[], int vLen);

  // Description:
  // Convolution and polynomial multiplication . 
  // This is assuming u and 'this' have the same dimensio
  // static void convVector(double vec[], double u[], int uLen, double v[], int vLen);

  // Description:
  // Calculates Vector * Matrix * Vector
  static double CalculateVectorMatrixVectorOperation(double** mat, double *vec, int offY,int dimY, int offX, int dimX);

  // Description:                                                           
  // Calculates the inner product of <vec, mat[posY:dimY-1][posX]> = vec * mat[posY:dimY-1][posX]
  static double InnerproductWithMatrixY(double* vec, double **mat, int posY,int dimY, int posX);

  // Description:                                                             
  // Product of mat[posY][posX:dimY-1]*vec
  static double InnerproductWithMatrixX(double **mat, int posY,int posX, int dimX, double *vec);
 
  // Description:
  // -------------------------------------------------------------------------------------------------------------------
  // CalculateLogMeanandLogCovariance - for 1 Image
  //
  // Input: mu              = Vector with Mean values for every tissue class
  //        Sigma           = Vector with Sigma values for every tissue class
  //        LogMu           = Log Mean Values calculated by the function
  //        LogVariance     = Log Variance Values calculated by the function
  //        LogTestSequence = Sequence of log(i+1) with i ranges from [0,SequenceMax]
  //        SequenceMax     = Maximum "grey value" the mean and sigma value should be computed
  //        
  // Idea: Calculates the MuLog and SigmaLog values given mu and sigma. To calculate MuLog and SigmaLog we 
  //       normally need samples from the image. In our case we do not have any samples, because we do not 
  //       know how the image is segmented to get around it we generate a Testsequence T where
  //       T[i] =  p(i)*log(i+1) with  
  //       p(i) = the probability that grey value i appears in the image given sigma and mu = Gauss(i, Sigma, Mu)
  //       and i ranges from [0,SequenceMax]   
  // -------------------------------------------------------------------------------------------------------------------
  static void CalculateLogMeanandLogCovariance(double *mu, double *Sigma, double *LogMu, double *LogVariance,double *LogTestSequence, int NumberOfClasses, int SequenceMax); 
 
  void TestMatrixFunctions(int MatrixDim,int iter);
//Kilian
//ETX
};

#endif







