/*=auto=========================================================================

(c) Copyright 2004 Massachusetts Institute of Technology (MIT) All Rights Reserved.

This software ("3D Slicer") is provided by The Brigham and Women's 
Hospital << Inc. on behalf of the copyright holders and contributors.
Permission is hereby granted << without payment, to copy, modify, display 
and distribute this software and its documentation << if any, for  
research purposes only << provided that (1) the above copyright notice and 
the following four paragraphs appear on all copies of this software << and 
(2) that source code to any modifications to this software be made 
publicly available under terms no more restrictive than those in this 
License Agreement. Use of this software constitutes acceptance of these 
terms and conditions.

3D Slicer Software has not been reviewed or approved by the Food and 
Drug Administration << and is for non-clinical, IRB-approved Research Use 
Only.  In no event shall data or images generated through the use of 3D 
Slicer Software be used in the provision of patient care.

IN NO EVENT SHALL THE COPYRIGHT HOLDERS AND CONTRIBUTORS BE LIABLE TO 
ANY PARTY FOR DIRECT << INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL 
DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION << 
EVEN IF THE COPYRIGHT HOLDERS AND CONTRIBUTORS HAVE BEEN ADVISED OF THE 
POSSIBILITY OF SUCH DAMAGE.

THE COPYRIGHT HOLDERS AND CONTRIBUTORS SPECIFICALLY DISCLAIM ANY EXPRESS 
OR IMPLIED WARRANTIES INCLUDING << BUT NOT LIMITED TO, THE IMPLIED 
WARRANTIES OF MERCHANTABILITY << FITNESS FOR A PARTICULAR PURPOSE, AND 
NON-INFRINGEMENT.

THE SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS 
IS." THE COPYRIGHT HOLDERS AND CONTRIBUTORS HAVE NO OBLIGATION TO 
PROVIDE MAINTENANCE << SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.


=========================================================================auto=*/


#include "vtkObjectFactory.h"
#include "vtkAnalyzeHeaderExtractor.h"
#include <stdio.h> 
//#include <fstream.h>


vtkStandardNewMacro(vtkAnalyzeHeaderExtractor);


vtkAnalyzeHeaderExtractor::vtkAnalyzeHeaderExtractor()
{
    this->FileName = NULL;
    this->Swapped = 0;
}


vtkAnalyzeHeaderExtractor::~vtkAnalyzeHeaderExtractor()
{
    if (this->FileName)
    {
        delete [] this->FileName;
        this->FileName = NULL;
    }
}

// This function sets the name of the header file. 
void vtkAnalyzeHeaderExtractor::SetFileName(const char *name)
{
    if (this->FileName && name && 
        (!strcmp(this->FileName, name))) // this->FileName == name
    {
        return;
    }
    if (!name && !this->FileName)
    {
        return;
    }
    if (this->FileName)
    {
        delete [] this->FileName;
    }

    if (name)
    {
        this->FileName = new char[strlen(name)+1];
        strcpy(this->FileName, name);
    }
    else
    {
        this->FileName = NULL;
    }
}


void vtkAnalyzeHeaderExtractor::Read()
{
    if (!this->FileName)
    {
        cout << "Header file name is NULL." << endl;
    }
    else
    {
        ifstream myFile (this->FileName, ios::in | ios::binary);
        if (!myFile) {
            cout << "Can't open file: " << this->FileName << endl; 
        }
        else
        {
            if (!myFile.read ((char *)&this->Hdr, (int)sizeof(dsr)))
            {
                cout << "Error occurred in reading file: " << this->FileName << endl;
            }
            else
            {
                this->Swapped = 0;
                if (this->Hdr.dime.dim[0] < 0 || this->Hdr.dime.dim[0] > 15) 
                {
                    this->Swapped = 1;
                    SwapHeader(); 
                }

                this->DataType = this->Hdr.dime.datatype;
                this->BitsPix = this->Hdr.dime.bitpix;
                this->Orient = (int)this->Hdr.hist.orient;

                this->FileFormat = (this->Hdr.dime.dim[4] > 1 ? 4 : 3);
                for (int i = 0; i < 4; i++)
                {
                    this->ImageDim[i] = this->Hdr.dime.dim[i+1];
                }
                for (int i = 0; i < 3; i++)
                {
                    this->PixDim[i] = this->Hdr.dime.pixdim[i+1];
                }
                this->PixRange[0] = this->Hdr.dime.glmax;
                this->PixRange[1] = this->Hdr.dime.glmin;
            }
        }
    } 
}


int vtkAnalyzeHeaderExtractor::IsLittleEndian()
{
    int a = 1;
    char b = *((unsigned char*)&a);

    int c = 0;
    if ((b == 0 && this->Swapped == 1) ||
        (b == 1 && this->Swapped == 0))
    {
        c = 1;
    }

    return c;
}


void vtkAnalyzeHeaderExtractor::ShowHeader() 
{ 
    cout << "Analyze Header Dump of: " << this->FileName << endl; 
    
    // Header Key  
    cout << "sizeof_hdr: " << this->Hdr.hk.sizeof_hdr << endl; 
    cout << "data_type: " << this->Hdr.hk.data_type << endl; 
    cout << "db_name: " << this->Hdr.hk.db_name << endl; 
    cout << "extents: " << this->Hdr.hk.extents << endl; 
    cout << "session_error: " << this->Hdr.hk.session_error << endl; 
    cout << "regular: " << this->Hdr.hk.regular << endl; 
    cout << "hkey_un0: " << this->Hdr.hk.hkey_un0 << endl; 
    
    // Image Dimension  
    for (int i = 0; i < 8; i++) 
    {
        cout << "dim[" << i << "]: " << this->Hdr.dime.dim[i] << endl; 
    }
    cout << "vox_units: " << this->Hdr.dime.vox_units << endl; 
    cout << "cal_units: " << this->Hdr.dime.cal_units << endl; 
    cout << "unused1: " << this->Hdr.dime.unused1 << endl; 
    cout << "datatype: " << this->Hdr.dime.datatype << endl;
    cout << "bitpix: " << this->Hdr.dime.bitpix << endl; 
    
    for (int i = 0; i < 8;i++) 
    {
        cout << "pixdim[" << i << "]: " << this->Hdr.dime.pixdim[i] << endl; 
    }
    cout << "vox_offset: " << this->Hdr.dime.vox_offset << endl; 
    cout << "funused1: " << this->Hdr.dime.funused1 << endl; 
    cout << "funused2: " << this->Hdr.dime.funused2 << endl;  
    cout << "funused3: " << this->Hdr.dime.funused3 << endl;  
    cout << "cal_max: " << this->Hdr.dime.cal_max << endl;
    cout << "cal_min: " << this->Hdr.dime.cal_min << endl; 
    cout << "compressed: " << this->Hdr.dime.compressed << endl;
    cout << "verified: " << this->Hdr.dime.verified << endl;
    cout << "glmax: " << this->Hdr.dime.glmax << endl;
    cout << "glmin: " << this->Hdr.dime.glmin << endl;
    
    // Data History  
    cout << "descrip: " << this->Hdr.hist.descrip << endl;
    cout << "aux_file: " << this->Hdr.hist.aux_file << endl;
    cout << "orient: " << (int)this->Hdr.hist.orient << endl;
    cout << "originator: " << this->Hdr.hist.originator << endl;
    cout << "generated: " << this->Hdr.hist.generated << endl;
    cout << "scannum: " << this->Hdr.hist.scannum << endl;
    cout << "patient_id: " << this->Hdr.hist.patient_id << endl; 
    cout << "exp_date: " << this->Hdr.hist.exp_date << endl;
    cout << "exp_time: " << this->Hdr.hist.exp_time << endl;
    cout << "hist_un0: " << this->Hdr.hist.hist_un0 << endl; 
    cout << "views: " << this->Hdr.hist.views << endl;
    cout << "vols_added: " << this->Hdr.hist.vols_added << endl;
    cout << "start_field: " << this->Hdr.hist.start_field << endl;
    cout << "field_skip: " << this->Hdr.hist.field_skip << endl;
    cout << "omax: " << this->Hdr.hist.omax << endl;
    cout << "omin: " << this->Hdr.hist.omin << endl; 
    cout << "smin: " << this->Hdr.hist.smax << endl; 
    cout << "smin: " << this->Hdr.hist.smin << endl;
} 

void vtkAnalyzeHeaderExtractor::SwapHeader() 
{ 
    SwapLong((unsigned char*)&this->Hdr.hk.sizeof_hdr); 
    SwapLong((unsigned char*)&this->Hdr.hk.extents); 
    SwapShort((unsigned char*)&this->Hdr.hk.session_error); 
    SwapShort((unsigned char*)&this->Hdr.dime.dim[0]); 
    SwapShort((unsigned char*)&this->Hdr.dime.dim[1]); 
    SwapShort((unsigned char*)&this->Hdr.dime.dim[2]); 
    SwapShort((unsigned char*)&this->Hdr.dime.dim[3]); 
    SwapShort((unsigned char*)&this->Hdr.dime.dim[4]); 
    SwapShort((unsigned char*)&this->Hdr.dime.dim[5]); 
    SwapShort((unsigned char*)&this->Hdr.dime.dim[6]); 
    SwapShort((unsigned char*)&this->Hdr.dime.dim[7]); 
    SwapShort((unsigned char*)&this->Hdr.dime.unused1); 
    SwapShort((unsigned char*)&this->Hdr.dime.datatype); 
    SwapShort((unsigned char*)&this->Hdr.dime.bitpix); 
    SwapLong((unsigned char*)&this->Hdr.dime.pixdim[0]); 
    SwapLong((unsigned char*)&this->Hdr.dime.pixdim[1]); 
    SwapLong((unsigned char*)&this->Hdr.dime.pixdim[2]); 
    SwapLong((unsigned char*)&this->Hdr.dime.pixdim[3]); 
    SwapLong((unsigned char*)&this->Hdr.dime.pixdim[4]); 
    SwapLong((unsigned char*)&this->Hdr.dime.pixdim[5]); 
    SwapLong((unsigned char*)&this->Hdr.dime.pixdim[6]); 
    SwapLong((unsigned char*)&this->Hdr.dime.pixdim[7]); 
    SwapLong((unsigned char*)&this->Hdr.dime.vox_offset); 
    SwapLong((unsigned char*)&this->Hdr.dime.funused1); 
    SwapLong((unsigned char*)&this->Hdr.dime.funused2); 
    SwapLong((unsigned char*)&this->Hdr.dime.cal_max); 
    SwapLong((unsigned char*)&this->Hdr.dime.cal_min); 
    SwapLong((unsigned char*)&this->Hdr.dime.compressed); 
    SwapLong((unsigned char*)&this->Hdr.dime.verified); 
    SwapShort((unsigned char*)&this->Hdr.dime.dim_un0); 
    SwapLong((unsigned char*)&this->Hdr.dime.glmax); 
    SwapLong((unsigned char*)&this->Hdr.dime.glmin); 
} 


void vtkAnalyzeHeaderExtractor::SwapLong(unsigned char *pntr) 
{ 
    unsigned char b0, b1, b2, b3; 
    b0 = *pntr; 
    b1 = *(pntr+1); 
    b2 = *(pntr+2); 
    b3 = *(pntr+3); 
    *pntr = b3; 
    *(pntr+1) = b2; 
    *(pntr+2) = b1; 
    *(pntr+3) = b0; 
} 


void vtkAnalyzeHeaderExtractor::SwapShort(unsigned char *pntr) 
{ 
    unsigned char b0, b1; 
    b0 = *pntr; 
    b1 = *(pntr+1); 
    *pntr = b1; 
    *(pntr+1) = b0; 
}

