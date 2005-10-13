/// .NAME vtkFSLookupTable - A look up table for FreeSurfer colour scales.
/// .SECTION Description
///
///

#ifndef __vtkFSLookupTable_h
#define __vtkFSLookupTable_h

#include <vtkFreeSurferReadersConfigure.h>
#include "vtkObject.h"
#include "vtkObjectFactory.h"
#include "vtkLookupTable.h"
#include "vtkScalarsToColors.h"
#include "vtkUnsignedShortArray.h"

/// Type constant, can have different types of colour scales
const int FSLUTHEAT = 1;
const int FSLUTBLUERED = 2;
const int FSLUTREDBLUE = 3;
const int FSLUTREDGREEN = 4;
const int FSLUTGREENRED = 5;

class VTK_FREESURFERREADERS_EXPORT vtkFSLookupTable : public vtkScalarsToColors
{
public:
    vtkTypeMacro(vtkFSLookupTable,vtkScalarsToColors);

    void PrintSelf(ostream& os, vtkIndent indent);

    static vtkFSLookupTable *New();

    vtkGetMacro(LowThresh,float);
    vtkSetMacro(LowThresh,float);

    vtkGetMacro(HiThresh,float);
    vtkSetMacro(HiThresh,float);

    vtkGetMacro(LutType,int);
    char *GetLutTypeString();
    void SetLutTypeToHeat();
    void SetLutTypeToBlueRed();
    void SetLutTypeToRedBlue();
    void SetLutTypeToRedGreen();
    void SetLutTypeToGreenRed();
        
    vtkGetMacro(Reverse,int);
    vtkSetMacro(Reverse,int);
    vtkBooleanMacro(Reverse,int);
    
    vtkGetMacro(Truncate,int);
    vtkSetMacro(Truncate,int);
    vtkBooleanMacro(Truncate,int);
    
    vtkGetMacro(Offset,float);
    vtkSetMacro(Offset,float);

    vtkGetMacro(Slope,float);
    vtkSetMacro(Slope,float);

    vtkGetMacro(Blufact,float);
    vtkSetMacro(Blufact,float);

    vtkGetMacro(FMid,float);
    vtkSetMacro(FMid,float);

    // from vtkScalarsToColors
    double *GetRange();
    void SetRange(double, double);
    unsigned char *MapValue(double);
    //BTX - begin tcl exclude
    void GetColor(double, double[3]);
    //ETX - end tcl exclude
    void MapScalarsThroughTable2(void*, unsigned char*, int, int, int, int);

    vtkGetMacro(NumberOfColors,int);
    vtkSetMacro(NumberOfColors,int);
    
protected:
    vtkFSLookupTable();
    ~vtkFSLookupTable();

    /// Low cut off, values passed in that are below this level are mapped to
    /// low cut off colour
    /// FS cmin and fthresh
    float LowThresh;
    /// High cut off, values passed in that are above this value are mapped to
    /// high cut off colour
    /// FS cmax
    float HiThresh;


    /// which type of colour scale this is supposed to model, from defined
    /// constants above
    int LutType;

    /// is the colour scale reversed?
    /// from FS invphaseflag
    int Reverse;

    /// truncate the values below zero?
    /// from FS truncphaseflag
    int Truncate;
    
    /// offset value added to the input value - a brightening factor
    float Offset;

    /// slope of the function that maps from input values to colours
    float Slope;

    /// blue factor?
    float Blufact;

    /// Midpoint of the function that maps from input values to colours
    /// FS fmid and cmid
    float FMid;

    /// Number of colours, from standard lut, not used
    int NumberOfColors;
};

#endif
    
