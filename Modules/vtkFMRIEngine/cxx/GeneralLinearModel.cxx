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
(c) Copyright 2004 Massachusetts Institute of Technology (MIT) All Rights Reserved.

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


#include "GeneralLinearModel.h"
#include <stdio.h>
#include <math.h>

gsl_matrix *GeneralLinearModel::X = NULL;
gsl_matrix *GeneralLinearModel::cov = NULL;
gsl_vector *GeneralLinearModel::y = NULL;
gsl_vector *GeneralLinearModel::c = NULL;
gsl_multifit_linear_workspace *GeneralLinearModel::work = NULL;

int *GeneralLinearModel::Dimensions = NULL;
float **GeneralLinearModel::DesignMatrix = NULL;


int GeneralLinearModel::FitModel(float *timeCourse,
                                 float *beta,
                                 float *chisq)
{
    int i, j;
    double xi, yi, ssr, t;

    if (DesignMatrix == NULL || Dimensions == NULL) 
    {
        cout << "Design matix has not been set.\n";
        return 1;
    }

    if (X == NULL)
    {
        X = gsl_matrix_alloc(Dimensions[0], Dimensions[1]);
    }
    if (y == NULL) 
    {
        y = gsl_vector_alloc(Dimensions[0]);
    }
    if (c == NULL)
    {
        c = gsl_vector_alloc(Dimensions[1]);
    }
    if (cov == NULL)
    {
        cov = gsl_matrix_alloc(Dimensions[1], Dimensions[1]);
    }

    for (i = 0; i < Dimensions[0]; i++)
    {
        gsl_vector_set(y, i, timeCourse[i]);

        for(j = 0; j < Dimensions[1]; j++)
        {
            gsl_matrix_set(X, i, j, DesignMatrix[i][j]);
        }
    }

    if (work == NULL)
    {
        work = gsl_multifit_linear_alloc(Dimensions[0], Dimensions[1]);
    }

    gsl_multifit_linear(X, y, c, cov, &ssr, work);
    *chisq = (float) ssr;
    for(j = 0; j < Dimensions[1]; j++)
    {
        beta[j] = gsl_vector_get(c,j);
    }

    return 0;
}


int GeneralLinearModel::SetDesignMatrix(vtkFloatArray *designMat)
{
    int noOfRegressors = designMat->GetNumberOfComponents();

    if (Dimensions == NULL)
    {
        Dimensions = new int[2];
        if (Dimensions == NULL) 
        {
            cout << "Memory allocation failed for Dimensions in class GeneralLinearModel.\n";
            return 1;
        }
    }  

    // Number of volumes
    Dimensions[0] = designMat->GetNumberOfTuples();
    // Number of evs (predictors)
    Dimensions[1] = noOfRegressors;

    if (DesignMatrix == NULL)
    {
        DesignMatrix = new float *[Dimensions[0]];
        if (DesignMatrix == NULL) 
        {
            cout << "Memory allocation failed for DesignMatrix in class GeneralLinearModel.\n";
            return 1;
        }

        for (int i = 0; i < Dimensions[0]; i++)
        {
            DesignMatrix[i] = new float[Dimensions[1]];
            for (int j = 0; j < Dimensions[1]; j++)
            {
                DesignMatrix[i][j] = designMat->GetComponent(i,j);
            }
        } 
    }

    return 0;
}


void GeneralLinearModel::Free()
{
    gsl_matrix_free(X);
    gsl_matrix_free(cov);
    gsl_vector_free(y);
    gsl_vector_free(c);
    gsl_multifit_linear_free(work);

    X = NULL;
    cov = NULL;
    y = NULL;
    c = NULL;
    work = NULL;

    if (DesignMatrix != NULL)
    {
        for (int i = 0; i < Dimensions[0]; i++)
        {
            delete [] DesignMatrix[i];
        } 
        delete [] DesignMatrix;
        DesignMatrix = NULL;
        
    }
    if (Dimensions != NULL)
    {
        delete [] Dimensions;
        Dimensions = NULL;
    }
}


