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
/*=========================================================================
 
  Library   : vtk/objects/library/CISGImage
  Module    : $RCSfile: vtkCISGCofstream.cxx,v $
  Authors   : Thomas Hartkens <thomas@hartkens.de>
              Daniel Rueckert <d.rueckert@doc.ic.ac.uk>
              Julia Schnabel  <julia.schnabel@kcl.ac.uk>
              under the supervision of Dave Hawkes and Derek Hill
  Web       : http://www.image-registration.com
  Copyright : King's College London
              Div. of Radiological Sciences, 
              Computational Imaging Science Group, 1997 - 2000
              http://www-ipg.umds.ac.uk/cisg
  Date      : $Date: 2005/04/19 14:48:25 $
  Version   : $Revision: 1.3 $

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
=========================================================================*/

#include "vtkCISGCofstream.h"


#define SIZEOF_CHAR    1
#define SIZEOF_UCHAR   1
#define SIZEOF_SHORT   2
#define SIZEOF_USHORT  2
#define SIZEOF_INT     4
#define SIZEOF_UINT    4
#define SIZEOF_FLOAT   4
#define SIZEOF_DOUBLE  8

void vtkCISGCofstream::Open(char *filename)
{
  this->open(filename,ios::out|ios::binary);

  // Check whether file was opened successful
  if (this->is_open() != True){
    cerr << "vtkCISGCofstream::Open: Can't open file " << filename << endl;
    //vtkErrorMacro(<< "vtkCISGCcofstream::Open: Can't open file " << filename << endl);
    return;
    //exit(1);
  }

  _swapped = swapping();

}

int vtkCISGCofstream::Write(char *data, int offset, int length)
{
  this->seekp(offset, ios::beg);
  this->write(data, length);
  return length;
}

int vtkCISGCofstream::WriteAsChar(char data, int offset)
{
  return this->Write((char *)&data, offset, SIZEOF_CHAR);
}

int vtkCISGCofstream::WriteAsChar(char *data, int length, int offset)
{
  return this->Write((char *)data, offset, length*SIZEOF_CHAR);
}

int vtkCISGCofstream::WriteAsUChar(unsigned char data, int offset)
{
  return this->Write((char *)&data, offset, SIZEOF_UCHAR);
}

int vtkCISGCofstream::WriteAsUChar(unsigned char *data, int length, int offset)
{
  return this->Write((char *)data, offset, length*SIZEOF_UCHAR);
}

int vtkCISGCofstream::WriteAsShort(short data, int offset)
{
  // Swap data
  swap16((char *)&data, (char *)&data, 1);

  return this->Write((char *)&data, offset, SIZEOF_SHORT);
}

int vtkCISGCofstream::WriteAsShort(short *data, int length, int offset)
{
  // Swap data
  swap16((char *)data, (char *)data, length);

  int l=this->Write((char *)data, offset, length*SIZEOF_SHORT);

  // Swap data (BACK)
  swap16((char *)data, (char *)data, length);
  return l;
}

int vtkCISGCofstream::WriteAsUShort(unsigned short data, int offset)
{
  // Swap data
  swap16((char *)&data, (char *)&data, 1);

  return this->Write((char *)&data, offset, SIZEOF_USHORT);
}

int vtkCISGCofstream::WriteAsUShort(unsigned short *data, int length, int offset)
{
  // Swap data
  swap16((char *)data, (char *)data, length);

  int l=this->Write((char *)data, offset, length*SIZEOF_USHORT);

  // Swap data (BACK)
  swap16((char *)data, (char *)data, length);
  return l;
}

int vtkCISGCofstream::WriteAsInt(int data, int offset)
{
  // Swap data
  swap32((char *)&data, (char *)&data, 1);

  return this->Write((char *)&data, offset, SIZEOF_INT);
}

int vtkCISGCofstream::WriteAsInt(int *data, int length, int offset)
{
  // Swap data
  swap32((char *)data, (char *)data, length);

  int l=this->Write((char *)data, offset, length*SIZEOF_INT);

  // Swap data (BACK)
  swap32((char *)data, (char *)data, length);
  return l;
}

int vtkCISGCofstream::WriteAsUInt(unsigned int data, int offset)
{
  // Swap data
  swap32((char *)&data, (char *)&data, 1);

  return this->Write((char *)&data, offset, SIZEOF_UINT);
}

int vtkCISGCofstream::WriteAsUInt(unsigned int *data, int length, int offset)
{
  // Swap data
  swap32((char *)data, (char *)data, length);

  int l=this->Write((char *)data, offset, length*SIZEOF_UINT);

  // Swap data (BACK)
  swap32((char *)data, (char *)data, length);
  return l;
}

int vtkCISGCofstream::WriteAsFloat(float data, int offset)
{
  // Swap data
  swap32((char *)&data, (char *)&data, 1);

  return this->Write((char *)&data, offset, SIZEOF_FLOAT);
}

int vtkCISGCofstream::WriteAsFloat(float *data, int length, int offset)
{
  // Swap data
  swap32((char *)data, (char *)data, length);

  int l=this->Write((char *)data, offset, length*SIZEOF_FLOAT);

  // Swap data (BACK)
  swap32((char *)data, (char *)data, length);
  return l;
}

int vtkCISGCofstream::WriteAsDouble(double *data, int length, int offset)
{
  // Swap data
  swap64((char *)data, (char *)data, length);

  int l=this->Write((char *)data, offset, length*SIZEOF_DOUBLE);

  // Swap data (BACK)
  swap64((char *)data, (char *)data, length);
  return l;
}

int vtkCISGCofstream::WriteAsDouble(double data, int offset)
{
  // Swap data
  swap64((char *)&data, (char *)&data, 1);

  return this->Write((char *)&data, offset, SIZEOF_DOUBLE);
}






int vtkCISGCofstream::swapping() {

  short byte_order_test;
  char  *byte1, *byte2;
  byte_order_test = 256;
  byte1 = (char*)&byte_order_test;
  byte2 = byte1 + 1;
  if(*byte1 > *byte2) return 0 ;
  else return 1;
}


void vtkCISGCofstream::swap16(char *a, char *b, int n)
{
  int i;
  char c;

  if (_swapped) {
    for (i = 0; i < n * 2; i += 2){
      c = a[i];
      a[i] = b[i+1];
      b[i+1] = c;
    }
  }
}

void vtkCISGCofstream::swap32(char *a, char *b, int n)
{
  int i;
  char c;

  if (_swapped) {
    for (i = 0; i < n * 4; i += 4){
      c = a[i];
      a[i] = b[i+3];
      b[i+3] = c;
      c = a[i+1];
      a[i+1] = b[i+2];
      b[i+2] = c;
    }
  }
}

void vtkCISGCofstream::swap64(char *a, char *b, int n)
{
  int i;
  char c;

  if (_swapped) {
    for (i = 0; i < n * 8; i += 8){
      c = a[i];
      a[i] = b[i+7];
      b[i+7] = c;
      c = a[i+1];
      a[i+1] = b[i+6];
      b[i+6] = c;
      c = a[i+2];
      a[i+2] = b[i+5];
      b[i+5] = c;
      c = a[i+3];
      a[i+3] = b[i+5];
      b[i+5] = c;
    }
  }
}



