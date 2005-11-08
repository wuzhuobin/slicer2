// .NAME vtkITKImageToImageFilter - Abstract base class for connecting ITK and VTK
// .SECTION Description
// vtkITKImageToImageFilter provides a 

#ifndef __vtkITKImageWriter_h
#define __vtkITKImageWriter_h

#include "vtkProcessObject.h"
#include "vtkImageData.h"
#include "vtkObjectFactory.h"
#include "vtkMatrix4x4.h"

class VTK_EXPORT vtkITKImageWriter : public vtkProcessObject
{
public:
  static vtkITKImageWriter *New();

  vtkTypeRevisionMacro(vtkITKImageWriter,vtkProcessObject);
  void PrintSelf(ostream& os, vtkIndent indent);
  
  // Description:
  // Specify file name for the image file. You should specify either
  // a FileName or a FilePrefix. Use FilePrefix if the data is stored 
  // in multiple files.
  void SetFileName(const char *);

  char *GetFileName() {
    return FileName;
  }

  // Description:
  // Set/Get the input object from the image pipeline.
  void SetInput(vtkImageData *input);

  vtkImageData *GetInput();

  // Description:
  // The main interface which triggers the writer to start.
  void Write();

  // Set orienation matrix
  void SetRasToIJKMatrix( vtkMatrix4x4* mat) {
    RasToIJKMatrix = mat;
  }

protected:
  vtkITKImageWriter();
  ~vtkITKImageWriter();

  char *FileName;
  vtkMatrix4x4* RasToIJKMatrix;

private:
  vtkITKImageWriter(const vtkITKImageWriter&);  // Not implemented.
  void operator=(const vtkITKImageWriter&);  // Not implemented.
};

vtkCxxRevisionMacro(vtkITKImageWriter, "$Revision: 1.2 $")
vtkStandardNewMacro(vtkITKImageWriter)

#endif




