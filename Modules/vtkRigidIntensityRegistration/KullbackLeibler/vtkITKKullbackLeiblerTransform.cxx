/*=auto=========================================================================
(c) Copyright 2003 Massachusetts Institute of Technology (MIT) All Rights Reserved.

This software ("3D Slicer") is provided by The Brigham and Women's 
Hospital, Inc. on behalf of the copyright holders and contributors.
Permission is hereby granted, without payment, to copy, modify, display 
and distribute this software and its documentation, if any, for  
research purposes only, provided that (1) the above copyright notice and 
the following four paragraphs appear on all copies of this software, and 
(2) that source code to any modifications to this software be made 
publicly available under terms no more restrictive than those in this 
License Agreement. Use of this software constitutes acceptance of these 
terms and conditions.

3D Slicer Software has not been reviewed or approved by the Food and 
Drug Administration, and is for non-clinical, IRB-approved Research Use 
Only.  In no event shall data or images generated through the use of 3D 
Slicer Software be used in the provision of patient care.

IN NO EVENT SHALL THE COPYRIGHT HOLDERS AND CONTRIBUTORS BE LIABLE TO 
ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL 
DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, 
EVEN IF THE COPYRIGHT HOLDERS AND CONTRIBUTORS HAVE BEEN ADVISED OF THE 
POSSIBILITY OF SUCH DAMAGE.

THE COPYRIGHT HOLDERS AND CONTRIBUTORS SPECIFICALLY DISCLAIM ANY EXPRESS 
OR IMPLIED WARRANTIES INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND 
NON-INFRINGEMENT.

THE SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS 
IS." THE COPYRIGHT HOLDERS AND CONTRIBUTORS HAVE NO OBLIGATION TO 
PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.


=========================================================================auto=*/

#include "vtkITKKullbackLeiblerTransform.h"

#include "vtkImageData.h"
#include "vtkObjectFactory.h"
#include "vtkImageExport.h"
#include "vtkTransform.h"
#include "vtkUnsignedIntArray.h"
#include "vtkDoubleArray.h"

#include "vtkMatrix4x4.h"
#include "vtkImageFlip.h"

#include "itkVTKImageImport.h"
#include "vtkITKUtility.h"

// All the MI Registration Stuff
#include "itkExceptionObject.h"

// itk classes
// Some of this may be necessary, but I doubt it.
#include "itkImage.h"
#include "itkImageRegionIterator.h"
#include "itkQuaternionRigidTransform.h"
#include "itkQuaternionRigidTransformGradientDescentOptimizer.h"
#include "itkKLHistogramImageToImageMetric.h"
#include "itkLinearInterpolateImageFunction.h"
#include "itkImageRegistrationMethod.h"
#include "itkNumericTraits.h"
#include "vnl/vnl_math.h"

#include "itkObject.h"
#include "itkMultiResolutionImageRegistrationMethod.h"
#include "itkAffineTransform.h"
#include "itkRecursiveMultiResolutionPyramidImageFilter.h"

#include "itkArray.h"

#include "KLRegistration.h"

vtkCxxRevisionMacro(vtkITKKullbackLeiblerTransform, "$Revision: 1.1 $");
vtkStandardNewMacro(vtkITKKullbackLeiblerTransform);

//----------------------------------------------------------------------------
vtkITKKullbackLeiblerTransform::vtkITKKullbackLeiblerTransform()
{
  // Default Parameters
  this->SourceImage=NULL;
  this->TargetImage=NULL;
  this->SourceStandardDeviation = 0.4;
  this->TargetStandardDeviation = 0.4;
  this->TranslateScale = 320;
  this->NumberOfSamples = 50;
  this->MetricValue = 0;
  this->Matrix->Identity();

  this->HistSize = 32;
  this->GivenHistogram = NULL; // No Histogram until calculated

  // the last iteration finished with no error
  this->Error = 0;

  this->LearningRate          = vtkDoubleArray::New();
  this->MaxNumberOfIterations = vtkUnsignedIntArray::New();

  // Default Number of MultiResolutionLevels is 1
  this->SetNextLearningRate(0.0001);
  this->SetNextMaxNumberOfIterations(500);

  // Default Shrink Factors: No Shrink
  this->SetSourceShrinkFactors(1,1,1);
  this->SetTargetShrinkFactors(1,1,1);

  // Default: no flipping!
  this->FlipTargetZAxis = 0;
  this->ImageFlip = vtkImageFlip::New();
    this->ImageFlip->SetFilteredAxis(2);
    this->ImageFlip->FlipAboutOriginOn();
  this->ZFlipMat = vtkMatrix4x4::New();
    this->ZFlipMat->Identity();
    this->ZFlipMat->SetElement(2,2,-1);

    // The output matrix
  this->OutputMatrix = vtkMatrix4x4::New();
    this->OutputMatrix->Zero();
}

//----------------------------------------------------------------------------

vtkITKKullbackLeiblerTransform::~vtkITKKullbackLeiblerTransform()
{
  if(this->SourceImage)
    {
    this->SourceImage->Delete();
    }
  if(this->TargetImage)
    { 
    this->TargetImage->Delete();
    }

  if(this->GivenSourceImage)
    {
    this->GivenSourceImage->Delete();
    }
  if(this->GivenTargetImage)
    {
    this->GivenTargetImage->Delete();
    }
  if(this->GivenTransform)
    {
    this->GivenTransform->Delete();
    }

  this->LearningRate->Delete();
  this->MaxNumberOfIterations->Delete();
  this->ImageFlip->Delete();
  this->ZFlipMat->Delete();
}

//----------------------------------------------------------------------------

void vtkITKKullbackLeiblerTransform::PrintSelf(ostream& os, vtkIndent indent)
{
  this->Superclass::PrintSelf(os, indent);

  os << "SourceStandardDeviation: " << this->SourceStandardDeviation  << endl;
  os << "TargetStandardDeviation: " << this->SourceStandardDeviation  << endl;
  os << "TranslateScale: " << this->TranslateScale  << endl;
  os << "NumberOfSamples: " << this->NumberOfSamples  << endl;
  os << "MetricValue: " << this->MetricValue  << endl;

  os << "Source Shrink: "       << SourceShrink[0] << ' '
     << SourceShrink[1] << ' '  << SourceShrink[2] << endl;
  os << "Target Shrink: "       << TargetShrink[0] << ' '
     << TargetShrink[1] << ' '  << TargetShrink[2] << endl;

  os << "NumberOfIterations: " << this->MaxNumberOfIterations  << endl;
    this->MaxNumberOfIterations->PrintSelf(os,indent.GetNextIndent());
  os << "LearningRate: "       << this->LearningRate  << endl;
    this->LearningRate->PrintSelf(os,indent.GetNextIndent());

   os << "Flip Target Z Axis? " << this->FlipTargetZAxis << endl;
   os << "Image Flipping:" << this->ImageFlip << endl;
   this->ImageFlip->PrintSelf(os,indent.GetNextIndent());
   os << "ZFlipMat" << this->ZFlipMat << endl;
   this->ZFlipMat->PrintSelf(os,indent.GetNextIndent());
   os << "OutputMatrix" << this->OutputMatrix << endl;
   this->OutputMatrix->PrintSelf(os,indent.GetNextIndent());

  os << "SourceImage: " << this->SourceImage << endl;
  if(this->SourceImage)
    {
    this->SourceImage->PrintSelf(os,indent.GetNextIndent());
    }
  os << "TargetImage: " << this->TargetImage << endl;
  if(this->TargetImage)
    {
    this->TargetImage->PrintSelf(os,indent.GetNextIndent());
    }
}

//----------------------------------------------------------------------------

//
// Need to unregister the results of the function
//
template <class T>
itk::Image<T,3> *VTKtoITKImage(vtkImageData *VtkImage,T*)
{
  typedef itk::Image<T,3>                       OutputImageType;
  typedef itk::VTKImageImport<OutputImageType>  ImageImportType;

  vtkImageExport *ImageExporter = vtkImageExport::New();
    ImageExporter->SetInput(VtkImage);
  ImageImportType::Pointer ItkImporter = ImageImportType::New();
  ConnectPipelines(ImageExporter, ItkImporter);
  ItkImporter->Update();
  ItkImporter->GetOutput()->Register();
  return ItkImporter->GetOutput();
}

//----------------------------------------------------------------------------

// This templated function executes the filter for any type of data.
// But, actually we use only float...
template <class T>
static void vtkITKKLExecute(vtkITKKullbackLeiblerTransform *self,
                               vtkImageData *source,
                               vtkImageData *target,
                               vtkMatrix4x4 *matrix,
                               T vtkNotUsed(dummy))
{

  // Declare the input and output types
  typedef itk::Image<T,3>                       OutputImageType;

  // Create the Registrator
  typedef itk::KLRegistration<OutputImageType,OutputImageType> RegistratorType;
  typename RegistratorType::Pointer KLRegistrator = RegistratorType::New();

  KLRegistrator->SetMovingImage(VTKtoITKImage(source,(T*)(NULL)));
  KLRegistrator->GetMovingImage()->UnRegister();

  // ----------------------------------------
  // Sources to ITK KLRegistration
  // ----------------------------------------

  if (!self->GetFlipTargetZAxis())
    {
      KLRegistrator->SetFixedImage(VTKtoITKImage(target,(T*)(NULL)));
    }
  else 
    {
      std::cout << "Z-Flipping Target Input" << std::endl;
      self->GetImageFlip()->SetInput(target);
      self->GetImageFlip()->Update();
      KLRegistrator->
    SetFixedImage(VTKtoITKImage(self->GetImageFlip()->GetOutput(),(T*)(NULL)));
    }
  KLRegistrator->GetFixedImage()->UnRegister();

   self->Print(std::cout);

  // ---------------------------------------
  // Set Up the KL Metric
  // --------------------------------------

  typedef itk::AffineTransform< double, 3 > GivenTransformType;
  GivenTransformType::Pointer ITKGivenTransform = GivenTransformType::New();
  typedef GivenTransformType::ParametersType ParametersType;

  ParametersType parameters( ITKGivenTransform->GetNumberOfParameters() );
  
  int count = 0;
  for( unsigned int row = 0; row < 3; row++ )
    {
    for( unsigned int col = 0; col < 3; col++ )
      {
      parameters[count] = 0;
      if( row == col )
        {
        parameters[count] = self->GetGivenTransform()->GetElement(row,col);
        }
      ++count;
      }
    }
  // initialize the offset/vector part
  for( unsigned int k = 0; k < 3; k++ )
    {
    parameters[count] =  self->GetGivenTransform()->GetElement(3,k);
    ++count;
    }
  ITKGivenTransform->SetParameters(parameters);

  KLRegistrator->SetGivenTransform(ITKGivenTransform);
  KLRegistrator->SetGivenFixedImage(VTKtoITKImage(self->GetGivenTargetImage(),(T*)(NULL)))->UnRegister();
  KLRegistrator->SetGivenMovingImage(VTKtoITKImage(self->GetGivenSourceImage(),(T*)(NULL)))->UnRegister();

  // take care of memory leak 
  //  KLRegistrator->GetGivenFixedImage()
  //  KLRegistrator->GetGivenMovingImage()->UnRegister();

  typedef RegistratorType::SizeType SizeType;

  SizeType histSize;
  histSize[0] = self->GetHistSize();
  histSize[1] = self->GetHistSize();
  KLRegistrator->SetHistogramSize(histSize);

  // ----------------------------------------
  // Do the Registratioon Configuration
  // ----------------------------------------

  // Initialize
  KLRegistrator->InitializeRegistration(matrix);

 // Setup the optimizer

  KLRegistrator->SetTranslationScale(1.0/vnl_math_sqr(self->GetTranslateScale()));
//  // This is the scale on translation
//  for (int j=4; j<7; j++)
//    {
//    scales[j] = KLReg_TranslationScale;
//    // This was chosen by Steve. I'm not sure why.
//    scales[j] = 1.0/vnl_math_sqr(self->GetTranslateScale());
//    }

  // Set metric related parameters
  KLRegistrator->SetMovingImageStandardDeviation(self->GetSourceStandardDeviation());
  KLRegistrator->SetFixedImageStandardDeviation(self->GetTargetStandardDeviation());
  KLRegistrator->SetNumberOfSpatialSamples(self->GetNumberOfSamples());

  //
  // This is the multi-resolution information
  // Number of iterations and learning rate at each level
  //

  typedef typename RegistratorType::UnsignedIntArray UnsignedIntArray;
  typedef typename RegistratorType::DoubleArray      DoubleArray;
  
  DoubleArray      LearnRates(self->GetLearningRate()->GetNumberOfTuples());
  UnsignedIntArray NumIterations(self->GetLearningRate()->GetNumberOfTuples());

  for(int i=0;i<self->GetLearningRate()->GetNumberOfTuples();i++)
    {
      LearnRates[i]    = self->GetLearningRate()->GetValue(i);
      NumIterations[i] = self->GetMaxNumberOfIterations()->GetValue(i);
    }
  KLRegistrator->SetNumberOfLevels(self->GetLearningRate()
                                       ->GetNumberOfTuples());
  KLRegistrator->SetLearningRates(LearnRates);
  KLRegistrator->SetNumberOfIterations(NumIterations);

  //
  // This is the shrink factors for each dimension
  // 

  typedef typename RegistratorType::ShrinkFactorsArray ShrinkFactorsArray;

  ShrinkFactorsArray SourceShrink;
  SourceShrink[0] = self->GetSourceShrinkFactors(0);
  SourceShrink[1] = self->GetSourceShrinkFactors(1);
  SourceShrink[2] = self->GetSourceShrinkFactors(2);
  KLRegistrator->SetMovingImageShrinkFactors(SourceShrink);

  ShrinkFactorsArray TargetShrink;
  TargetShrink[0] = self->GetTargetShrinkFactors(0);
  TargetShrink[1] = self->GetTargetShrinkFactors(1);
  TargetShrink[2] = self->GetTargetShrinkFactors(2);
  KLRegistrator->SetFixedImageShrinkFactors(TargetShrink);

  //
  // Start registration
  //
  try { KLRegistrator->Execute(); }
  catch( itk::ExceptionObject & err )
    {
      std::cout << "Caught an exception: " << std::endl;
      std::cout << err << std::endl;
      self->SetError(1);
      return;
    }

  KLRegistrator->ResultsToMatrix(matrix);

  // Get the Value of the agreement
  self->SetMetricValue(KLRegistrator->GetMetricValue());
  // self->SetMetricValue(optimizer->GetValue());

  // the last iteration finished with no error
  self->SetError(0);

  self->Modified();
}

//----------------------------------------------------------------------------
// Update the 4x4 matrix. Updates are only done as necessary.
 
void vtkITKKullbackLeiblerTransform::InternalUpdate()
{

  if (this->SourceImage == NULL || this->TargetImage == NULL)
    {
    this->Matrix->Identity();
    return;
    }

  if (MaxNumberOfIterations->GetNumberOfTuples() != 
               LearningRate->GetNumberOfTuples())
    vtkErrorMacro (<< MaxNumberOfIterations->GetNumberOfTuples() 
    << "is the number of levels of iterations"
    << LearningRate->GetNumberOfTuples() 
    << "is the number of levels of learning rates. "
    << "the two numbers should be the same");

  if (this->SourceImage->GetScalarType() != VTK_FLOAT)
    {
    vtkErrorMacro (<< "Source type " << this->SourceImage->GetScalarType()
                   << "must be float");
    this->Matrix->Identity();
    return;
    }

  if (this->TargetImage->GetScalarType() != VTK_FLOAT)
    {
    vtkErrorMacro (<< "Target type " << this->SourceImage->GetScalarType()
                   << "must be float");
    this->Matrix->Identity();
    return;
    }

  float dummy = 0.0;
  vtkITKKLExecute(this,
          this->SourceImage,
          this->TargetImage,
          this->Matrix,
          dummy);
}

//------------------------------------------------------------------------

void vtkITKKullbackLeiblerTransform::Initialize(vtkMatrix4x4 *mat)
{
  this->Matrix->DeepCopy(mat);

  // Do we need the flip?
  if (mat->Determinant()<0)
    {
      std::cout << "Z-Flipping Input Matrix" << std::endl;
      this->FlipTargetZAxis = 1;
      vtkMatrix4x4::Multiply4x4(mat,this->ZFlipMat,this->Matrix);
    }
  else
    {
      this->FlipTargetZAxis = 0;
      this->Matrix->DeepCopy(mat);
    }
}

//------------------------------------------------------------------------

vtkMatrix4x4 *vtkITKKullbackLeiblerTransform::GetOutputMatrix()
{
  if(this->FlipTargetZAxis)
    {
      std::cout << "Z-Flipping Output Matrix" << std::endl;
      vtkMatrix4x4::Multiply4x4(this->Matrix,this->ZFlipMat,
                                this->OutputMatrix);
    }
  else
    {
      this->OutputMatrix->DeepCopy(this->Matrix);
    }
  return this->OutputMatrix;
}
//------------------------------------------------------------------------
unsigned long vtkITKKullbackLeiblerTransform::GetMTime()
{
  unsigned long result = this->vtkLinearTransform::GetMTime();
  unsigned long mtime;

  if (this->SourceImage)
    {
    mtime = this->SourceImage->GetMTime(); 
    if (mtime > result)
      {
      result = mtime;
      }
    }
  if (this->TargetImage)
    {
    mtime = this->TargetImage->GetMTime();
    if (mtime > result)
      {
      result = mtime;
      }
    }
  return result;
}

//----------------------------------------------------------------------------
void vtkITKKullbackLeiblerTransform::Inverse()
{
  vtkImageData *tmp1 = this->SourceImage;
  vtkImageData *tmp2 = this->TargetImage;
  this->TargetImage = tmp1;
  this->SourceImage = tmp2;
  this->Modified();
}

//----------------------------------------------------------------------------
vtkAbstractTransform *vtkITKKullbackLeiblerTransform::MakeTransform()
{
  return vtkITKKullbackLeiblerTransform::New(); 
}

//----------------------------------------------------------------------------
void vtkITKKullbackLeiblerTransform::InternalDeepCopy(vtkAbstractTransform *transform)
{
  vtkITKKullbackLeiblerTransform *t = (vtkITKKullbackLeiblerTransform *)transform;

  cerr << "Calling Internal Deep Copy" << endl;

  this->SetSourceStandardDeviation(t->GetSourceStandardDeviation());
  this->SetTargetStandardDeviation(t->GetTargetStandardDeviation());
  this->SetTranslateScale(t->GetTranslateScale());
  this->SetNumberOfSamples(t->GetNumberOfSamples());
  this->SetMetricValue(t->GetMetricValue());

  this->SetLearningRate(t->LearningRate);
  this->SetTranslateScale(t->TranslateScale);
  this->SetNumberOfSamples(t->NumberOfSamples);

//  vtkImageData *SourceImage;
//  vtkImageData *TargetImage;
//  vtkUnsignedIntArray  *MaxNumberOfIterations;
//  vtkDoubleArray       *LearningRate;

  this->Modified();
}


//----------------------------------------------------------------------------

void vtkITKKullbackLeiblerTransform::SetNextLearningRate(const double rate)
{ LearningRate->InsertNextValue(rate); }

//----------------------------------------------------------------------------

void vtkITKKullbackLeiblerTransform::SetNextMaxNumberOfIterations(const int num) 
  { MaxNumberOfIterations->InsertNextValue(num); }

//----------------------------------------------------------------------------

void vtkITKKullbackLeiblerTransform::SetSourceShrinkFactors(
    unsigned int i, unsigned int j, unsigned int k)
{
  SourceShrink[0] = i;
  SourceShrink[1] = j;
  SourceShrink[2] = k;
}

//----------------------------------------------------------------------------

void vtkITKKullbackLeiblerTransform::SetTargetShrinkFactors(
    unsigned int i, unsigned int j, unsigned int k)
{
  TargetShrink[0] = i;
  TargetShrink[1] = j;
  TargetShrink[2] = k;
}

