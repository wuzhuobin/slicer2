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
#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <math.h>
#include "vtkMrmlCrossSectionNode.h"
#include "vtkObjectFactory.h"

//------------------------------------------------------------------------------
vtkMrmlCrossSectionNode* vtkMrmlCrossSectionNode::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkMrmlCrossSectionNode");
  if(ret)
  {
    return (vtkMrmlCrossSectionNode*)ret;
  }
  // If the factory was unable to create the object, then create it here.
  return new vtkMrmlCrossSectionNode;
}

//----------------------------------------------------------------------------
vtkMrmlCrossSectionNode::vtkMrmlCrossSectionNode()
{
  // Strings
  this->Direction = NULL;
  this->BackVolRefID = NULL;
  this->ForeVolRefID = NULL;
  this->LabelVolRefID = NULL;
  
  // Numbers
  this->Position = 0;
  this->SliceSlider = 0;
  this->RotatorX = 0;
  this->RotatorY = 0;
  this->Zoom = 1.0;
  this->InModel = 0;
  this->ClipState = 1;
}

//----------------------------------------------------------------------------
vtkMrmlCrossSectionNode::~vtkMrmlCrossSectionNode()
{
  if (this->Direction)
  {
    delete [] this->Direction;
    this->Direction = NULL;
  }
  if (this->BackVolRefID)
  {
    delete [] this->BackVolRefID;
    this->BackVolRefID = NULL;
  }
  if (this->ForeVolRefID)
  {
    delete [] this->ForeVolRefID;
    this->ForeVolRefID = NULL;
  }
  if (this->LabelVolRefID)
  {
    delete [] this->LabelVolRefID;
    this->LabelVolRefID = NULL;
  }
}

//----------------------------------------------------------------------------
void vtkMrmlCrossSectionNode::Write(ofstream& of, int nIndent)
{
  // Write all attributes not equal to their defaults
  
  vtkIndent i1(nIndent);

  of << i1 << "<CrossSection";

  of << " position='" << this->Position << "'";
  
  // Strings
  if (this->Direction && strcmp(this->Direction, "")) 
  {
    of << " direction='" << this->Direction << "'";
  }
  else {
    of << " direction='none'";
  }
  if (this->BackVolRefID && strcmp(this->BackVolRefID, ""))
  {
    of << " backVolRefID='" << this->BackVolRefID << "'";
  }
  if (this->ForeVolRefID && strcmp(this->ForeVolRefID, ""))
  {
    of << " foreVolRefID='" << this->ForeVolRefID << "'";
  }
  if (this->LabelVolRefID && strcmp(this->LabelVolRefID, ""))
  {
    of << " labelVolRefID='" << this->LabelVolRefID << "'";
  }

  // Numbers
  if (this->InModel != 0)
  {
    of << " inmodel='" << (this->InModel ? "true":"false") << "'";
  }
  if (this->SliceSlider != 0)
  {
    of << " sliceslider='" << this->SliceSlider << "'";
  }
  if (this->RotatorX != 0)
  {
    of << " rotatorx='" << this->RotatorX << "'";
  }
  if (this->RotatorY != 0)
  {
    of << " rotatory='" << this->RotatorY << "'";
  }
  if (this->Zoom != 1.0)
  {
    of << " zoom='" << this->Zoom << "'";
  }
  if (this->ClipState != 1)
  {
    of << " clipState='" << (this->ClipState ? "true":"false") << "'";
  }
  of << "></CrossSection>\n";
}

//----------------------------------------------------------------------------
// Copy the node's attributes to this object.
// Does NOT copy: Position
void vtkMrmlCrossSectionNode::Copy(vtkMrmlNode *anode)
{
  vtkMrmlNode::MrmlNodeCopy(anode);
  vtkMrmlCrossSectionNode *node = (vtkMrmlCrossSectionNode *) anode;

  // Strings
  this->SetDirection(node->Direction);
  this->SetBackVolRefID(node->BackVolRefID);
  this->SetForeVolRefID(node->ForeVolRefID);
  this->SetLabelVolRefID(node->LabelVolRefID);
  // Numbers
  this->SetInModel(node->InModel);
  this->SetSliceSlider(node->SliceSlider);
  this->SetRotatorX(node->RotatorX);
  this->SetRotatorY(node->RotatorY);
  this->SetZoom(node->Zoom);
}

//----------------------------------------------------------------------------
void vtkMrmlCrossSectionNode::PrintSelf(ostream& os, vtkIndent indent)
{
  
  vtkMrmlNode::PrintSelf(os,indent);

  os << indent << "Position: " << this->Position << "\n";
  os << indent << "Description: " <<
    (this->Description ? this->Description : "(none)") << "\n";
  os << indent << "InModel: " << this->InModel << "\n";
  os << indent << "SliceSlider: " << this->SliceSlider << "\n";
  os << indent << "RotatorX: " << this->RotatorX << "\n";
  os << indent << "RotatorY: " << this->RotatorY << "\n";
  os << indent << "Zoom: " << this->Zoom << "\n";
  os << indent << "BackVolRefID: " << 
    (this->BackVolRefID ? this->BackVolRefID : "(none)") << "\n";
  os << indent << "ForeVolRefID: " <<
    (this->ForeVolRefID ? this->ForeVolRefID : "(none)") << "\n";
  os << indent << "LabelVolRefID: " <<
    (this->LabelVolRefID ? this->LabelVolRefID : "(none)") << "\n";
  os << indent << "ClipState: " << this->ClipState << "\n";
}
