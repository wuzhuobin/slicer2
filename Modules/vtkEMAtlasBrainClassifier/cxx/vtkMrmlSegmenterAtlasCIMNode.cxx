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
#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <math.h>
#include "vtkMrmlSegmenterAtlasCIMNode.h"
#include "vtkObjectFactory.h"

//------------------------------------------------------------------------------
vtkMrmlSegmenterAtlasCIMNode* vtkMrmlSegmenterAtlasCIMNode::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkMrmlSegmenterAtlasCIMNode");
  if(ret)
  {
    return (vtkMrmlSegmenterAtlasCIMNode*)ret;
  }
  // If the factory was unable to create the object, then create it here.
  return new vtkMrmlSegmenterAtlasCIMNode;
}

//----------------------------------------------------------------------------
vtkMrmlSegmenterAtlasCIMNode::vtkMrmlSegmenterAtlasCIMNode()
{
  this->CIMMatrix = NULL; 
}

//----------------------------------------------------------------------------
vtkMrmlSegmenterAtlasCIMNode::~vtkMrmlSegmenterAtlasCIMNode()
{
  if (this->CIMMatrix)
  {
    delete [] this->CIMMatrix;
    this->CIMMatrix = NULL;
  }
}

//----------------------------------------------------------------------------
void vtkMrmlSegmenterAtlasCIMNode::Write(ofstream& of)
{
  // Write all attributes not equal to their defaults

  if (this->Name && strcmp(this->Name, "")) 
  {
    of << " name ='" << this->Name << "'";
  }
  if (this->CIMMatrix && strcmp(this->CIMMatrix, "")) 
  {
    of << " CIMMatrix='" << this->CIMMatrix << "'";
  }
}

//----------------------------------------------------------------------------
// Copy the node's attributes to this object.
// Does NOT copy: ID, Name
void vtkMrmlSegmenterAtlasCIMNode::Copy(vtkMrmlNode *anode)
{
  vtkMrmlSegmenterAtlasCIMNode *node = (vtkMrmlSegmenterAtlasCIMNode *) anode;

  this->SetCIMMatrix(node->CIMMatrix); 
}

//----------------------------------------------------------------------------
void vtkMrmlSegmenterAtlasCIMNode::PrintSelf(ostream& os, vtkIndent indent)
{
   os << indent << "Name: " <<
    (this->Name ? this->Name : "(none)") << "\n";
   os << indent << "CIMMatrix: " <<
    (this->CIMMatrix ? this->CIMMatrix : "(none)") << "\n";
   os << ")\n";
}
