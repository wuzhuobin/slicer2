/*=auto=========================================================================

(c) Copyright 2003 Massachusetts Institute of Technology (MIT) All Rights Reserved.

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
#include "vtkMrmlSegmenterClassNode.h"
#include "vtkObjectFactory.h"

//------------------------------------------------------------------------------
vtkMrmlSegmenterClassNode* vtkMrmlSegmenterClassNode::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkMrmlSegmenterClassNode");
  if(ret)
  {
    return (vtkMrmlSegmenterClassNode*)ret;
  }
  // If the factory was unable to create the object, then create it here.
  return new vtkMrmlSegmenterClassNode;
}

//----------------------------------------------------------------------------
vtkMrmlSegmenterClassNode::vtkMrmlSegmenterClassNode()
{
  // vtkMrmlNode's attributes => Tabs following sub classes  
  this->Indent     = 1;
  this->LocalPriorPrefix = NULL; 
  this->LocalPriorName   = NULL; 
  memset(this->LocalPriorRange,0,2*sizeof(int));
  this->LogMean          = NULL;
  this->LogCovariance    = NULL;
  this->Label            = 0;
  this->Prob             = 0.0;
  this->ShapeParameter   = 0.0;
  this->LocalPriorWeight = 1.0;
  this->InputChannelWeights = NULL;
  this->PCAMeanName      = NULL; 
  memset(this->PCAFileRange,0,2*sizeof(int));
  this->PCAMaxDist       = 0.0;
  this->PCADistVariance  = 0.0; 
  this->ReferenceStandardFileName     = NULL; 
  
  this->PrintWeights        = 0;
  this->PrintQuality        = 0;
  this->PrintPCA            = 0;

  memset(this->RegistrationTranslation,0,3*sizeof(double));
  memset(this->RegistrationRotation,0,3*sizeof(double));
  for (int i =0; i < 3; i++) RegistrationScale[i]= 1.0;
  for (int i = 0; i < 6; i++) this->RegistrationCovariance[i] = 1.0;
  this->RegistrationCovariance[6] = this->RegistrationCovariance[7] = this->RegistrationCovariance[8] = 0.1;
}

//----------------------------------------------------------------------------
vtkMrmlSegmenterClassNode::~vtkMrmlSegmenterClassNode()
{
  if (this->LocalPriorPrefix)
  {
    delete [] this->LocalPriorPrefix;
    this->LocalPriorPrefix = NULL;
  }
  if (this->LocalPriorName)
  {
    delete [] this->LocalPriorName;
    this->LocalPriorName = NULL;
  }
  if (this->LogMean)
  {
    delete [] this->LogMean;
    this->LogMean = NULL;
  }
  if (this->LogCovariance)
  {
    delete [] this->LogCovariance;
    this->LogCovariance = NULL;
  }
  
  if (this->InputChannelWeights) {
    delete [] this->InputChannelWeights;
    this->InputChannelWeights = NULL;
  }

  if (this->PCAMeanName)
  {
    delete [] this->PCAMeanName;
    this->PCAMeanName = NULL;
  }

  if (this->ReferenceStandardFileName)
  {
    delete [] this->ReferenceStandardFileName;
    this->ReferenceStandardFileName = NULL;
  }


}

//----------------------------------------------------------------------------
void vtkMrmlSegmenterClassNode::Write(ofstream& of, int nIndent)
{
  // Write all attributes not equal to their defaults
  
  vtkIndent i1(nIndent);

  of << i1 << "<SegmenterClass";
  if (this->Name && strcmp(this->Name, ""))  {
    of << " name ='" << this->Name << "'";
  }
  of << " Label='" << this->Label << "'";
  of << " Prob='" << this->Prob << "'";
  of << " ShapeParameter='" << this->ShapeParameter << "'";
  
  if (this->LocalPriorPrefix && strcmp(this->LocalPriorPrefix, "")) 
  {
    of << " LocalPriorPrefix='" << this->LocalPriorPrefix << "'";
  }
  if (this->LocalPriorName && strcmp(this->LocalPriorName, "")) 
  {
    of << " LocalPriorName='" << this->LocalPriorName << "'";
  }
  if (this->LocalPriorRange[0] != 0 || this->LocalPriorRange[1] != 0)
  {
    of << " LocalPriorRange='" << this->LocalPriorRange[0] << " "
       << this->LocalPriorRange[1] << "'";
  }
  if (this->LogMean && strcmp(this->LogMean, "")) 
  {
    of << " LogMean='" << this->LogMean << "'";
  }
  if (this->LogCovariance && strcmp(this->LogCovariance, "")) 
  {
    of << " LogCovariance='" << this->LogCovariance << "'";
  }

  if (this->InputChannelWeights && strcmp(this->InputChannelWeights, "")) 
  {
    of << " InputChannelWeights='" << this->InputChannelWeights << "'";
  }
  of << " LocalPriorWeight='" << this->LocalPriorWeight << "'";

  if (this->PCAMeanName && strcmp( this->PCAMeanName, "")) 
  {
    of << " PCAMeanName='" << this->PCAMeanName << "'";
  }

  if (this->ReferenceStandardFileName && strcmp(this->ReferenceStandardFileName, "")) 
  {
    of << " ReferenceStandardFileName='" << this->ReferenceStandardFileName << "'";
  }
  if  (this->PCAFileRange[0] || this->PCAFileRange[1]) of << " PCAFileRange='" << this->PCAFileRange[0] << " " << this->PCAFileRange[1] << "'";

  of << " PCAMaxDist='" << this->PCAMaxDist << "'";
  of << " PCADistVariance='" << this->PCADistVariance << "'";
  of << " PrintWeights='" << this->PrintWeights << "'";
  of << " PrintQuality='" << this->PrintQuality << "'";
  of << " PrintPCA='" << this->PrintPCA << "'";

  if  (this->RegistrationTranslation[0] || this->RegistrationTranslation[1] || this->RegistrationTranslation[2]) of << " RegistrationTranslation='" << this->RegistrationTranslation[0] << " " << this->RegistrationTranslation[1] << " " << this->RegistrationTranslation[2] << "'";
  if  (this->RegistrationRotation[0] || this->RegistrationRotation[1] || this->RegistrationRotation[2]) of << " RegistrationRotation='" << this->RegistrationRotation[0] << " " << this->RegistrationRotation[1] << " " << this->RegistrationRotation[2] << "'";
  if  ((this->RegistrationScale[0] != 1) || (this->RegistrationScale[1] != 1) || (this->RegistrationScale[2] != 1)) of << " RegistrationScale='" << this->RegistrationScale[0] << " " << this->RegistrationScale[1] << " " << this->RegistrationScale[2] << "'";

  of << " RegistrationCovariance='";
  for(int i=0; i < 9; i++)  of << this->RegistrationCovariance[i] << " ";
  of << "'"; 

  of << ">\n";
}

//----------------------------------------------------------------------------
// Copy the node's attributes to this object.
// Does NOT copy: ID, Name
void vtkMrmlSegmenterClassNode::Copy(vtkMrmlNode *anode)
{
  vtkMrmlNode::MrmlNodeCopy(anode);
  vtkMrmlSegmenterClassNode *node = (vtkMrmlSegmenterClassNode *) anode;

  this->SetLabel(node->Label);
  this->SetProb(node->Prob);
  this->SetShapeParameter(node->ShapeParameter);
  this->SetLocalPriorPrefix(node->LocalPriorPrefix); 
  this->SetLocalPriorName(node->LocalPriorName); 
  this->SetLocalPriorRange(node->LocalPriorRange); 
  this->SetLogMean(node->LogMean);
  this->SetLogCovariance(node->LogCovariance);
  this->SetInputChannelWeights(node->InputChannelWeights);
  this->SetLocalPriorWeight(node->LocalPriorWeight);
  this->SetPCAFileRange(node->PCAFileRange);
  this->SetPCAMeanName(node->PCAMeanName);
  this->SetReferenceStandardFileName(node->ReferenceStandardFileName);
  this->SetRegistrationTranslation(node->RegistrationTranslation);
  this->SetRegistrationRotation(node->RegistrationRotation);
  this->SetRegistrationScale(node->RegistrationScale);
  this->SetRegistrationCovariance(node->RegistrationCovariance);

  this->SetPCAMaxDist(node->PCAMaxDist);
  this->SetPCADistVariance(node->PCADistVariance);

  this->SetPrintWeights(node->PrintWeights);
  this->SetPrintQuality(node->PrintQuality);
  this->SetPrintPCA(node->PrintPCA);
}

//----------------------------------------------------------------------------
void vtkMrmlSegmenterClassNode::PrintSelf(ostream& os, vtkIndent indent)
{
  vtkMrmlNode::PrintSelf(os,indent);
   os << indent << "Name: " <<
    (this->Name ? this->Name : "(none)") << "\n";
   os << indent << "Label: " << this->Label << "\n";
   os << indent << "Prob: " << this->Prob << "\n";
   os << indent << "ShapeParameter: " << this->ShapeParameter << "\n";

   os << indent << "LocalPriorPrefix: " <<
    (this->LocalPriorPrefix ? this->LocalPriorPrefix : "(none)") << "\n";
   os << indent << "LocalPriorName: " <<
    (this->LocalPriorName ? this->LocalPriorName : "(none)") << "\n";
   os << indent << "LocalPriorRange: " << this->LocalPriorRange[0] << ", " << this->LocalPriorRange[1] << "\n" ;
   os << indent << "LocalPriorWeight: " << this->LocalPriorWeight << "\n";

   os << indent << "LogMean: " <<
    (this->LogMean ? this->LogMean : "(none)") << "\n";
   os << indent << "LogCovariance: " <<
    (this->LogCovariance ? this->LogCovariance : "(none)") << "\n";

   os << indent << "InputChannelWeights: " << 
    (this->InputChannelWeights ? this->InputChannelWeights : "(none)") << "\n";

   os << indent << "ReferenceStandardFileName: " <<  (this->ReferenceStandardFileName ? this->ReferenceStandardFileName : "(none)") << "\n"; 
   os << indent << "PCAMeanName:               " <<  (this->PCAMeanName ? this->PCAMeanName : "(none)") << "\n"; 
   os << indent << "PCAFileRange:              " << this->PCAFileRange[0] << ", " << this->PCAFileRange[1] << "\n" ;
   os << indent << "PCAMaxDist:                " << this->PCAMaxDist << "\n";
   os << indent << "PCADistVariance:           " << this->PCADistVariance << "\n";

   os << indent << "PrintWeights:              " << this->PrintWeights << "\n";
   os << indent << "PrintQuality:              " << this->PrintQuality << "\n";
   os << indent << "PrintPCA:                  " << this->PrintPCA << "\n";

   os << indent << "RegistrationTranslation:   " << this->RegistrationTranslation[0] << ", " << this->RegistrationTranslation[1] << ", " << this->RegistrationTranslation[2] << "\n" ;
   os << indent << "RegistrationRotation:      " << this->RegistrationRotation[0] << ", " << this->RegistrationRotation[1] << ", " << this->RegistrationRotation[2] << "\n" ;
   os << indent << "RegistrationScale:         " << this->RegistrationScale[0] << ", " << this->RegistrationScale[1] << ", " << this->RegistrationScale[2] << "\n" ;
   os << indent << "RegistrationCovariance:    " ;
   for (int i = 0 ; i < 9 ; i++)  os << RegistrationCovariance[i] << " "; 
   os << "\n" ;
}
