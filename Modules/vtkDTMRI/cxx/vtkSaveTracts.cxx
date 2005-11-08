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
#include "vtkSaveTracts.h"

#include "vtkAppendPolyData.h"
#include "vtkPolyDataWriter.h"
#include "vtkTransformPolyDataFilter.h"
#include "vtkMrmlModelNode.h"

#include "vtkPolyData.h"
#include "vtkTubeFilter.h"
#include "vtkProbeFilter.h"
#include "vtkPointData.h"
#include "vtkMath.h"

#include "vtkActor.h"
#include "vtkProperty.h"

#include <sstream>

#include "vtkHyperStreamline.h"
#include "vtkHyperStreamlinePoints.h"
#include "vtkPreciseHyperStreamlinePoints.h"

//#include "vtkImageWriter.h"

//------------------------------------------------------------------------------
vtkSaveTracts* vtkSaveTracts::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkSaveTracts");
  if(ret)
    {
      return (vtkSaveTracts*)ret;
    }
  // If the factory was unable to create the object, then create it here.
  return new vtkSaveTracts;
}

//----------------------------------------------------------------------------
vtkSaveTracts::vtkSaveTracts()
{
  // Initialize these to identity, so if the user doesn't set them it's okay.
  this->WorldToTensorScaledIJK = vtkTransform::New();
  this->TensorRotationMatrix = vtkMatrix4x4::New();

  // collections
  this->Streamlines = NULL;
  this->TubeFilters = NULL;
  this->Actors = NULL;

  // optional input data
  this->InputTensorField = NULL;
  
  // settings
  this->SaveForAnalysis = 0;
}

//----------------------------------------------------------------------------
vtkSaveTracts::~vtkSaveTracts()
{
  this->WorldToTensorScaledIJK->Delete();
  if (this->Streamlines) this->Streamlines->Delete();
  if (this->TubeFilters) this->TubeFilters->Delete();
}


void vtkSaveTracts::SaveStreamlinesAsPolyData(char *filename,                                                                char *name)
{
  this->SaveStreamlinesAsPolyData(filename, name, NULL);
}


// NOTE: Limit currently is 1000 models (1000 different input colors is max).
//----------------------------------------------------------------------------
void vtkSaveTracts::SaveStreamlinesAsPolyData(char *filename,
                                              char *name,
                                              vtkMrmlTree *colorTree)
{
  vtkHyperStreamline *currStreamline;
  vtkTubeFilter *currTubeFilter;
  vtkActor *currActor;
  vtkCollection *collectionOfModels;
  vtkAppendPolyData *currAppender;
  vtkPolyDataWriter *writer;
  vtkTransformPolyDataFilter *currTransformer;
  vtkTransform *currTransform;
  double R[1000], G[1000], B[1000];
  int arraySize=1000;
  int lastColor;
  int currColor, newColor, idx, found;
  vtkFloatingPointType rgb_vtk_float[3];
  double rgb[3];
  std::stringstream fileNameStr;
  vtkMrmlTree *tree;
  vtkMrmlModelNode *currNode;
  vtkMrmlColorNode *currColorNode;
  std::stringstream colorNameStr;
  vtkMrmlTree *colorTreeTwo;


  // Test that we have required input
  if (this->Streamlines == 0) 
    {
      vtkErrorMacro("You need to set the Streamlines before saving tracts.");
      return;
    }
  if (this->TubeFilters == 0) 
    {
      vtkErrorMacro("You need to set the TubeFilters before saving tracts.");
      return;
    }
  if (this->Actors == 0) 
    {
      vtkErrorMacro("You need to set the Actors before saving tracts.");
      return;
    }

  // If saving for analysis need to have tensors to save
  if (this->SaveForAnalysis) 
    {
      if (this->InputTensorField == 0) 
        {      
          vtkErrorMacro("You need to set the InputTensorField when using SaveForAnalysis.");
          return;
        }
    }

  // traverse streamline collection, grouping streamlines into models by color
  this->Streamlines->InitTraversal();
  this->TubeFilters->InitTraversal();
  this->Actors->InitTraversal();
  currStreamline= (vtkHyperStreamline *)this->Streamlines->GetNextItemAsObject();
  currTubeFilter= (vtkTubeFilter *) this->TubeFilters->GetNextItemAsObject();
  currActor= (vtkActor *)this->Actors->GetNextItemAsObject();

  // test we have actors and streamlines
  if (currActor == NULL || currStreamline == NULL || currTubeFilter == NULL)
    {
      vtkErrorMacro("No streamlines have been created yet.");
      return;      
    }

  // init things with the first streamline.
  currActor->GetProperty()->GetColor(rgb);
  currAppender = vtkAppendPolyData::New();
  collectionOfModels = vtkCollection::New();
  collectionOfModels->AddItem((vtkObject *)currAppender);
  lastColor=0;
  R[0]=rgb[0];
  G[0]=rgb[1];
  B[0]=rgb[2];

  cout << "Traverse STREAMLINES" << endl;
  while(currStreamline && currActor && currTubeFilter)
    {
      cout << "stream " << currStreamline << endl;
      currColor=0;
      newColor=1;
      // If we have this color already, store its index in currColor
      while (currColor<=lastColor && currColor<arraySize)
        {
          currActor->GetProperty()->GetColor(rgb);
          if (rgb[0]==R[currColor] &&
              rgb[1]==G[currColor] &&
              rgb[2]==B[currColor])
            {
              newColor=0;
              break;
            }
          currColor++;
        }

      // if this is a new color, we must create a new model to save.
      if (newColor)
        {
          // add an appender to the collection of models.
          currAppender = vtkAppendPolyData::New();
          collectionOfModels->AddItem((vtkObject *)currAppender);
          // increment count of colors
          lastColor=currColor;
          // save this color's info in the array
          R[currColor]=rgb[0];
          G[currColor]=rgb[1];
          B[currColor]=rgb[2];

        }
      else
        {
          // use the appender number currColor that we found in the while loop
          currAppender = (vtkAppendPolyData *) 
            collectionOfModels->GetItemAsObject(currColor);
        }

      // Append this streamline to the chosen model using the appender
      if (this->SaveForAnalysis) {
        currAppender->AddInput(currStreamline->GetOutput());
      } 
      else {
        currAppender->AddInput(currTubeFilter->GetOutput());        
      }
      // get next objects in collections
      currStreamline= (vtkHyperStreamline *)
        this->Streamlines->GetNextItemAsObject();
      currTubeFilter= (vtkTubeFilter *)
        this->TubeFilters->GetNextItemAsObject();
      currActor = (vtkActor *) this->Actors->GetNextItemAsObject();
    }


  // traverse appender collection (collectionOfModels) and write each to disk
  cout << "Traverse APPENDERS" << endl;
  writer = vtkPolyDataWriter::New();
  tree = vtkMrmlTree::New();
  // object to hold any new colors we encounter (not on input color tree)
  colorTreeTwo = vtkMrmlTree::New();

  collectionOfModels->InitTraversal();
  currAppender = (vtkAppendPolyData *) 
    collectionOfModels->GetNextItemAsObject();
  idx=0;

  // Create transformation matrix for writing paths.
  // This was used to place actors in scene.
  // (scaled IJK to world)
  currTransform=vtkTransform::New();
  currTransform->SetMatrix(this->WorldToTensorScaledIJK->GetMatrix());
  currTransform->Inverse();

  while(currAppender)
    {
      cout << idx << endl;


      if (this->SaveForAnalysis) {
        // First find the tensors that correspond to each point on the paths.
        // Note the paths are still in the scaled IJK coordinate system
        // so the probing makes sense.
        vtkProbeFilter *probe = vtkProbeFilter::New();
        probe->SetSource(this->InputTensorField);
        probe->SetInput(currAppender->GetOutput());
        vtkDebugMacro("Probing tensors");
        probe->Update();


        // Next transform models so that they are written in the coordinate
        // system in which they are displayed. (world coordinates, RAS + transforms)
        currTransformer = vtkTransformPolyDataFilter::New();
        currTransformer->SetTransform(currTransform);
        currTransformer->SetInput(probe->GetPolyDataOutput());
        vtkDebugMacro("Transforming PolyData");
        currTransformer->Update();
        
        // Here we rotate the tensors into the same (world) coordinate system.
        // -------------------------------------------------
        vtkDebugMacro("Rotating tensors");
        int numPts = probe->GetPolyDataOutput()->GetNumberOfPoints();
        vtkFloatArray *newTensors = vtkFloatArray::New();
        newTensors->SetNumberOfComponents(9);
        newTensors->Allocate(9*numPts);
        
        vtkDebugMacro("Rotating tensors: init");
        double (*matrix)[4] = this->TensorRotationMatrix->Element;
        double tensor[9];
        double tensor3x3[3][3];
        double temp3x3[3][3];
        double matrix3x3[3][3];
        double matrixTranspose3x3[3][3];
        for (int row = 0; row < 3; row++)
          {
            for (int col = 0; col < 3; col++)
              {
                matrix3x3[row][col] = matrix[row][col];
                matrixTranspose3x3[row][col] = matrix[col][row];
              }
          }
        
        vtkDebugMacro("Rotating tensors: get tensors from probe");        
        vtkDataArray *oldTensors = probe->GetOutput()->GetPointData()->GetTensors();
        
        vtkDebugMacro("Rotating tensors: rotate");
        for (vtkIdType i = 0; i < numPts; i++)
          {
            oldTensors->GetTuple(i,tensor);
            int idx = 0;
            for (int row = 0; row < 3; row++)
              {
                for (int col = 0; col < 3; col++)
                  {
                    tensor3x3[row][col] = tensor[idx];
                    idx++;
                  }
              }          
            // rotate by our matrix
            // R T R'
            vtkMath::Multiply3x3(matrix3x3,tensor3x3,temp3x3);
            vtkMath::Multiply3x3(temp3x3,matrixTranspose3x3,tensor3x3);
            
            idx =0;
            for (int row = 0; row < 3; row++)
              {
                for (int col = 0; col < 3; col++)
                  {
                    tensor[idx] = tensor3x3[row][col];
                    idx++;
                  }
              }  
            newTensors->InsertNextTuple(tensor);
          }
        
        vtkDebugMacro("Rotating tensors: add to new pd");
        vtkPolyData *data = vtkPolyData::New();
        data->SetLines(currTransformer->GetOutput()->GetLines());
        data->SetPoints(currTransformer->GetOutput()->GetPoints());
        data->GetPointData()->SetTensors(newTensors);
        vtkDebugMacro("Done rotating tensors");
        // End of tensor rotation code.
        // -------------------------------------------------
        
        writer->SetInput(data);
        probe->Delete();

        // Write as ASCII for easier reading into matlab
        writer->SetFileTypeToASCII();

      }
      else {
        // Else we are saving just the output tube
        // Next transform models so that they are written in the coordinate
        // system in which they are displayed. (world coordinates, RAS + transforms)
        currTransformer = vtkTransformPolyDataFilter::New();
        currTransformer->SetTransform(currTransform);
        currTransformer->SetInput(currAppender->GetOutput());
        currTransformer->Update();

        writer->SetInput(currTransformer->GetOutput());

        // Write as binary
        writer->SetFileTypeToBinary();

      }


      // Check for scalars
      int ScalarVisibility = 0;
      double range[2];
      if (writer->GetInput()->GetPointData()->GetScalars()) {
        ScalarVisibility = 1;
        writer->GetInput()->GetPointData()->GetScalars()->GetRange(range);
      }

      // clear the buffer (set to empty string)
      fileNameStr.str("");
      fileNameStr << filename << '_' << idx << ".vtk";
      writer->SetFileName(fileNameStr.str().c_str());
      writer->Write();
      currTransformer->Delete();

      // Delete it (but it survives until the collection it's on is deleted).
      currAppender->Delete();

      // Also write a MRML file: add to MRML tree
      currNode=vtkMrmlModelNode::New();
      currNode->SetFullFileName(fileNameStr.str().c_str());
      currNode->SetFileName(fileNameStr.str().c_str());
      // use the name argument to name the model (name label in slicer GUI)
      fileNameStr.str("");
      fileNameStr << name << '_' << idx;
      currNode->SetName(fileNameStr.str().c_str());
      currNode->SetDescription("Model of a DTMRI tract");


      if (ScalarVisibility) {
        currNode->ScalarVisibilityOn();
        currNode->SetScalarRange(range);
      }
      currNode->ClippingOn();


      // Find the name of the color if it's on the input color tree.
      found = 0;
      if (colorTree)
        {
          colorTree->InitTraversal();
          currColorNode = (vtkMrmlColorNode *) colorTree->GetNextItemAsObject();
          while (currColorNode)
            {
              currColorNode->GetDiffuseColor(rgb_vtk_float);
              if (rgb_vtk_float[0]==R[idx] &&
                  rgb_vtk_float[1]==G[idx] &&
                  rgb_vtk_float[2]==B[idx])              
                {
                  found = 1;
                  currNode->SetColor(currColorNode->GetName());
                  break;
                }
              currColorNode = (vtkMrmlColorNode *) 
                colorTree->GetNextItemAsObject();
            }
        }

      // If we didn't find the color on the input color tree, 
      // make a node for it then put it onto the new color tree.
      if (found == 0) 
        {
          currColorNode = vtkMrmlColorNode::New();
          rgb_vtk_float[0] = R[idx];
          rgb_vtk_float[1] = G[idx];
          rgb_vtk_float[2] = B[idx];
          currColorNode->SetDiffuseColor(rgb_vtk_float);
          colorNameStr.str("");
          colorNameStr << "class_" << idx ;
          currColorNode->SetName(colorNameStr.str().c_str());
          currNode->SetColor(currColorNode->GetName());
          // add it to the MRML tree with new colors
          colorTreeTwo->AddItem(currColorNode);
          // call Delete to decrement the reference count
          // so that when we delete the tree the nodes delete too.
          currColorNode->Delete();
        }

      // add it to the MRML file
      tree->AddItem(currNode);

      currAppender = (vtkAppendPolyData *) 
        collectionOfModels->GetNextItemAsObject();
      idx++;
    } 

  // If we had color inputs put them at the end of the MRML file
  if (colorTree)
    {
      colorTree->InitTraversal();
      currColorNode = (vtkMrmlColorNode *) colorTree->GetNextItemAsObject();      
      while (currColorNode)
        {
          tree->AddItem(currColorNode);
          currColorNode = (vtkMrmlColorNode *) 
            colorTree->GetNextItemAsObject();
        }
    }
  // Also add any new colors we found
  colorTreeTwo->InitTraversal();
  currColorNode = (vtkMrmlColorNode *) colorTreeTwo->GetNextItemAsObject();      
  while (currColorNode)
    {
      tree->AddItem(currColorNode);
      currColorNode = (vtkMrmlColorNode *) 
        colorTreeTwo->GetNextItemAsObject();
    }
  
  // Write the MRML file
  fileNameStr.str("");
  fileNameStr << filename << ".xml";
  tree->Write((char *)fileNameStr.str().c_str());

  cout << "DELETING" << endl;

  // Delete all objects we created
  collectionOfModels->Delete();
  writer->Delete();
  tree->Delete();
  colorTreeTwo->Delete();
  currTransform->Delete();

}






