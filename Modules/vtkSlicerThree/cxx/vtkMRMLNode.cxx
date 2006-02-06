/*=auto=========================================================================

Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

See Doc/copyright/copyright.txt
or http://www.slicer.org/copyright/copyright.txt for details.

Program:   3D Slicer
Module:    $RCSfile: vtkMRMLNode.cxx,v $
Date:      $Date: 2006/02/06 21:29:48 $
Version:   $Revision: 1.3 $

=========================================================================auto=*/
#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include "vtkMRMLNode.h"
#include "vtkObjectFactory.h"

//------------------------------------------------------------------------------
vtkMRMLNode* vtkMRMLNode::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkMRMLNode");
  if(ret)
    {
      return (vtkMRMLNode*)ret;
    }
  // If the factory was unable to create the object, then create it here.
  return NULL;
}

//------------------------------------------------------------------------------
vtkMRMLNode::vtkMRMLNode()
{
  this->ID = 0;
  
  // By default nodes have no effect on indentation
  this->Indent = 0;

  // Strings
  this->Description = NULL;

  // By default all MRML nodes have a blank name
  // Must set name to NULL first so that the SetName
  // macro will not free memory.
  this->Name = NULL;
  this->SetName("");

  this->SpaceName = NULL;
  this->SceneRootDir = NULL;
}

//----------------------------------------------------------------------------
vtkMRMLNode::~vtkMRMLNode()
{
  if (this->Description)
    {
      delete [] this->Description;
      this->Description = NULL;
    }
  
  if (this->SpaceName)
    {
      delete [] this->SpaceName;
      this->SpaceName = NULL;
    }
  
  if (this->Name)
    {
      delete [] this->Name;
      this->Name = NULL;
    }
}

//----------------------------------------------------------------------------
void vtkMRMLNode::Copy(vtkMRMLNode *node)
{
  this->SetDescription(node->GetDescription());
  this->SetSpaceName(node->GetSpaceName());
  this->SetName(strcat(node->GetName(), "1"));
}

//----------------------------------------------------------------------------
void vtkMRMLNode::PrintSelf(ostream& os, vtkIndent indent)
{
  this->vtkObject::PrintSelf(os,indent);

  os << indent << "ID:          " << this->ID << "\n";

  os << indent << "Indent:      " << this->Indent << "\n";

  os << indent << "Name: " <<
    (this->Name ? this->Name : "(none)") << "\n";

  os << indent << "Description: " <<
    (this->Description ? this->Description : "(none)") << "\n";

}

//----------------------------------------------------------------------------
void vtkMRMLNode::WriteXML(ostream& of, int nIndent)
{
  vtkErrorMacro("NOT IMPLEMENTED YET");
}

//----------------------------------------------------------------------------
void vtkMRMLNode::ReadXMLAttributes(const char** atts)
{
  char* attName;
  char* attValue;
  while (*atts != NULL) {
    attName = (char *)(*(atts++));
    attValue = (char *)(*(atts++));
    if (!strcmp(attName, "Name")) {
      this->SetName(attValue);
    }
    else if (!strcmp(attName, "Description")) {
      this->SetDescription(attValue);
    }
    else if (!strcmp(attName, "SpaceName")) {
      this->SetSpaceName(attValue);
    }
  } 
  return;
}