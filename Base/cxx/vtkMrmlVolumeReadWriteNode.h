/*=auto=========================================================================
  
(c) Copyright 2002 Massachusetts Institute of Technology

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
// .NAME vtkMrmlVolumeReadWriteNode - 
// .SECTION Description
// This sub-node should contain information specific to each
// type of volume that needs to be read in.  This can be used
// to clean up the special cases in this file which handle
// volumes of various types, such as dicom, header, etc.  In
// future these things can be moved to the sub-node specific for that
// type of volume.  The sub-nodes here that describe specific volume
// types each correspond to an implementation of the reader/writer,
// which can be found in a vtkMrmlDataVolumeReadWrite subclass.

#ifndef __vtkMrmlVolumeReadWriteNode_h
#define __vtkMrmlVolumeReadWriteNode_h

#include "vtkMrmlNode.h"
#include "vtkSlicer.h"

class VTK_SLICER_BASE_EXPORT vtkMrmlVolumeReadWriteNode : public vtkMrmlNode
{
  public:
  static vtkMrmlVolumeReadWriteNode *New();
  vtkTypeMacro(vtkMrmlVolumeReadWriteNode,vtkMrmlNode);
  void PrintSelf(ostream& os, vtkIndent indent);
  
  //--------------------------------------------------------------------------
  // Utility Functions
  //--------------------------------------------------------------------------
 
  // Description:
  // Copy the node's attributes to this object
  void Copy(vtkMrmlNode *node);

  // Description:
  // Write the node's attributes to a MRML file in XML format
  void Write(ofstream& of, int indent);
  
  //--------------------------------------------------------------------------
  // Specifics for each type of volume data
  //--------------------------------------------------------------------------

  // Type of vtkMrmlVolumeReadWriteNode we are.  This must be written to 
  // the MRML file so when it is read back in, a node of this type
  // can be created.
  vtkGetStringMacro(ReaderType);

  // Subclasses will add more here to handle their types of volume

protected:
  vtkMrmlVolumeReadWriteNode();
  ~vtkMrmlVolumeReadWriteNode();
  vtkMrmlVolumeReadWriteNode(const vtkMrmlVolumeReadWriteNode&) {};
  void operator=(const vtkMrmlVolumeReadWriteNode&) {};

  vtkSetStringMacro(ReaderType);
  char *ReaderType;
};

#endif
