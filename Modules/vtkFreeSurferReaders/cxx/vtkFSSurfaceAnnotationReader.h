/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkFSSurfaceAnnotationReader.h,v $
  Date:      $Date: 2006/08/07 21:06:54 $
  Version:   $Revision: 1.6 $

=========================================================================auto=*/
// .NAME vtkFSSurfaceAnnotationReader - read a surface annotation and
// color table file from
// Freesurfer tools
// .SECTION Description

// Reads a surface annotation file from FreeSurfer and outputs a
// vtkIntArray and has an access function to get the vtkLookupTable
// with the color values. Use the SetFileName function to specify the
// file name. The number of values in the array should be equal to the
// number of vertices/points in the surface.

#ifndef __vtkFSSurfaceAnnotationReader_h
#define __vtkFSSurfaceAnnotationReader_h

#include <vtkFreeSurferReadersConfigure.h>
#include "vtkDataReader.h"
#include "vtkLookupTable.h"
#include "vtkPolyData.h"

// tag
const int FS_COLOR_TABLE_TAG = 1;

const int FS_COLOR_TABLE_NAME_LENGTH = 1024;
const int FS_COLOR_TABLE_ENTRY_NAME_LENGTH = 1024;

const int FS_ERROR_LOADING_COLOR_TABLE = 1;
const int FS_ERROR_LOADING_ANNOTATION = 2;
const int FS_ERROR_PARSING_COLOR_TABLE = 3;
const int FS_ERROR_PARSING_ANNOTATION = 4;
const int FS_WARNING_UNASSIGNED_LABELS = 5;
const int FS_NO_COLOR_TABLE = 6;

class VTK_FREESURFERREADERS_EXPORT vtkFSSurfaceAnnotationReader : public vtkDataReader
{
public:
  static vtkFSSurfaceAnnotationReader *New();
  vtkTypeMacro(vtkFSSurfaceAnnotationReader,vtkDataReader);
  void PrintSelf(ostream& os, vtkIndent indent);

  vtkIntArray *GetOutput()
    {return this->Labels; };
  void SetOutput(vtkIntArray *output)
    {this->Labels = output; };

  vtkLookupTable *GetColorTableOutput()
    {return this->Colors; };
  void SetColorTableOutput(vtkLookupTable* colors)
    {this->Colors = colors; };

  char* GetColorTableNames();

  int ReadFSAnnotation();
    int WriteFSAnnotation();
    
  void SetColorTableFileName (char*);

    // changed these to use vtk Get/Set macros
    //void DoUseExternalColorTableFile ();
    //void DontUseExternalColorTableFile ();
    vtkGetMacro(UseExternalColorTableFile,int);
    vtkSetMacro(UseExternalColorTableFile,int);
    vtkBooleanMacro(UseExternalColorTableFile,int);
    
protected:
  vtkFSSurfaceAnnotationReader();
  ~vtkFSSurfaceAnnotationReader();

  vtkIntArray    *Labels;
  vtkLookupTable *Colors;
  char           *NamesList;
  int            NumColorTableEntries;

    // bool UseExternalColorTableFile;
    int UseExternalColorTableFile;
  char ColorTableFileName[1024];

  // Read color table information from a source, allocate the arrays
  // to hold rgb and name values, and return pointers to the
  // arrays. The caller is responsible for disposing of the memory.
  int ReadEmbeddedColorTable (FILE* annotFile, int* numEntries, 
                  int*** rgbValues, char*** names);
  int ReadExternalColorTable (char* fileName, int* numEntries, 
                  int*** rgbValues, char*** names);
  

private:
  vtkFSSurfaceAnnotationReader(const vtkFSSurfaceAnnotationReader&);  // Not implemented.
  void operator=(const vtkFSSurfaceAnnotationReader&);  // Not implemented.
};


#endif
