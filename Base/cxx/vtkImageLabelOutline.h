/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkImageLabelOutline.h,v $
  Date:      $Date: 2005/12/20 22:44:16 $
  Version:   $Revision: 1.14.16.1 $

=========================================================================auto=*/
// .NAME vtkImageLabelOutline -  Display labelmap outlines
// .SECTION Description
//  Used  in slicer for the Label layer to outline the segmented
//  structures (instead of showing them filled-in).

#ifndef __vtkImageLabelOutline_h
#define __vtkImageLabelOutline_h

#include "vtkImageData.h"
#include "vtkImageNeighborhoodFilter.h"
#include "vtkSlicer.h"

class VTK_SLICER_BASE_EXPORT vtkImageLabelOutline : public vtkImageNeighborhoodFilter
{
 public:
  static vtkImageLabelOutline *New();
  vtkTypeMacro(vtkImageLabelOutline,vtkImageNeighborhoodFilter);
  void PrintSelf(ostream& os, vtkIndent indent);

  // Description:
  // background pixel value in the image (usually 0)
  vtkSetMacro(Background, float);
  vtkGetMacro(Background, float);

  // Description:
  // not used (don't know what it was intended for)
  vtkSetMacro(Outline, int);
  vtkGetMacro(Outline, int);

 protected:
  vtkImageLabelOutline();
  ~vtkImageLabelOutline();

  float Background;
  int Outline;

  void ThreadedExecute(vtkImageData *inData, vtkImageData *outData, 
               int extent[6], int id);
};

#endif



