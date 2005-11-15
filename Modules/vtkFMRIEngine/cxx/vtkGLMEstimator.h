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
/*==============================================================================
(c) Copyright 2005 Massachusetts Institute of Technology (MIT) All Rights Reserved.

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
==============================================================================*/

#ifndef __vtkGLMEstimator_h
#define __vtkGLMEstimator_h


#include <vtkFMRIEngineConfigure.h>
#include "vtkActivationEstimator.h"
#include "vtkFloatArray.h"
#include "vtkShortArray.h"
#include "vtkDataObject.h"

class  VTK_FMRIENGINE_EXPORT vtkGLMEstimator : public vtkActivationEstimator
{
public:
    static vtkGLMEstimator *New();
    vtkTypeMacro(vtkGLMEstimator, vtkActivationEstimator);

    // Description:
    // Returns the time course of a specified voxel (i, j, k).
    vtkFloatArray *GetTimeCourse(int i, int j, int k);

    // Description:
    // Returns the time course of the defined ROI. 
    vtkFloatArray *GetRegionTimeCourse();

    // Description:
    // Sets the lower threshold.
    void SetLowerThreshold(float low) {this->LowerThreshold = low;}

    // Description:
    // Sets the cutoff frequency.
    void SetCutoff(float c) {this->Cutoff = c;}

    // Description:
    // Sets the indices of all voxels in the defined ROI.
    void SetRegionVoxels(vtkFloatArray *voxels) {this->RegionVoxels = voxels;}

    // Description:
    // Enables or disables high-pass filtering. 
    void EnableHighPassFiltering(int yes) {
        this->HighPassFiltering = yes;}

    // Description:
    // Gets HighPassFiltering.
    vtkGetMacro(HighPassFiltering, int);

protected:
    vtkGLMEstimator();
    ~vtkGLMEstimator();

    void SimpleExecute(vtkImageData* input,vtkImageData* output);
    void PerformHighPassFiltering();

    int HighPassFiltering;
    float LowerThreshold;
    float Cutoff;

    vtkFloatArray *TimeCourse;
    vtkFloatArray *RegionTimeCourse;
    vtkFloatArray *RegionVoxels;
};


#endif
