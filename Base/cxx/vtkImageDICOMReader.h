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
// .NAME vtkImageDICOMReader - Superclass of binary file readers.
// .SECTION Description
// vtkImageDICOMReader provides methods needed to read a region from a file.

// .SECTION See Also
// vtkBMPReader vtkPNMReader vtkTIFFReader

#ifndef __vtkImageDICOMReader_h
#define __vtkImageDICOMReader_h

//#include <iostream.h>
//#include <fstream.h>
#include "vtkImageData.h"
#include "vtkImageSource.h"
#include "vtkTransform.h"
#include "vtkSlicer.h"

#ifndef vtkFloatingPointType
#define vtkFloatingPointType float
#endif

#define VTK_FILE_BYTE_ORDER_BIG_ENDIAN 0
#define VTK_FILE_BYTE_ORDER_LITTLE_ENDIAN 1

class VTK_SLICER_BASE_EXPORT vtkImageDICOMReader : public vtkImageSource
{
public:
  static vtkImageDICOMReader *New();
  vtkTypeMacro(vtkImageDICOMReader,vtkImageSource);
  void PrintSelf(ostream& os, vtkIndent indent);   

  // Description:
  // Specify file name for the image file. You should specify either
  // a FileName or a FilePrefix. Use FilePrefix if the data is stored 
  // in multiple files.
  void SetFileName(char *);
  vtkGetStringMacro(FileName);

  // Description:
  // Specify file prefix for the image file(s).You should specify either
  // a FileName or FilePrefix. Use FilePrefix if the data is stored
  // in multiple files.
  void SetFilePrefix(char *);
  vtkGetStringMacro(FilePrefix);

  // Description:
  // The sprintf format used to build filename from FilePrefix and number.
  void SetFilePattern(char *);
  vtkGetStringMacro(FilePattern);

  // Description:
  // Set the data type of pixles in the file.  
  // As a convienience, the OutputScalarType is set to the same value.
  // If you want the output scalar type to have a different value, set it
  // after this method is called.
  void SetDataScalarType(int type);
  void SetDataScalarTypeToFloat(){this->SetDataScalarType(VTK_FLOAT);}
  void SetDataScalarTypeToDouble(){this->SetDataScalarType(VTK_DOUBLE);}
  void SetDataScalarTypeToInt(){this->SetDataScalarType(VTK_INT);}
  void SetDataScalarTypeToShort(){this->SetDataScalarType(VTK_SHORT);}
  void SetDataScalarTypeToUnsignedShort()
    {this->SetDataScalarType(VTK_UNSIGNED_SHORT);}
  void SetDataScalarTypeToUnsignedChar()
    {this->SetDataScalarType(VTK_UNSIGNED_CHAR);}

  // Description:
  // Get the file format.  Pixels are this type in the file.
  vtkGetMacro(DataScalarType, int);

  // Description:
  // Set/Get the number of scalar components
  vtkSetMacro(NumberOfScalarComponents,int);
  vtkGetMacro(NumberOfScalarComponents,int);
  
  // Description:
  // Get/Set the extent of the data on disk.  
  vtkSetVector6Macro(DataExtent,int);
  vtkGetVector6Macro(DataExtent,int);
  
  // Description:
  // Set/get the data VOI. You can limit the reader to only
  // read a subset of the data. 
  vtkSetVector6Macro(DataVOI,int);
  vtkGetVector6Macro(DataVOI,int);
  
  // Description:
  // The number of dimensions stored in a file. This defaults to two.
  vtkSetMacro(FileDimensionality, int);
  int GetFileDimensionality() {return this->FileDimensionality;}
  
  // Description:
  // Set/Get the spacing of the data in the file.
  vtkSetVector3Macro(DataSpacing,vtkFloatingPointType);
  vtkGetVector3Macro(DataSpacing,vtkFloatingPointType);
  
  // Description:
  // Set/Get the origin of the data (location of first pixel in the file).
  vtkSetVector3Macro(DataOrigin,vtkFloatingPointType);
  vtkGetVector3Macro(DataOrigin,vtkFloatingPointType);

  // Description:
  // Get the size of the header computed by this object.
  int GetHeaderSize();
  int GetHeaderSize(int slice);

  // Description:
  // If there is a tail on the file, you want to explicitly set the
  // header size.
  void SetHeaderSize(int size);
  
  // Description:
  // Set/Get the Data mask.
  vtkGetMacro(DataMask,unsigned short);
  void SetDataMask(int val) 
       {if (val == this->DataMask) { return; }
        this->DataMask = ((unsigned short)(val)); this->Modified();}
  
  // Description:
  // Set/Get transformation matrix to transform the data from slice space
  // into world space. This matirx must be a permutation matrix. To qualify,
  // the sums of the rows must be + or - 1.
  vtkSetObjectMacro(Transform,vtkTransform);
  vtkGetObjectMacro(Transform,vtkTransform);

  // Description:
  // These methods should be used instead of the SwapBytes methods.
  // They indicate the byte ordering of the file you are trying
  // to read in. These methods will then either swap or not swap
  // the bytes depending on the byte ordering of the machine it is
  // being run on. For example, reading in a BigEndian file on a
  // BigEndian machine will result in no swapping. Trying to read
  // the same file on a LittleEndian machine will result in swapping.
  // As a quick note most UNIX machines are BigEndian while PC's
  // and VAX tend to be LittleEndian. So if the file you are reading
  // in was generated on a VAX or PC, SetDataByteOrderToLittleEndian 
  // otherwise SetDataByteOrderToBigEndian. 
  void SetDataByteOrderToBigEndian();
  void SetDataByteOrderToLittleEndian();
  int GetDataByteOrder();
  void SetDataByteOrder(int);
  char *GetDataByteOrderAsString();

  // Description:
  // Set/Get the byte swapping to explicitely swap the bytes of a file.
  vtkSetMacro(SwapBytes,int);
  int GetSwapBytes() {return this->SwapBytes;}
  vtkBooleanMacro(SwapBytes,int);

//BTX
  ifstream *GetFile() {return this->File;}
  vtkGetVectorMacro(DataIncrements,unsigned long,4);
//ETX

  // Warning !!!
  // following should only be used by methods or template helpers, not users
  void ComputeInverseTransformedExtent(int inExtent[6],
                       int outExtent[6]);
  void ComputeInverseTransformedIncrements(int inIncr[3],
                       int outIncr[3]);

  void OpenFile();
  void OpenAndSeekFile(int extent[6], int slice);

  // Description:
  // Set/Get whether the data comes from the file starting in the lower left
  // corner or upper left corner.
  vtkBooleanMacro(FileLowerLeft, int);
  vtkGetMacro(FileLowerLeft, int);
  vtkSetMacro(FileLowerLeft, int);

  // Description:
  // Set/Get the internal file name
  void ComputeInternalFileName(int slice);
  vtkGetStringMacro(InternalFileName);
  
  int GetDICOMHeaderSize(int idx);
  void SetDICOMFileNames(int, char **, int, int *);
  void Start();
  
protected:
  vtkImageDICOMReader();
  ~vtkImageDICOMReader();
  vtkImageDICOMReader(const vtkImageDICOMReader&) {};
  void operator=(const vtkImageDICOMReader&) {};

  char *InternalFileName;
  char *FileName;
  char *FilePrefix;
  char *FilePattern;
  int NumberOfScalarComponents;
  int FileLowerLeft;

  ifstream *File;
  unsigned long DataIncrements[4];
  int DataExtent[6];
  unsigned short DataMask;  // Mask each pixel with ...
  int SwapBytes;

  int FileDimensionality;
  int HeaderSize;
  int DataScalarType;
  int ManualHeaderSize;
  int Initialized;
  vtkTransform *Transform;

  void ComputeTransformedSpacing (vtkFloatingPointType Spacing[3]);
  void ComputeTransformedOrigin (vtkFloatingPointType origin[3]);
  void ComputeTransformedExtent(int inExtent[6],
                int outExtent[6]);
  void ComputeTransformedIncrements(int inIncr[3],
                    int outIncr[3]);

  int DataDimensions[3];
  vtkFloatingPointType DataSpacing[3];
  vtkFloatingPointType DataOrigin[3];
  int DataVOI[6];
  
  int DICOMFiles;
  char **DICOMFileList;

  int DICOMMultiFrameOffsets;
  int *DICOMMultiFrameOffsetList;

  void ExecuteInformation();
  void Execute() { this->vtkImageSource::Execute(); };
  void Execute(vtkImageData *data);
  virtual void ComputeDataIncrements();
};

#endif
