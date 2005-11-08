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
// .NAME vtkMrmlSegmenterAtlasClassNode - MRML node to represent transformation matrices.
// .SECTION Description
// The output of a rigid-body registration is a rotation and translation 
// expressed mathematically as a transformation matrix.  These transforms 
// can be inserted into MRML files as Segmenter nodes.  Each matrix 
// affects volumes and models that appear below it in the MRML file.  
// Multiple matrices can be concatenated together. 

#ifndef __vtkMrmlSegmenterAtlasGenericClassNode_h
#define __vtkMrmlSegmenterAtlasGenericClassNode_h

//#include <iostream.h>
//#include <fstream.h>
#include "vtkMrmlNode.h"
#include "vtkSlicer.h"
#include <vtkEMAtlasBrainClassifierConfigure.h>

// For the first stage super class is just a hirachical element, where we just define the name
// Extensions for later are planned
// Kilian 07-Oct-02

class VTK_EMATLASBRAINCLASSIFIER_EXPORT vtkMrmlSegmenterAtlasGenericClassNode : public vtkMrmlNode
{
public:
  static vtkMrmlSegmenterAtlasGenericClassNode *New();
  vtkTypeMacro(vtkMrmlSegmenterAtlasGenericClassNode,vtkMrmlNode);

  // Variable Set/Get Functions - Name has to be first to properly work with GUI   
  // Description:
  // Just is listed here so that it properly works with automatic GUI - nothing really is changed 
  vtkSetStringMacro(Name);
  vtkGetStringMacro(Name);
 
  // Any Variables afterwards 
  // Description:
  // Get/Set for Segmenter
  vtkSetMacro(Prob, double);
  vtkGetMacro(Prob, double);

  // Description:
  // This variable allows to control the influence of the LocalPrioir in the segmentation process 
  // LocalPriorWeight = 1.0 default setting; 0.0 => LocalPrior is ignored
  // Note: this variable is applied to all the subclasses during the segmentation bc the subclasses define the local Prior 
  vtkGetMacro(LocalPriorWeight,float);
  vtkSetMacro(LocalPriorWeight,float);

  // Description:
  // Get/Set for SegmenterClass - define name of spatial prior
  vtkSetStringMacro(LocalPriorName);
  vtkGetStringMacro(LocalPriorName);

  // Description:
  // This paramters allows the individual influence of each channel in the segmentation process 
  // by default 
  // The weight confidence measure describes the confidence in the weights form the EM algorithm
  // where the length(InputChannelWeights) = # of input channels 
  // Note: this variable is applied to all the subclasses during the segmentation bc the subclasses define the Tissue Cass Distributioon 
  vtkSetStringMacro(InputChannelWeights);
  vtkGetStringMacro(InputChannelWeights);

  // Description:
  // Print out Weights (1 = Normal 2=as shorts normed to 1000)   
  vtkGetMacro(PrintWeights, int);
  vtkSetMacro(PrintWeights, int);

protected:
  vtkMrmlSegmenterAtlasGenericClassNode();
  ~vtkMrmlSegmenterAtlasGenericClassNode();
  vtkMrmlSegmenterAtlasGenericClassNode(const vtkMrmlSegmenterAtlasGenericClassNode&) {};
  void operator=(const vtkMrmlSegmenterAtlasGenericClassNode&) {};

  void PrintSelf(ostream& os, vtkIndent indent);
  
  // Description:
  // Write the node's attributes to a MRML file in XML format
  void Write(ofstream& of);

  // Description:
  // Copy the node's attributes to this object
  void Copy(vtkMrmlNode *node);


  double Prob;
  float  LocalPriorWeight;
  char   *InputChannelWeights;  
  int    PrintWeights;
  char   *LocalPriorName;
};

#endif


/*
  // Description:  
  // Translation from patient case to atlas space   
  vtkGetVector3Macro(RegistrationTranslation, double);
  vtkSetVector3Macro(RegistrationTranslation, double);

  // Description:
  // Rotation from patient case to atlas space   
  vtkGetVector3Macro(RegistrationRotation, double);
  vtkSetVector3Macro(RegistrationRotation, double);

  // Description:
  // Scale from patient case to atlas space   
  vtkGetVector3Macro(RegistrationScale, double);
  vtkSetVector3Macro(RegistrationScale, double);

  // Description:
  // Diagonal Covariance Matrix (describing the zero Mean Gaussian distribution of the class registration parameters 
  vtkGetVectorMacro(RegistrationCovariance,double,9); 
  vtkSetVectorMacro(RegistrationCovariance,double,9);

  // Description:
  // Prints out the registration parameters translation - rotation -scaling 
  vtkGetMacro(PrintRegistrationParameters, int);
  vtkSetMacro(PrintRegistrationParameters, int);

  // Description:
  // Prints out the registration cost at each voxel 
  vtkGetMacro(PrintRegistrationSimularityMeasure, int);
  vtkSetMacro(PrintRegistrationSimularityMeasure, int);
  
  // Description:
  // If the class specific registration is activated by the superclass should this structure be optimizaed or ignored !
  // By default it is ignored (set to 0)
  vtkGetMacro(RegistrationClassSpecificRegistrationFlag,int); 
  vtkSetMacro(RegistrationClassSpecificRegistrationFlag,int); 
  vtkBooleanMacro(RegistrationClassSpecificRegistrationFlag,int); 
  // Description:
  // If you eant to include a class just being set via its intensity value than set this flag
  vtkGetMacro(ExcludeFromIncompleteEStepFlag,int);
  vtkSetMacro(ExcludeFromIncompleteEStepFlag,int);
  vtkBooleanMacro(ExcludeFromIncompleteEStepFlag,int);

  int    PrintRegistrationParameters;
  int    PrintRegistrationSimularityMeasure;

  double RegistrationTranslation[3];
  double RegistrationRotation[3];
  double RegistrationScale[3];
  double RegistrationCovariance[9];
  int RegistrationClassSpecificRegistrationFlag; 
  int ExcludeFromIncompleteEStepFlag;

 */