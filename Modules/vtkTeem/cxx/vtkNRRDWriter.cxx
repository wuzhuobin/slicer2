
#include "vtkNRRDWriter.h"


#include "vtkImageData.h"
#include "vtkPointData.h"
#include "vtkObjectFactory.h"
#include "vtkDataArray.h"
#include "teem/nrrd.h"


vtkCxxRevisionMacro(vtkNRRDWriter, "$Revision: 1.1.2.1 $");
vtkStandardNewMacro(vtkNRRDWriter);

//----------------------------------------------------------------------------
vtkNRRDWriter::vtkNRRDWriter()
{
  this->FileName = NULL;
  this->BValues = vtkDoubleArray::New();
  this->DiffusionGradients = vtkDoubleArray::New();
  this->IJKToRASMatrix = vtkMatrix4x4::New();
  this->MeasurementFrameMatrix = vtkMatrix4x4::New();
  this->UseCompression = 1;
  this->FileType = VTK_BINARY;
}

//----------------------------------------------------------------------------
vtkNRRDWriter::~vtkNRRDWriter()
{
  if ( this->FileName )
    {
    delete [] this->FileName;
    }

  if (this->DiffusionGradients)
    {
    this->DiffusionGradients->Delete();
    }
  if (this->BValues)
    {
    this->BValues->Delete();
    }
  if (this->IJKToRASMatrix)
    {
    this->IJKToRASMatrix->Delete();
    }
  if (this->MeasurementFrameMatrix)
    {
    this->MeasurementFrameMatrix->Delete();
    }      
}

//----------------------------------------------------------------------------
// Specify the input data or filter.
void vtkNRRDWriter::SetInput(vtkImageData *input)
{
  this->vtkProcessObject::SetNthInput(0, input);
}

//----------------------------------------------------------------------------
vtkImageData* vtkNRRDWriter::GetInput()
{
  return vtkImageData::SafeDownCast(this->Superclass::GetInput());
}

//----------------------------------------------------------------------------
//vtkImageData* vtkNRRDWriter::GetInput(int port)
//{
//  return vtkImageData::SafeDownCast(this->Superclass::GetInput(port));
//}

//----------------------------------------------------------------------------
//int vtkNRRDWriter::FillInputPortInformation(
//  int port, vtkInformation *info)
//{
//  info->Set(vtkAlgorithm::INPUT_REQUIRED_DATA_TYPE(), "vtkImageData");
//  return 1;

//}

//----------------------------------------------------------------------------
// Writes all the data from the input.
void vtkNRRDWriter::vtkImageDataInfoToNrrdInfo(vtkImageData *in, int &nrrdKind, size_t &numComp, int &vtkType, void *buffer)
{

  vtkDataArray *array;
  if ((array = static_cast<vtkDataArray *> (in->GetPointData()->GetScalars())))
    {
    numComp = array->GetNumberOfComponents();
    vtkType = array->GetDataType();
    buffer = array->GetVoidPointer(0);
    
    switch (numComp)
      {
      case 1:
        nrrdKind = nrrdKindScalar;
        break;
      case 2:
        nrrdKind = nrrdKindComplex;
        break;
      case 3:
        nrrdKind = nrrdKindRGBColor;
        break;
      case 4:
        nrrdKind = nrrdKindRGBAColor;
        break;
      default:
        int numGrad = this->DiffusionGradients->GetNumberOfTuples();
        int numBValues = this->BValues->GetNumberOfTuples();
        if (numGrad == numBValues && numGrad == numComp)
          {
          nrrdKind = nrrdKindList;
          }
        else
          {
          nrrdKind = nrrdKindList;
          }
       }
     }
   else if ((array = static_cast<vtkDataArray *> ( in->GetPointData()->GetVectors())))
     {
     buffer = array->GetVoidPointer(0);
     vtkType = array->GetDataType();
     nrrdKind = nrrdKindVector;
     }
   else if ((array = static_cast<vtkDataArray *> ( in->GetPointData()->GetNormals())))
     {
     buffer = array->GetVoidPointer(0);
     vtkType = array->GetDataType();
     nrrdKind = nrrdKindVector;
     numComp = array->GetNumberOfComponents();
     }
   else if ((array = static_cast<vtkDataArray *> ( in->GetPointData()->GetTensors())))
     {
     buffer = array->GetVoidPointer(0);
     vtkType = array->GetDataType();
     nrrdKind = nrrdKind3DMatrix;
     numComp = array->GetNumberOfComponents();
     }       
} 

int vtkNRRDWriter::VTKToNrrdPixelType( const int vtkPixelType )
  {
  switch( vtkPixelType )
    {
    default:
    case VTK_VOID:
      return nrrdTypeDefault;
      break;
    case VTK_CHAR:
      return nrrdTypeChar;
      break;
    case VTK_UNSIGNED_CHAR:
      return nrrdTypeUChar;
      break;
    case VTK_SHORT:
      return nrrdTypeShort;
      break;
    case VTK_UNSIGNED_SHORT:
      return nrrdTypeUShort;
      break;
      //    case nrrdTypeLLong:
      //      return LONG ;
      //      break;
      //    case nrrdTypeULong:
      //      return ULONG;
      //      break;
    case VTK_INT:
      return nrrdTypeInt;
      break;
    case VTK_UNSIGNED_INT:
      return nrrdTypeUInt;
      break;
    case VTK_FLOAT:
      return nrrdTypeFloat;
      break;
    case VTK_DOUBLE:
      return nrrdTypeDouble;
      break;
    }
  }



//----------------------------------------------------------------------------
// Writes all the data from the input.
void vtkNRRDWriter::WriteData()
{

  if (this->GetFileName() == NULL)
    {
    vtkErrorMacro("FileName has not been set. Cannot save file");
    return;
    } 

  Nrrd *nrrd = nrrdNew();
  NrrdIoState *nio = nrrdIoStateNew();
  int kind[NRRD_DIM_MAX];
  size_t size[NRRD_DIM_MAX];
  unsigned int nrrdDim, baseDim, spaceDim;
  double spaceDir[NRRD_DIM_MAX][NRRD_SPACE_DIM_MAX];
  double origin[NRRD_DIM_MAX];
  void *buffer;
  int vtkType;
  
  cout<<"Updating Input Information"<<endl;
    // Fill in image information.
  this->GetInput()->UpdateInformation();
  
  // Find Pixel type from data and select a buffer.
  cout<<"Getting ImageDataInfo to NrrdInfo"<<endl;
  this->vtkImageDataInfoToNrrdInfo(this->GetInput(),kind[0],size[0],vtkType, buffer); 

  cout<<"Retreive info: "<<endl;
  cout<<"Kind: "<<kind[0]<<endl;
  cout<<"Size: "<<size[0]<<endl;
  cout<<"vtkType: "<<vtkType<<endl;
  cout<<"Buffer pointer: "<<buffer<<endl;

  cout<<"Setting axis depedent info"<<endl;
  spaceDim = 3; // VTK is always 3D volumes.
  if (size[0] > 1)
    {
    // the range axis has no space direction
    for (unsigned int saxi=0; saxi < spaceDim; saxi++)
      {
      spaceDir[0][saxi] = AIR_NAN;
      }
    baseDim = 1;
    }
  else
    {
    baseDim = 0;
    }
  nrrdDim = baseDim + spaceDim;

  unsigned int axi;
  for (axi=0; axi < spaceDim; axi++)
    {
    size[axi+baseDim] = this->GetInput()->GetDimensions()[axi];
    kind[axi+baseDim] = nrrdKindDomain;
    origin[axi] = this->IJKToRASMatrix->GetElement((int) axi,3);
    double spacing = this->GetInput()->GetSpacing()[axi];
    for (unsigned int saxi=0; saxi < spaceDim; saxi++)
      {
      spaceDir[axi+baseDim][saxi] = this->IJKToRASMatrix->GetElement(axi,saxi);
      }
    }
  cout<<"Before wrapping buffer"<<endl;
  if (nrrdWrap_nva(nrrd, const_cast<void *>(buffer),
                   this->VTKToNrrdPixelType( vtkType ),
                   nrrdDim, size)
      || nrrdSpaceDimensionSet(nrrd, spaceDim)
      || nrrdSpaceOriginSet(nrrd, origin))
    {
    char *err = biffGetDone(NRRD); // would be nice to free(err)
    vtkErrorMacro("Write: Error wrapping nrrd for " 
                      << this->GetFileName() << ":\n" << err);
    // Free the nrrd struct but don't touch nrrd->data
    nrrd = nrrdNix(nrrd);
    nio = nrrdIoStateNix(nio);
    return; 
    }
  cout<<"Setting axis info"<<endl;
  nrrdAxisInfoSet_nva(nrrd, nrrdAxisInfoKind, kind);
  nrrdAxisInfoSet_nva(nrrd, nrrdAxisInfoSpaceDirection, spaceDir);

  cout<<"Size: "<<size[0]<<" "<<size[1]<<" "<<size[2]<<" "<<size[3]<<endl;
  cout<<"vtk Type: "<<vtkType<<" Nrrd Type: "<<this->VTKToNrrdPixelType( vtkType )<<endl;

  // Go through MetaDataDictionary and set either specific nrrd field
  // or a key/value pair
  // We basically care about finding if we have diffusion information
  // and measurement frame information

  // 1. Measurement Frame
  cout<<"Set Measurement Frame"<<endl;
  if (this->MeasurementFrameMatrix)
    {
    for (unsigned int saxi=0; saxi < nrrd->spaceDim; saxi++)
      {
      for (unsigned int saxj=0; saxj < nrrd->spaceDim; saxj++)
        {
        nrrd->measurementFrame[saxi][saxj] = this->MeasurementFrameMatrix->GetElement(saxi,saxj);
        }
      }
    }

   cout<<"Set Diffusion Data"<<endl;
  // 2. Take care about diffusion data
  if (this->DiffusionGradients && this->BValues)
    {
    int numGrad = this->DiffusionGradients->GetNumberOfTuples();
    int numBValues = this->BValues->GetNumberOfTuples();

    if (kind[0] == nrrdKindList && numGrad == size[0] && numBValues == size[0])
      {
      // This is diffusion Data
      double *grad;
      double bVal,factor;
      double maxbVal = this->BValues->GetRange()[1];
      char value[1024];
      char key[1024];
      strcpy(key,"modality");
      strcpy(value,"DWMRI");
      nrrdKeyValueAdd(nrrd, key, value);

      strcpy(key,"DWMRI_b-value");
      sprintf(value,"%f",maxbVal,1024);
      nrrdKeyValueAdd(nrrd,key, value);
      for (unsigned int ig =0; ig< numGrad; ig++)
        {
        grad=this->DiffusionGradients->GetTuple3(ig);
        bVal = this->BValues->GetValue(ig);
        factor = bVal/maxbVal;
        sprintf(key,"%s%04d","DWMRI_gradient_",ig);
        sprintf(value,"%f %f %f",grad[0]*factor, grad[1]*factor, grad[2]*factor);
        cout<<" Key: "<<key<<" Value: "<<value<<endl;
        nrrdKeyValueAdd(nrrd,key, value);
        }
     }
  }

  // set encoding for data: compressed (raw), (uncompressed) raw, or ascii
  if (this->GetUseCompression() == true
      && nrrdEncodingGzip->available())
    {
    // this is necessarily gzip-compressed *raw* data
    nio->encoding = nrrdEncodingGzip;
    }
  else
    {
    int fileType = this->GetFileType();
    switch ( fileType )
      {
      default:
      case VTK_BINARY:
        nio->encoding = nrrdEncodingRaw;
        break;
      case VTK_ASCII:
        nio->encoding = nrrdEncodingAscii;
        break;
      }
    }

  // set endianness as unknown of output
  nio->endian = airEndianUnknown;
  nio->endian = airEndianBig;

  cout<<"Write NRRD dataset"<<endl;
  // Write the nrrd to file.
  if (nrrdSave(this->GetFileName(), nrrd, nio))
    {
    char *err = biffGetDone(NRRD); // would be nice to free(err)
    vtkErrorMacro("Write: Error writing " 
                      << this->GetFileName() << ":\n" << err);                  
    }
  // Free the nrrd struct but don't touch nrrd->data
  cout<<"Freeing nrrd data"<<endl;
  nrrd = nrrdNix(nrrd);
  nio = nrrdIoStateNix(nio);

}

void vtkNRRDWriter::PrintSelf(ostream& os, vtkIndent indent)
{
  this->Superclass::PrintSelf(os,indent);

  os << indent << "RAS to IJK Matrix: ";
     this->IJKToRASMatrix->PrintSelf(os,indent);
  os << indent << "Measurement frame: ";
     this->MeasurementFrameMatrix->PrintSelf(os,indent);
}