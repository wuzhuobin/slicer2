/*=auto=========================================================================

(c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

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

#include "GeneralLinearModel.h"
#include "vtkGLMEstimator.h"
#include "vtkObjectFactory.h"
#include "vtkImageData.h"
#include "vtkPointData.h"
#include "vtkCommand.h"
#include "vtkImageFFT.h"
#include "vtkImageRFFT.h"
#include "vtkImageIdealHighPass.h"
#include "vtkImageAppend.h"
#include "vtkImageAccumulate.h"
#include "vtkImageExtractComponents.h"
#include "vtkExtractVOI.h"
#include "vtkImageViewer.h"
#include "vtkGLMDetector.h"



vtkStandardNewMacro(vtkGLMEstimator);


vtkGLMEstimator::vtkGLMEstimator()
{
    this->Cutoff = 0.0;
    this->LowerThreshold = 0.0;
    this->HighPassFiltering = 0;
    this->GrandMean = 0.0;
    this->GlobalEffect = 0;

    this->GlobalMeans = NULL;
    this->Detector = NULL; 
    this->TimeCourse = NULL; 
    this->RegionTimeCourse = NULL;
    this->RegionVoxels = NULL;
}


vtkGLMEstimator::~vtkGLMEstimator()
{
    if (this->TimeCourse != NULL)
    {
        this->TimeCourse->Delete();
    }
    if (this->RegionTimeCourse != NULL)
    {
        this->RegionTimeCourse->Delete();
    }
    if (this->RegionVoxels != NULL)
    {
        this->RegionVoxels->Delete();
    }
}


vtkFloatArray *vtkGLMEstimator::GetRegionTimeCourse()
{
    // Checks the input list
    if (this->NumberOfInputs == 0 || this->GetInput(0) == NULL)
    {
        vtkErrorMacro( <<"No input image data in this filter.");
        return NULL;
    }

    if (this->RegionVoxels == NULL)
    {
        vtkErrorMacro( <<"Indices of all voxels in the ROI is required.");
        return NULL;
    }

    if (this->RegionTimeCourse != NULL) 
    {
        this->RegionTimeCourse->Delete();
    }
    this->RegionTimeCourse = vtkFloatArray::New();
    this->RegionTimeCourse->SetNumberOfTuples(this->NumberOfInputs);
    this->RegionTimeCourse->SetNumberOfComponents(1);

    short *val;
    int size = this->RegionVoxels->GetNumberOfTuples();

    for (int ii = 0; ii < this->NumberOfInputs; ii++)
    {
        int total = 0;
        for (int jj = 0; jj < size; jj++)
        {
            short x = (short)this->RegionVoxels->GetComponent(jj, 0);
            short y = (short)this->RegionVoxels->GetComponent(jj, 1);
            short z = (short)this->RegionVoxels->GetComponent(jj, 2);

            val = (short *)this->GetInput(ii)->GetScalarPointer(x, y, z); 
            total += *val;
        }

        this->RegionTimeCourse->SetComponent(ii, 0, (short)(total/size)); 
    }

    return this->RegionTimeCourse;
}


vtkFloatArray *vtkGLMEstimator::GetTimeCourse(int i, int j, int k)
{
    // Checks the input list
    if (this->NumberOfInputs == 0 || this->GetInput(0) == NULL)
    {
        vtkErrorMacro( <<"No input image data in this filter.");
        return NULL;
    }

    if (this->TimeCourse != NULL) 
    {
        this->TimeCourse->Delete();
    }
    this->TimeCourse = vtkFloatArray::New();
    this->TimeCourse->SetNumberOfTuples(this->NumberOfInputs);
    this->TimeCourse->SetNumberOfComponents(1);

    short *val;
    for (int ii = 0; ii < this->NumberOfInputs; ii++)
    {
        val = (short *)this->GetInput(ii)->GetScalarPointer(i, j, k); 
        this->TimeCourse->SetComponent(ii, 0, *val); 
    }

    // Execute high-pass filter on the timecourse
    if (this->HighPassFiltering) 
    {
        this->PerformHighPassFiltering();
    }

    return this->TimeCourse;
}


void vtkGLMEstimator::PerformHighPassFiltering()
{
    // We are going to perform high pass filtering on the time course 
    // of a specific voxel. First, we convert the time course from
    // a vtkFloatArray to vtkImageData.
    vtkImageData *img = vtkImageData::New();
    img->GetPointData()->SetScalars(this->TimeCourse);
    img->SetDimensions(this->NumberOfInputs, 1, 1);
    img->SetScalarType(VTK_FLOAT);
    img->SetSpacing(1.0, 1.0, 1.0);
    img->SetOrigin(0.0, 0.0, 0.0);

    // FFT on the vtkImageData
    vtkImageFFT *fft = vtkImageFFT::New();
    fft->SetInput(img); 

    // Cut frequency on the vtkImageData on frequence domain
    vtkImageIdealHighPass *highPass = vtkImageIdealHighPass::New();
    highPass->SetInput(fft->GetOutput());
    highPass->SetXCutOff(this->Cutoff);         
    highPass->SetYCutOff(this->Cutoff); 
    highPass->ReleaseDataFlagOff();

    // RFFT on the vtkImageData following frequency cutoff
    vtkImageRFFT *rfft = vtkImageRFFT::New();
    rfft->SetInput(highPass->GetOutput());

    // The vtkImageData now holds two components: real and imaginary.
    // The real component is the image (time course) we want to plot
    vtkImageExtractComponents *real = vtkImageExtractComponents::New();
    real->SetInput(rfft->GetOutput());
    real->SetComponents(0);
    real->Update();

    // Update the vtkFloatArray of the time course
    vtkDataArray *arr = real->GetOutput()->GetPointData()->GetScalars();
    for (int i = 0; i < this->NumberOfInputs; i++) 
    {
        float x = (float) arr->GetComponent(i, 0);
        this->TimeCourse->SetComponent(i, 0, x);
    }

    // Clean up
    highPass->Delete();
    real->Delete();
    rfft->Delete();
    fft->Delete();
    img->Delete();
}


void vtkGLMEstimator::ComputeMeans()
{
    if (this->GlobalMeans != NULL)
    {
        delete [] this->GlobalMeans;
    }
    this->GlobalMeans = new float [this->NumberOfInputs];

    // this class is for single volume stats; here we use
    // it to get voxel intensity mean for the entire volume.
    vtkImageAccumulate *ia = vtkImageAccumulate::New();

    // all voxels in the same bin
    ia->SetComponentExtent(0, 0, 0, 0, 0, 0);

    ia->SetComponentOrigin(0.0, 0.0, 0.0);
    ia->SetComponentSpacing(1.0, 1.0, 1.0);

    int imgDim[3];  
    this->GetInput(0)->GetDimensions(imgDim);
    int dim = imgDim[0] * imgDim[1] * imgDim[2];
    float gt = 0.0;
    
    // for progress update (bar)
    unsigned long count = 0;
    unsigned long target = (unsigned long)(this->NumberOfInputs * dim / 100.0);
    target++;

    for (int i = 0; i < this->NumberOfInputs; i++)
    {
        // get original mean for each volume
        ia->SetInput(this->GetInput(i));
        ia->Update();
        double *means = ia->GetMean();
        // 4.0 is arbitray. I did experiment on 1, 2, 4, 6, 8 and 10.
        // 4 seems the best with my 45-volume test data set.
        this->GlobalMeans[i] = (float) (means[0] / 4.0);

        // get new mean for each volume
        double total = 0.0;
        short *ptr = (short *) this->GetInput(i)->GetScalarPointer();
        int count2 = 0;
        for (int ii = 0; ii < dim; ii++)
        {
            if (ptr[ii] >= this->GlobalMeans[i])
            {
                total += ptr[ii];
                count2++;
            }

            // status bar update
            if (!(count%target))
            {
                UpdateProgress(count / (100.0*target));
            }
            count++;
        }
        this->GlobalMeans[i] = (float) (total / count2);
        gt += this->GlobalMeans[i];
    }
    ia->Delete();

    // grand mean
    this->GrandMean = gt / this->NumberOfInputs;
}
 

void vtkGLMEstimator::SimpleExecute(vtkImageData *inputs, vtkImageData* output)
{
    if (this->NumberOfInputs == 0 || this->GetInput(0) == NULL)
    {
        vtkErrorMacro( << "No input image data in this filter.");
        return;
    }

    // compute global means and grand mean for the sequence
    if (this->GlobalEffect > 0)
    {
        ComputeMeans();
    }

    // Sets up properties for output vtkImageData
    int noOfRegressors = ((vtkGLMDetector *)this->Detector)->GetDesignMatrix()->GetNumberOfComponents();
    int imgDim[3];  
    int vox;
        
    this->GetInput(0)->GetDimensions(imgDim);
    output->SetScalarType(VTK_FLOAT);
    output->SetOrigin(this->GetInput(0)->GetOrigin());
    output->SetSpacing(this->GetInput(0)->GetSpacing());
    // The scalar components hold the following:
    // for each regressor: beta value
    // plus chisq (the sum of squares of the residuals from the best-fit)
    // plus the correlation coefficient at lag 1 generated from error modeling.
    // plus one % signal change for each regressors
    output->SetNumberOfScalarComponents(noOfRegressors * 2 + 2);
    output->SetDimensions(imgDim[0], imgDim[1], imgDim[2]);
    output->AllocateScalars();
   
    // Array holding time course of a voxel
    vtkFloatArray *tc = vtkFloatArray::New();
    tc->SetNumberOfTuples(this->NumberOfInputs);
    tc->SetNumberOfComponents(1);

    // for progress update (bar)
    unsigned long count = 0;
    unsigned long target = (unsigned long)(imgDim[0]*imgDim[1]*imgDim[2] / 100.0);
    target++;

    // Use memory allocation for MS Windows VC++ compiler.
    // beta[noOfRegressors] is not allowed by MS Windows VC++ compiler.
    float *beta = new float [noOfRegressors];

    // array of % signal change; one for each beta
    float *pSigChanges = new float [noOfRegressors];

    vox = 0;
    vtkDataArray *scalarsInOutput = output->GetPointData()->GetScalars();
    // Voxel iteration through the entire image volume
    for (int kk = 0; kk < imgDim[2]; kk++)
    {
        for (int jj = 0; jj < imgDim[1]; jj++)
        {
            for (int ii = 0; ii < imgDim[0]; ii++)
            {
                // Gets time course for this voxel
                float total = 0.0;
                float scaledTotal = 0.0;
                for (int i = 0; i < this->NumberOfInputs; i++)
                {
                    short *value 
                        = (short *)this->GetInput(i)->GetScalarPointer(ii, jj, kk);

                    // time course is scaled by user option
                    float scale = 1.0;
                    if (this->GlobalEffect == 1)
                    {
                        scale = 100.0 / this->GrandMean;
                    }
                    else if (this->GlobalEffect == 2)
                    {
                        scale = 100.0 / this->GlobalMeans[i];
                    }
                    else if (this->GlobalEffect == 3)
                    {
                        scale = (100.0 / this->GlobalMeans[i]) * (100.0 / this->GrandMean);
                    }

                    float v = scale * (*value);
                    scaledTotal += v;
                    tc->SetComponent(i, 0, v);
                    total += *value;
                }   

                float chisq, p;
                if ((total/this->NumberOfInputs) > this->LowerThreshold)
                {
                    // first pass parameter estimates without modeling autocorrelation structure.
                    ((vtkGLMDetector *)this->Detector)->DisableAR1Modeling ( );
                    ((vtkGLMDetector *)this->Detector)->FitModel( tc, beta, &chisq );
                    // for testing
                    p = 0.0;
                    if ( 0 ) {
                        ((vtkGLMDetector *)this->Detector)->ComputeResiduals ( tc, beta );
                        // second pass parameter estimates, with whitened temporal autocorrelation.
                        p = ((vtkGLMDetector *)this->Detector)->ComputeCorrelationCoefficient ( );
                        ((vtkGLMDetector *)this->Detector)->PreWhitenDataAndResiduals ( tc, p );
                        ((vtkGLMDetector *)this->Detector)->EnableAR1Modeling ( );
                        ((vtkGLMDetector *)this->Detector)->FitModel( tc, beta, &chisq );
                    }
                     // now have all we need to compute inferences

                    // compute % signal changes for all betas
                    float mean = scaledTotal / this->NumberOfInputs;
                    for (int dd = 0; dd < noOfRegressors; dd++)
                    {
                        pSigChanges[dd] = 100 * beta[dd] / mean;
                    }
                }
                else
                {
                    for (int dd = 0; dd < noOfRegressors; dd++)
                    {
                        beta[dd] = 0.0;
                        pSigChanges[dd] = 0.0;
                        chisq = p = 0.0;
                    }
                }
       
                // put values into output volume
                int yy = 0;
                // betas
                for (int dd = 0; dd < noOfRegressors; dd++)
                {
                    scalarsInOutput->SetComponent(vox, yy++, beta[dd]);
                }
                // chisq and p
                scalarsInOutput->SetComponent(vox, yy++, chisq);
                scalarsInOutput->SetComponent(vox, yy++, p);
                // % signal changes
                for (int dd = 0; dd < noOfRegressors; dd++)
                {
                    scalarsInOutput->SetComponent(vox, yy++, pSigChanges[dd]);
                }

                vox++;

                // progress bar update
                if (!(count%target))
                {
                    UpdateProgress(count / (100.0*target));
                }
                count++;
            }
        } 
    }

    delete [] beta;
    delete [] pSigChanges;

    GeneralLinearModel::Free();
    tc->Delete();
}

