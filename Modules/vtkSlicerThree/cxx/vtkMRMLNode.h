/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMRMLNode.h,v $
  Date:      $Date: 2006/02/01 16:23:52 $
  Version:   $Revision: 1.3 $

=========================================================================auto=*/
// .NAME vtkMRMLNode - Abstract Superclass for all specific types of MRML nodes.
// .SECTION Description
// This node encapsulates the functionality common to all types of MRML nodes.
// This includes member variables for ID, Description, and Options,
// as well as member functions to Copy() and Write().

#ifndef __vtkMRMLNode_h
#define __vtkMRMLNode_h

#include "vtkObject.h"

class VTK_EXPORT vtkMRMLNode : public vtkObject
{
public:
  static vtkMRMLNode *New();
  vtkTypeMacro(vtkMRMLNode,vtkObject);
  void PrintSelf(ostream& os, vtkIndent indent);
  
  virtual vtkMRMLNode* CreateNodeInstance() = 0;

  // Description:
  // Copy everything from another node of the same type.
  // Instances of vtkMRMLNode must define the Copy function.
  // Instances of vtkMRMLNode::Copy should call vtkMRMLNode::CopyMrmlNode
  virtual void Copy(vtkMRMLNode *node);
  
  // Description:
  // Set/Get a numerical ID for the calling program to use to keep track
  // of its various node objects.
  vtkSetMacro(ID, int);
  vtkGetMacro(ID, int);
  
  // Description:
  // Text description of this node, to be set by the user
  vtkSetStringMacro(Description);
  vtkGetStringMacro(Description);
  
  // Description:
  // Name of this node, to be set by the user
  vtkSetStringMacro(Name);
  vtkGetStringMacro(Name);
  
  
  // Description:
  // Name of space in which this node lives
  vtkSetStringMacro(SpaceName);
  vtkGetStringMacro(SpaceName);
  
  // Description:
  // Set node attributes
  virtual void ReadXMLAttributes(const char** atts) = 0;
  
  // Description:
  // Write this node's information to a MRML file in XML format.
  // Only write attributes that differ from the default values,
  // which are set in the node's constructor.
  // This is a virtual function that all subclasses must overload.
  virtual void WriteXML(ostream& of, int indent) = 0;
  
  // Description:
  // Node's effect on indentation when displaying the
  // contents of a MRML file. (0, +1, -1)
  vtkGetMacro(Indent, int);
  
protected:
  
  vtkMRMLNode();
  // critical to have a virtual descructor!
  virtual ~vtkMRMLNode();
  vtkMRMLNode(const vtkMRMLNode&) {};
  void operator=(const vtkMRMLNode&) {};
  
  vtkSetMacro(Indent, int);
  
  int ID;
  char *Description;
  char *Name;
  char *SpaceName;
  int Indent;
};

#endif



