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
// .NAME vtkMrmlLandmarkNode - MRML node to represent transformation matrices.
// .SECTION Description
// The output of a rigid-body registration is a rotation and translation 
// expressed mathematically as a transformation matrix.  These transforms 
// can be inserted into MRML files as Landmark nodes.  Each matrix 
// affects volumes and models that appear below it in the MRML file.  
// Multiple matrices can be concatenated together. 

#ifndef __vtkMrmlLandmarkNode_h
#define __vtkMrmlLandmarkNode_h

#include <iostream.h>
#include <fstream.h>
#include "vtkMrmlNode.h"

class VTK_EXPORT vtkMrmlLandmarkNode : public vtkMrmlNode
{
public:
  static vtkMrmlLandmarkNode *New();
  vtkTypeMacro(vtkMrmlLandmarkNode,vtkMrmlNode);
  void PrintSelf(ostream& os, vtkIndent indent);
  
  // Description:
  // Write the node's attributes to a MRML file in XML format
  void Write(ofstream& of, int indent);

  //--------------------------------------------------------------------------
  // Utility Functions
  //--------------------------------------------------------------------------

  // Description:
  // Copy the node's attributes to this object
  void Copy(vtkMrmlLandmarkNode *node);

  // Description:
  // Get/Set for Landmark
  vtkSetVector3Macro(XYZ,float);
  vtkGetVectorMacro(XYZ,float,3);

  // Description:
  // Get/Set for Landmark
  vtkSetVector3Macro(FXYZ,float);
  vtkGetVectorMacro(FXYZ,float,3);

  // Description:
  // Position of the landmark along the path
  vtkSetMacro(PathPosition, float);
  vtkGetMacro(PathPosition, float);

protected:
  vtkMrmlLandmarkNode();
  ~vtkMrmlLandmarkNode();
  vtkMrmlLandmarkNode(const vtkMrmlLandmarkNode&) {};
  void operator=(const vtkMrmlLandmarkNode&) {};

  float XYZ[3];
  float FXYZ[3];
  int PathPosition;
};

#endif

