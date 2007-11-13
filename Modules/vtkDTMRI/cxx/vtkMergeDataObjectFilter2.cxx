/*=========================================================================

  Program:   Visualization Toolkit
  Module:    $RCSfile: vtkMergeDataObjectFilter2.cxx,v $

  Copyright (c) Ken Martin, Will Schroeder, Bill Lorensen
  All rights reserved.
  See Copyright.txt or http://www.kitware.com/Copyright.htm for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.  See the above copyright notice for more information.

=========================================================================*/
#include "vtkMergeDataObjectFilter2.h"

#include "vtkCellData.h"
#include "vtkDataSet.h"
#include "vtkFieldData.h"
#include "vtkFieldDataToAttributeDataFilter.h"
#include "vtkObjectFactory.h"
#include "vtkPointData.h"

vtkCxxRevisionMacro(vtkMergeDataObjectFilter2, "$Revision: 1.1.2.1 $");
vtkStandardNewMacro(vtkMergeDataObjectFilter2);

//----------------------------------------------------------------------------
// Create object with no input or output.
vtkMergeDataObjectFilter2::vtkMergeDataObjectFilter2()
{
  this->OutputField = VTK_DATA_OBJECT_FIELD;
}

//----------------------------------------------------------------------------
vtkMergeDataObjectFilter2::~vtkMergeDataObjectFilter2()
{
}

//----------------------------------------------------------------------------
// Specify a data object at a specified table location.
void vtkMergeDataObjectFilter2::SetDataObject(vtkDataObject *d)
{
  this->vtkProcessObject::SetNthInput(1, d);
}

//----------------------------------------------------------------------------
// Get a pointer to a data object at a specified table location.
vtkDataObject *vtkMergeDataObjectFilter2::GetDataObject()
{
  if (this->NumberOfInputs < 2)
    {
    return NULL;
    }
  else
    {
    return this->Inputs[1];
    }
}


//----------------------------------------------------------------------------
// Merge it all together
void vtkMergeDataObjectFilter2::Execute()
{
  vtkDataObject *dataObject=this->GetDataObject();
  vtkFieldData *fd;
  vtkDataSet *input=this->GetInput();
  vtkDataSet *output=this->GetOutput();
  
  vtkDebugMacro(<<"Merging dataset and data object");

  if (dataObject == NULL)
    {
    vtkErrorMacro(<< "Data Object's Field Data is NULL.");
    return;
    }

  fd=dataObject->GetFieldData();

  // First, copy the input to the output as a starting point
  output->CopyStructure( input );

  // Pass here so that the attributes/fields can be over-written later
  output->GetPointData()->PassData(input->GetPointData());
  output->GetCellData()->PassData(input->GetCellData());



  if ( this->OutputField == VTK_CELL_DATA_FIELD )
    {
    int ncells=fd->GetNumberOfTuples();
    if ( ncells != input->GetNumberOfCells() )
      {
      vtkErrorMacro(<<"Field data size incompatible with number of cells");
      return;
      }
    for(int i=0; i<fd->GetNumberOfArrays(); i++)
      {
      output->GetCellData()->AddArray(fd->GetArray(i));
      }
    }
  else if ( this->OutputField == VTK_POINT_DATA_FIELD )
    {
    int npts=fd->GetNumberOfTuples();
    if ( npts != input->GetNumberOfPoints() )
      {
      vtkErrorMacro(<<"Field data size incompatible with number of points");
      return;
      }
    for(int i=0; i<fd->GetNumberOfArrays(); i++)
      {
      output->GetPointData()->AddArray(fd->GetArray(i));
      }
    }
}

//----------------------------------------------------------------------------
void vtkMergeDataObjectFilter2::SetOutputFieldToDataObjectField() 
{
  this->SetOutputField(VTK_DATA_OBJECT_FIELD);
}

//----------------------------------------------------------------------------
void vtkMergeDataObjectFilter2::SetOutputFieldToPointDataField() 
{
  this->SetOutputField(VTK_POINT_DATA_FIELD);
}

//----------------------------------------------------------------------------
void vtkMergeDataObjectFilter2::SetOutputFieldToCellDataField() 
{
  this->SetOutputField(VTK_CELL_DATA_FIELD);
}

//----------------------------------------------------------------------------
void vtkMergeDataObjectFilter2::PrintSelf(ostream& os, vtkIndent indent)
{
  this->Superclass::PrintSelf(os,indent);

  os << indent << "Output Field: ";
  if ( this->OutputField == VTK_DATA_OBJECT_FIELD )
    {
    os << "DataObjectField\n";
    }
  else if ( this->OutputField == VTK_POINT_DATA_FIELD )
    {
    os << "PointDataField\n";
    }
  else //if ( this->OutputField == VTK_CELL_DATA_FIELD )
    {
    os << "CellDataField\n";
    }

}
