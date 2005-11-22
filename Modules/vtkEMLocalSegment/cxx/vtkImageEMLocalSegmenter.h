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
// .NAME vtkImageEMLocalSegmenter
// Since 22-Apr-02 vtkImageEMLocal3DSegmenter is called vtkImageEMLocalSegmenter - Kilian
// EMLocal =  using EM Algorithm with Local Tissue Class Probability
#ifndef __vtkImageEMLocalSegmenter_h
#define __vtkImageEMLocalSegmenter_h 
     
#include <vtkEMLocalSegmentConfigure.h> 
#include "vtkImageEMGeneral.h" 
#include "vtkImageEMLocalSuperClass.h"

// Just for debugging purposes
#define EM_DEBUG 1
 
// Kilian: Move it into ClassFunction later as soon as you know how to properly mention it here  
//--------------------------------------------------------------------
// Class Definition 
//--------------------------------------------------------------------
//ETX 
class VTK_EMLOCALSEGMENT_EXPORT vtkImageEMLocalSegmenter : public vtkImageEMGeneral
{
  public:
  // -----------------------------------------------------
  // Genral Functions for the filter
  // -----------------------------------------------------
  static vtkImageEMLocalSegmenter *New();
  vtkTypeMacro(vtkImageEMLocalSegmenter,vtkObject);

  void PrintSelf(ostream& os, vtkIndent indent);

  // -----------------------------------------------------
  // Message Protocol
  // -----------------------------------------------------

  char* GetErrorMessages() {return this->ErrorMessage.GetMessages(); }
  int GetErrorFlag() {return  this->ErrorMessage.GetFlag();}
  void ResetErrorMessage() {this->ErrorMessage.ResetParameters();}
  // So we can also enter streams for functions outside vtk
  ProtocolMessages* GetErrorMessagePtr(){return &this->ErrorMessage;}

  char* GetWarningMessages() {return this->WarningMessage.GetMessages(); }
  int GetWarningFlag() {return  this->WarningMessage.GetFlag();}
  void ResetWarningMessage() {this->WarningMessage.ResetParameters();}
  ProtocolMessages* GetWarningMessagePtr(){return &this->WarningMessage;}

  // -----------------------------------------------------
  // Setting Algorithm 
  // -----------------------------------------------------
  vtkSetMacro(Alpha, double);
  vtkGetMacro(Alpha, double);

  vtkSetMacro(SmoothingWidth, int);
  vtkGetMacro(SmoothingWidth, int);

  vtkSetMacro(SmoothingSigma, int);
  vtkGetMacro(SmoothingSigma, int);

  void SetNumberOfTrainingSamples(int Number) {this->NumberOfTrainingSamples = Number;}
  vtkGetMacro(NumberOfTrainingSamples, int);

  vtkGetStringMacro(PrintDir);
  vtkSetStringMacro(PrintDir);


  void SetImageInput(int index, vtkImageData *image) {this->SetInput(index,image);}

  vtkGetMacro(ImageProd, int); 

  // Description:
  // For validation purposes you might want to disable MultiThreading 
  // so that you get the same results on different machines. If disabled 
  // and run on multi processor machines it will lower the performance 
  vtkGetMacro(DisableMultiThreading,int); 
  vtkSetMacro(DisableMultiThreading,int); 

  // Desciption:
  // Head Class is the inital class under which all subclasses are attached  
  void SetHeadClass(vtkImageEMLocalSuperClass *InitHead);

  int* GetSegmentationBoundaryMin();
  int* GetSegmentationBoundaryMax();

  int* GetExtent(){return this->Extent;}

  // Desciption:
  // Dimension of work area => SegmentationBoundaryMax[i] - SegmentationBoundaryMin[i] + 1 
  int GetDimensionX();
  int GetDimensionY();
  int GetDimensionZ();


  // Description:
  // Number of input images for the segmentation - Has to be defined before defining any class specific setting 
  // Otherwise they get deleted
  // Be carefull: this is just the number of images not attlases, 
  // e.g. I have 5 tissue classes and 3 Inputs (T1, T2, SPGR) -> NumInputImages = 3
  void SetNumInputImages(int number);
  int GetNumInputImages() {return this->NumInputImages;} 

  // Description:
  // Define what kind of interpolation you want for the registration function - 
  // 1 = Linear Affine Registration 
  // 2 = Nearest Neighbour Affine Registration
   vtkSetMacro(RegistrationInterpolationType, int);
   vtkGetMacro(RegistrationInterpolationType, int);
   void SetInterpolationToNearestNeighbour() {this->RegistrationInterpolationType = EMSEGMENT_REGISTRATION_INTERPOLATION_NEIGHBOUR;}
   void SetInterpolationToLinear() {this->RegistrationInterpolationType = EMSEGMENT_REGISTRATION_INTERPOLATION_LINEAR;}


  // -----------------------------------------------------
  // Main Segmentation Function 
  // -----------------------------------------------------  
  // Needs to be public so we can access it from template functions
  //BTX
  int HierarchicalSegmentation(vtkImageEMLocalSuperClass* head, float** InputVector,short *ROI, short *OutputVector, EMTriVolume & iv_m, EMVolume *r_m, char* LevelName,  
                   float GlobalRotInvRotation[9], float GlobalRotInvTranslation[3]);

  vtkImageEMLocalSuperClass* GetActiveSuperClass() {return this->activeSuperClass;}
  vtkImageEMLocalSuperClass* GetHeadClass() {return this->HeadClass;}

protected:
  // -----------------------------------------------------
  // Protected Functions
  // -----------------------------------------------------
  vtkImageEMLocalSegmenter();
  vtkImageEMLocalSegmenter(const vtkImageEMLocalSegmenter&) {};
  ~vtkImageEMLocalSegmenter(); 
  void DeleteVariables();

  void operator=(const vtkImageEMLocalSegmenter&) {};
  void ExecuteData(vtkDataObject *);   

 // Description:
  // Resets the error flag and messages 
  void ResetMessageSettings();  

  // Description:
  // Checks all intput image if they have coresponding dimensions 
  int CheckInputImage(vtkImageData * inData,int DataTypeOrig, vtkFloatingPointType DataSpacingOrig[3], int num);


  double Alpha;        // alpha - Paramter 0<= alpaha <= 1

  int SmoothingWidth;  // Width for Gausian to regularize weights   
  int SmoothingSigma;  // Sigma paramter for regularizing Gaussian

  int NumInputImages;               // Number of input images  
 
  // These are defined in vtkEMImageLocalSegment
  char* PrintDir;        // In which directory should the results be printed  

  // New Variables for Local Version 
  int ImageProd;                   // Size of Image = DimensionX*DimensionY*DimensionZ

  int Extent[6];                  // Extent of images - needed for several inputs 

  int NumberOfTrainingSamples;    // Number of Training Samples Probability Image has been summed up over !  


  vtkImageEMLocalSuperClass *activeSuperClass;   // Currently Active Super Class -> Important for interface with TCL
  classType    activeClassType;

  vtkImageEMLocalSuperClass *HeadClass;          // Initial Class

  void   *activeClass;               // Currently Active Class -> Important for interface with TCL

  short  **DebugImage;             // Just used for debuging

  int    RegistrationInterpolationType;  // Registration Interpolation Type

  ProtocolMessages ErrorMessage;    // Lists all the error messges -> allows them to be displayed in tcl too 
  ProtocolMessages WarningMessage;  // Lists all the warning messges -> allows them to be displayed in tcl too 

  int    DisableMultiThreading;     // For validation purposes you might want to disable MultiThreading 
                                    // so that you get the same results on different machines 
  //ETX
};
#endif











