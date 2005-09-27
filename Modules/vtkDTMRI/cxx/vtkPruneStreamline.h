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
/*=========================================================================

  Program:   Visualization Toolkit
  Module:    $RCSfile: vtkPruneStreamline.h,v $

  Copyright (c) Ken Martin, Will Schroeder, Bill Lorensen
  All rights reserved.
  See Copyright.txt or http://www.kitware.com/Copyright.htm for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.  See the above copyright notice for more information.

=========================================================================*/
// .NAME vtkPruneStreamline - transform points and associated normals and vectors for polygonal dataset
// .SECTION Description
// vtkPruneStreamline is a filter to transform point
// coordinates and associated point and cell normals and
// vectors. Other point and cell data is passed through the filter
// unchanged. This filter is specialized for polygonal data. See
// vtkTransformFilter for more general data.
//
// An alternative method of transformation is to use vtkActor's methods
// to scale, rotate, and translate objects. The difference between the
// two methods is that vtkActor's transformation simply effects where
// objects are rendered (via the graphics pipeline), whereas
// vtkPruneStreamline actually modifies point coordinates in the 
// visualization pipeline. This is necessary for some objects 
// (e.g., vtkProbeFilter) that require point coordinates as input.

// .SECTION See Also
// vtkTransform vtkTransformFilter vtkActor

#ifndef __vtkPruneStreamline_h
#define __vtkPruneStreamline_h

#include "vtkDTMRIConfigure.h"

#include "vtkPolyDataToPolyDataFilter.h"
#include "vtkShortArray.h"
#include "vtkIntArray.h"


class VTK_DTMRI_EXPORT vtkPruneStreamline : public vtkPolyDataToPolyDataFilter
{
public:
  static vtkPruneStreamline *New();
  vtkTypeRevisionMacro(vtkPruneStreamline,vtkPolyDataToPolyDataFilter);
  void PrintSelf(ostream& os, vtkIndent indent);

  // Description:
  // Return the MTime also considering the ROI values.
  unsigned long GetMTime();

  // Description:
  // Specify an array with the ROI signatures.
  vtkSetObjectMacro(ANDROIValues,vtkShortArray);
  vtkGetObjectMacro(ANDROIValues,vtkShortArray);
  
  vtkSetObjectMacro(NOTROIValues,vtkShortArray);
  vtkGetObjectMacro(NOTROIValues,vtkShortArray);
  
  // Description:
  // List of streamlines Ids that pass the test
  vtkGetObjectMacro(StreamlineIdPassTest,vtkIntArray);

  //Description:
  // Number of positives that we have to get before declaring that a
  // streamline passes through a given ROI.
  vtkSetMacro(Threshold,int);
  vtkGetMacro(Threshold,int);
  
protected:
  vtkPruneStreamline();
  ~vtkPruneStreamline();

  void Execute();
  
  vtkShortArray *ANDROIValues;
  vtkShortArray *NOTROIValues;
  vtkIntArray *StreamlineIdPassTest;
  int Threshold;
  
  int TestForStreamline(int *streamlineANDTest,int npts, int *streamlineNOTTest, int npts);
  
private:
  vtkPruneStreamline(const vtkPruneStreamline&);  // Not implemented.
  void operator=(const vtkPruneStreamline&);  // Not implemented.
};

#endif


