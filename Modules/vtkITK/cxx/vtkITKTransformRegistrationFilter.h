// .NAME vtkITKImageToImageFilter - Abstract base class for connecting ITK and VTK
// .SECTION Description
// vtkITKImageToImageFilter provides a 

#ifndef __vtkITKTransformRegistrationFilter_h
#define __vtkITKTransformRegistrationFilter_h


#include "vtkITKRegistrationFilter.h"
#include "itkTransformRegistrationFilter.h"
#include "vtkMatrix4x4.h"

#ifdef _WIN32
#include <iostream>
#else
#include <iostream.h>
#endif



///////////////////////////

// vtkITKTransformRegistrationFilter Class

class VTK_EXPORT vtkITKTransformRegistrationFilter : public vtkITKRegistrationFilter
{
public:
  vtkTypeMacro(vtkITKTransformRegistrationFilter,vtkITKImageToImageFilter);

  static vtkITKTransformRegistrationFilter* New(){return 0;};

  virtual void GetTransformationMatrix(vtkMatrix4x4* matrix) = 0;
  
  virtual void GetCurrentTransformationMatrix(vtkMatrix4x4* matrix) = 0;
  
  virtual void SetTransformationMatrix(vtkMatrix4x4 *matrix) = 0;

  virtual void AbortIterations() = 0;

  vtkProcessObject* GetProcessObject() {return this;};

  virtual void ResetMultiResolutionSettings() {};

  vtkSetMacro(Error, int);
  vtkGetMacro(Error, int);

  virtual double GetMetricValue() {return 0;};

protected:

  //BTX
  typedef itk::ImageToImageFilter<itk::itkRegistrationFilterImageType, itk::itkRegistrationFilterImageType> ITKRegistrationType;
  
  //ITKRegistrationType::Pointer m_ITKFilter;

  vtkMatrix4x4 *m_Matrix;

  int Error;

  // default constructor
  vtkITKTransformRegistrationFilter () {Error=0;}; // This is called from New() by vtkStandardNewMacro

  virtual void UpdateRegistrationParameters(){};

  virtual vtkITKRegistrationFilter::OutputImageType::Pointer GetTransformedOutput();

  virtual void CreateRegistrationPipeline();

  virtual ~vtkITKTransformRegistrationFilter(){};
  //ETX


private:
  vtkITKTransformRegistrationFilter(const vtkITKTransformRegistrationFilter&);  // Not implemented.
  void operator=(const vtkITKTransformRegistrationFilter&);  // Not implemented.
};





///////////////////////////////////////////////////////////////////
//
//  The following section of code implements a Command observer
//  that will monitor the evolution of the registration process.
//

//BTX
class vtkITKTransformRegistrationCommand : public itk::Command 
{
public:
  typedef  vtkITKTransformRegistrationCommand   Self;
  typedef  itk::Command             Superclass;
  typedef  itk::SmartPointer<vtkITKTransformRegistrationCommand>  Pointer;
  itkNewMacro( vtkITKTransformRegistrationCommand );

  void SetRegistrationFilter (vtkITKTransformRegistrationFilter *registration) {
    m_registration = registration;
  }

protected:
  vtkITKTransformRegistrationCommand() {};
  
  vtkITKTransformRegistrationFilter  *m_registration;
  
  std::ofstream m_fo;
  
public:
  
  virtual void Execute(itk::Object *caller, const itk::EventObject & event)
  {
    Execute( (const itk::Object *)caller, event);
  }
  
  virtual void Execute(const itk::Object * object, const itk::EventObject & event)
  {
    if(itk::IterationEvent().CheckEvent( &event ) ) {
      int iter = m_registration->GetCurrentIteration();
      m_registration->SetCurrentIteration(iter+1);
      m_registration->UpdateProgress((float)iter/m_registration->GetNumIterations() );
      if (m_registration->GetAbortExecute()) {
        m_registration->AbortIterations();
      }
      vtkMatrix4x4 *mat = vtkMatrix4x4::New();
      m_registration->GetCurrentTransformationMatrix(mat);
      m_fo << iter << "," << m_registration->GetMetricValue() << "  ";
      mat->Print(m_fo);
      m_fo << std::endl;
      m_fo.flush();
      
      m_registration->InvokeEvent(vtkCommand::ProgressEvent);
    }
    else {
      std::cout << "Error in vtkITKTransformRegistrationCommand::Execute" << std::endl;
    }
  }
};
//ETX

#endif




