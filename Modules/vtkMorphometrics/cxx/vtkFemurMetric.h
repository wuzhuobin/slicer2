/*=auto=========================================================================
                                                                                
(c) Copyright 2004 Massachusetts Institute of Technology (MIT) All Rights Reserved.
                                                                                
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
#ifndef __vtk_femur_metric_h
#define __vtk_femur_metric_h
#include <vtkMorphometricsConfigure.h>
#include <vtkObject.h>
#include <vtkPlaneSource.h>
#include <vtkSphereSource.h>
#include <vtkCylinderSource.h>
#include <vtkTransformPolyDataFilter.h>
#include <vtkTransform.h>
#include <vtkPolyData.h>
//---------------------------------------------------------
// Author: Axel Krauth
//
// This class represents the basic and derived geometric
// properties of a thigh bone. The basic properties are
// an approximating sphere for the head, an axis for the
// neck as well as for the shaft. The only derived property
// at the moment is the angle between the neck and the shaft axis
//
// To be able to compute the basic properties, a division of the 
// thighbone into a head, a neck and a shaft segment is needed.
// the four planes which are members of this class represent a good
// approximation where a physician would place the border between those
// sections.
//

class VTK_MORPHOMETRICS_EXPORT vtkFemurMetric : public vtkObject
{
 public:
  static vtkFemurMetric* New();
  void Delete();
  vtkTypeMacro(vtkFemurMetric,vtkObject);
  void PrintSelf();

  vtkSetObjectMacro(Femur,vtkPolyData);
  vtkGetObjectMacro(Femur,vtkPolyData);

  vtkGetMacro(NeckShaftAngle,float);

 // representation of the approximation of the head sphere
  vtkGetObjectMacro(HeadSphere,vtkSphereSource);

 // representation of the neck axis as a transformed cylinder
  vtkGetObjectMacro(NeckAxisFilter,vtkTransformPolyDataFilter);
  vtkGetObjectMacro(NeckAxisSource,vtkCylinderSource);

 // representation of the shaft axis as a transformed cylinder
  vtkGetObjectMacro(ShaftAxisFilter,vtkTransformPolyDataFilter);
  vtkGetObjectMacro(ShaftAxisSource,vtkCylinderSource);

  vtkGetObjectMacro(HeadNeckPlane,vtkPlaneSource);

  vtkGetObjectMacro(NeckShaftPlane,vtkPlaneSource);

  vtkGetObjectMacro(UpperShaftEndPlane,vtkPlaneSource);
  
  vtkGetObjectMacro(LowerShaftEndPlane,vtkPlaneSource);

 // ensure that the geometry fulfills some properties, i.e. the head
 // of femur is in the halfspace specified by the NeckShaftPlane
  void Normalize();

  void ComputeNeckShaftAngle();
 protected:
  vtkFemurMetric();
  ~vtkFemurMetric();

  void Execute();
 private:
  vtkFemurMetric(vtkFemurMetric&);
  void operator=(const vtkFemurMetric);

  vtkSphereSource* HeadSphere;
  
  vtkCylinderSource* NeckAxisSource;
  vtkTransformPolyDataFilter* NeckAxisFilter;
  vtkTransform* NeckAxisTransform;

  vtkCylinderSource* ShaftAxisSource;
  vtkTransformPolyDataFilter* ShaftAxisFilter;
  vtkTransform* ShaftAxisTransform;

  vtkPlaneSource*  HeadNeckPlane;

  vtkPlaneSource*  NeckShaftPlane;

  vtkPlaneSource*  UpperShaftEndPlane;

  vtkPlaneSource*  LowerShaftEndPlane;

  vtkPolyData* Femur;

 // convenience function for computing the angle between two vectors
  float Angle(float* a,float* b);
 // update t so that it translates and rotates an input vtkCylinderSource 
 // to the given location and orientation
  void SetAxis(vtkTransform* t,float x0_x,float x0_y,float x0_z,float dir_x,float dir_y,float dir_z);
 
 // retrieve the axis of a cylinder for a given transformation t
  float* CylinderDirection(vtkTransform* t);
  float NeckShaftAngle;
};

#endif
