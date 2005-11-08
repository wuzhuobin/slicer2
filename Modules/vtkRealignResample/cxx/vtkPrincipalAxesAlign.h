/*=auto=========================================================================

(c) Copyright 2005 Massachusetts Institute of Technology (MIT) All Rights Reserved.

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
#ifndef __vtk_principal_axes_align_h
#define __vtk_principal_axes_align_h
#include <vtkRealignResampleConfigure.h>
#include <vtkPolyDataToPolyDataFilter.h>
#include <vtkSetGet.h>
// ---------------------------------------------------------
// Author: Axel Krauth
//
// This class computes the principal axes of the input.
// The direction of the eigenvector for the largest eigenvalue is the XAxis,
// the direction of the eigenvector for the smallest eigenvalue is the ZAxis,
// and the YAxis the the eigenvector for the remaining eigenvalue.

class VTK_REALIGNRESAMPLE_EXPORT vtkPrincipalAxesAlign : public vtkPolyDataToPolyDataFilter
{
 public:
  static vtkPrincipalAxesAlign* New();
  void Delete();
  vtkTypeMacro(vtkPrincipalAxesAlign,vtkPolyDataToPolyDataFilter);

  vtkGetVector3Macro(Center,vtkFloatingPointType);
  vtkGetVector3Macro(XAxis,vtkFloatingPointType);
  vtkGetVector3Macro(YAxis,vtkFloatingPointType);
  vtkGetVector3Macro(ZAxis,vtkFloatingPointType);
  void Execute();
  void PrintSelf();
 protected:
  vtkPrincipalAxesAlign();
  ~vtkPrincipalAxesAlign();

 private:
  vtkPrincipalAxesAlign(vtkPrincipalAxesAlign&);
  void operator=(const vtkPrincipalAxesAlign);

  vtkFloatingPointType* Center;
  vtkFloatingPointType* XAxis;
  vtkFloatingPointType* YAxis;
  vtkFloatingPointType* ZAxis;

  // a matrix of the eigenvalue problem
  double** eigenvalueProblem;
  // for efficiency reasons parts of the eigenvalue problem are computed separately
  double** eigenvalueProblemDiag;
  double** eigenvectors;
  double* eigenvalues;
};

#endif