/*=auto=========================================================================

(c) Copyright 2001 Massachusetts Institute of Technology

Permission is hereby granted, without payment, to copy, modify, display 
and distribute this software and its documentation, if any, for any purpose, 
provided that the above copyright notice and the following three paragraphs 
appear on all copies of this software.  Use of this software constitutes 
acceptance of these terms and conditions.

IN NO EVENT SHALL MIT BE LIABLE TO ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, 
INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE 
AND ITS DOCUMENTATION, EVEN IF MIT HAS BEEN ADVISED OF THE POSSIBILITY OF 
SUCH DAMAGE.

MIT SPECIFICALLY DISCLAIMS ANY EXPRESS OR IMPLIED WARRANTIES INCLUDING, 
BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR 
A PARTICULAR PURPOSE, AND NON-INFRINGEMENT.

THE SOFTWARE IS PROVIDED "AS IS."  MIT HAS NO OBLIGATION TO PROVIDE 
MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.

=========================================================================auto=*/
#include "vtkDataTimeDef.h"
#include "vtkThread.h"

// ---------------------------------------------------------
// EMVolume Definiton 
// ---------------------------------------------------------
void EMVolume::Print(char name[]) {
  int y,x,z;
  for (z = 0; z < this->MaxZ; z++) {
    cout << name  << "[" << z+1 << "] = [" << endl; 
    for (y = 0; y < this->MaxY; y++) {
      for (x = 0; x < this->MaxX; x++) cout << (*this)(z,y,x) << " ";
      if (y < this->MaxY-1) cout << endl;
    }
    cout << "]; " << endl;
  }
}

void EMVolume::Test(int Vdim) {
    // KILIAN
  cout << "fix for windows ======================================================================" << endl;
#ifndef _WIN32
  int x,y,z;
  float v[Vdim];
  float *vtest = new float[Vdim];
  EMVolume result(this->MaxZ,this->MaxY,this->MaxX),
           Copy(this->MaxZ,this->MaxY,this->MaxX);

  this->SetValue(1.0);

  cout << "======================================================================" << endl;
  cout << "Test Run with Volume Dim " << this->MaxZ << "and Vector Dim " << Vdim << endl;
  cout << "v = [";
  for (x = 0; x < Vdim; x++) {
    v[x] = x+1;
    vtest[x] = x+1;
    cout << v[x] << " " ;
  }
  cout << "];" << endl;

  Copy = (*this);

  START_PRECISE_TIMING; 
  Copy.ConvY(v,Vdim);
  result.ConvX(Copy,v,Vdim);
  Copy.ConvZ(result,v,Vdim);
  END_PRECISE_TIMING;
  SHOW_ELAPSED_PRECISE_TIME;  

  //  Copy.Print("Z");
  // Copy = *this;
  cout << "----------------- 2 Version ------------" << endl;
  // Faster with 1 PCU (and only slightly slower with 2) and less memory
  START_PRECISE_TIMING; 
  this->ConvY(v,Vdim);
  //this->Print("Y"); 
  this->ConvX(v,Vdim);
  //this->Print("X"); 
  this->ConvZ(v,Vdim);
  END_PRECISE_TIMING;
  SHOW_ELAPSED_PRECISE_TIME;  
  // this->Print("Z"); 
 
  cout << "----------------- 3 Version (MultiThreaded)------------" << endl;
  // The multi Threaded version takes longer - so do not use it 
  START_PRECISE_TIMING; 
  Copy.ConvMultiThread(vtest,Vdim);
  END_PRECISE_TIMING;
  SHOW_ELAPSED_PRECISE_TIME;  
  // Copy.Print("Z"); 
  delete []vtest;
#endif
}

// Kilian : This is just so we are compatible with older version
void EMVolume::Conv(double *v,int vLen) {
  float *v_f = new float[vLen];
  for (int i = 0; i < vLen; i++) v_f[i] = float(v[i]);
  this->Conv(v_f,vLen);  
  delete[] v_f;
}



inline void EMVolume::ConvY(float *v, int vLen) {
  int x,y,z;

  // => Utrans[i] represents the i column of U;    
  float * col     = new float[this->MaxY],
        * result  = new float[this->MaxY];
  float * DataStart = this->Data;

  for (z = 0; z < this->MaxZ; z++) {
    for (x = 0; x < this->MaxX; x++) {
      for (y = 0; y < this->MaxY; y++) {
    col[y] = *this->Data;
    this->Data +=this->MaxX; 
      }
      this->Data -= this->MaxXY;
      convVector(result,col,this->MaxY,v,vLen); // Use the i-th Rows of Utrans; 
      for (y=0; y < this->MaxY; y++) {
    *this->Data = result[y]; // Write result to this->mat as i-th column
    this->Data +=this->MaxX; 
      }
      this->Data -= this->MaxXY -1;
    }
    this->Data += this->MaxXY-this->MaxX;
  }
  this->Data = DataStart; 
  delete[] result;
  delete[] col;
} 

// Same just v is a row vector instead of column one
// We use the following equation :
// conv(U,v) = conv(U',v')' => conv(U,v') = conv(U',v)';
inline void EMVolume::ConvX(float *v, int vLen) {
  int x,i,MaxYZ;

  // Use the i-th Rows of U = ith Column of U';
  // write it to the i-th Row of 'this' => Transpose again
  float  * row     = new float[this->MaxX],
         * result  = new float[this->MaxX];
  float  * DataStart = this->Data;

  MaxYZ = this->MaxY*this->MaxZ;
  for (i = 0; i < MaxYZ; i++) {
    for (x = 0; x < this->MaxX; x++) row[x] = *this->Data++;
    this->Data -= this->MaxX;
    convVector(result,row,this->MaxX,v,vLen); 
    for (x=0; x < this->MaxX; x++) *this->Data++ = result[x];
  }
  this->Data = DataStart;
  delete[] result;
  delete[] row;
} 

// Same just v is a row vector instead of column one
// We use the following equation :
// conv(U,v) = conv(U',v')' => conv(U,v') = conv(U',v)';
inline void EMVolume::ConvX(EMVolume &src,float *v, int vLen) {
  int x,i,MaxYZ;

  // Use the i-th Rows of U = ith Column of U';
  // write it to the i-th Row of 'this' => Transpose again
  float  * row       = new float[this->MaxX],
         * result    = new float[this->MaxX],
         * DataStart = this->Data,
         * SrcStart  = src.Data;

  MaxYZ = this->MaxY*this->MaxZ;
  for (i = 0; i < MaxYZ; i++) {
    for (x = 0; x < this->MaxX; x++) row[x] = *src.Data ++;
    convVector(result,row,this->MaxX,v,vLen); 
    for (x=0; x < this->MaxX; x++) *this->Data ++ = result[x];
  }
  delete[] result;
  delete[] row;
  this->Data = DataStart;
  src.Data = SrcStart;
} 

// Convolution and polynomial multiplication . 
// This is assuming u and 'this' have the same dimension
inline void EMVolume::ConvZ(EMVolume &src,float *v,int vLen) {
  int stump = vLen /2;
  int i,k,j,jMin,jMax;

  int kMax = this->MaxZ + stump;

  float *SrcDataStart = src.Data;
  float *DataStart    = this->Data;
  float *vSta = v;

  for (k = stump; k <  kMax; k++) {
    for (i = 0; i < this->MaxXY; i++) {
      *this->Data++ = 0;
    }
    jMin = (0 > (k+1 - vLen) ? 0 : (k+1  - vLen));     //  max(0,k+1-vLen):
    jMax = ((k+1) < this->MaxZ ? (k+1) : this->MaxZ);     //  min(k+1,mat3DZlen) 

    // this->mat3D[k-stump] += U[j]*v[k-j];
    src.Data = SrcDataStart + this->MaxXY*jMin;  
    v = vSta + k-jMin; 
    for (j=jMin; j < jMax; j++) {
      this->Data -= this->MaxXY;
      for (i = 0; i < this->MaxXY; i++) {
    *this->Data += (*src.Data) * (*v);
    this->Data++;src.Data ++;
      }
      v--;
    }
  } 
  this->Data = DataStart;
  src.Data = SrcDataStart;  
}

// No unecessary memrory -> faster
inline void EMVolume::ConvZ(float *v, int vLen) {
  int z,i,MaxXYZ;

  // Use the i-th Rows of U = ith Column of U';
  // write it to the i-th Row of 'this' => Transpose again
  float  * vec     = new float[this->MaxZ],
         * result  = new float[this->MaxZ];
  float  * DataStart = this->Data;

  MaxXYZ = this->MaxXY*this->MaxZ;

  for (i = 0; i < this->MaxXY; i++) {
    for (z = 0; z < this->MaxZ; z++) {
      vec[z] = *this->Data;
      this->Data += this->MaxXY;
    }
    this->Data -= MaxXYZ;
    convVector(result,vec,this->MaxZ,v,vLen); 

    for (z=0; z < this->MaxZ; z++) {
      *this->Data = result[z];
      this->Data += this->MaxXY;
    }
    this->Data -= (MaxXYZ-1);
  }
  this->Data = DataStart;

  delete[] result;
  delete[] vec;
} 


#ifndef _WIN32
// ---------------------------------------------------------
// Functions to Multi Thread Convolution
// somehow copied from Simon convolution.cxx
// ---------------------------------------------------------
// Be Carefull ouput will be written to the instance - and input must be of the same dimension
// as *this 


void ConvolutionFilterWorker(void *jobparm)
{
  convolution_filter_work *job = (convolution_filter_work *)jobparm;

  /* For each image pixel,
   *   fill array with image values,
   *   copy convolution into output image
   */
  int i; int j; int k;
  int n; int m; int o;
  int nvals = 0;

  int index; 
  int M1 = job->M1;
  int M2 = job->M2;
  int N1 = job->N1;
  int N2 = job->N2;
  int O1 = job->O1;
  int O2 = job->O2;

  int filterSliceSize = (M2 - M1 +1)*(N2 - N1 + 1);
  int filterRowSize = (N2 - N1 + 1);
  int nrow = job->nrow;
  int ncol = job->ncol;
  int nslice = job->nslice;

  float *input = NULL;
  float *output = NULL;
  float *filter = job->filter;

  float sum = 0.0;
  int coeff = -1;


  index = job->startindex;
  m = (index / job->ncol) % job->nrow;
  n = index % job->ncol;
  o = index / (job->ncol * job->nrow);

  input = &job->input[o*nrow*ncol+m*ncol+n];
  output = &job->output[o*nrow*ncol+m*ncol+n];

  for (index = job->startindex; index < job->endindex; index++) {
    m = (index / job->ncol) % job->nrow;
    n = index % job->ncol;
    o = index / (job->ncol * job->nrow);
    sum = 0.0;
    coeff = -1;
    for (k = O1; k <= O2; k++) {
      for (i = M1; i <= M2; i++) {
        for (j = N1; j <= N2; j++) {
          coeff++;
      // cout << coeff << endl;
          if (o < k || o > k + nslice - 1) continue;
          if (m < i || m > i + nrow - 1) continue;
          if (n < j || n > j + ncol - 1) continue;
            sum += (*(input + job->indexes[coeff])) * filter[coeff];
        }
      }
    }
    (*output) = sum;
    input++;
    output++;
  }

}

int EMVolume::ConvolutionFilter_workpile(float *input, float *filter, int M1, int M2, int N1, int N2, int O1, int O2)
{
  #define MAXCONVOLUTIONWORKERTHREADS 32
  int numthreads = 0;
  workpile_t workpile;
  int npixels = this->MaxXY*this->MaxZ;
  int jobsize;

  convolution_filter_work job[MAXCONVOLUTIONWORKERTHREADS];
  int i; int j; int k;
  int icount;
  int *indexes = NULL;
  int numindexes = (M2-M1+1)*(N2-N1+1)*(O2-O1+1);

  indexes = (int *)malloc(sizeof(int)*numindexes);
  assert(indexes != NULL);

  /* y[n] = \sum_k(-inf, +inf) h[k] x[n-k] */
  icount = 0;
  for (k = O1; k <= O2; k++) {
    for (i = M1; i <= M2; i++) {
      for (j = N1; j <= N2; j++) {
        indexes[icount] = -(i)*this->MaxX + -(k)*this->MaxXY - j;
        icount++;
      }
    }
  }
 
  numthreads = vtkThreadNumCpus(void);
  vtkThread thread;
  assert((numthreads <= MAXCONVOLUTIONWORKERTHREADS) && (numthreads > 0));
  workpile = thread.work_init(numthreads, ConvolutionFilterWorker, numthreads);

  jobsize = npixels/numthreads;
  for (i = 0; i < numthreads; i++) {
    if (i == 0) {
      job[i].startindex = 0;
    } else {
      job[i].startindex = job[i-1].endindex;
    }
    if (i == (numthreads - 1)) {
      job[i].endindex = npixels;
    } else {
      job[i].endindex = (i+1)*jobsize;
    }
    job[i].input  = input;
    job[i].nrow   = this->MaxY;
    job[i].ncol   = this->MaxX;
    job[i].nslice = this->MaxZ;
    job[i].filter = filter;
    job[i].indexes = indexes;
    job[i].numindexes = numindexes;
    job[i].M1 = M1;
    job[i].M2 = M2;
    job[i].N1 = N1;
    job[i].N2 = N2;
    job[i].O1 = O1;
    job[i].O2 = O2;
    job[i].output = this->Data;
    thread.work_put(workpile, &job[i]);
  }

  /* At this point all the jobs are done and the workers are waiting */
  /* In order to avoid a memory leak they should now all be killed off,
   *   or asked to suicide
   */
  thread.work_wait(workpile);
  thread.work_finished_forever(workpile);

  free(indexes);

  return 0; /* Success */
}

// Be Carefull ouput will be written to the instance - and input must be of the same dimension
// as *this 
int EMVolume::ConvMultiThread(float* filter, int filterLen) {
  int min_filter = - filterLen /2;
  int max_filter = min_filter + filterLen -1; // -1 for 0 !!!
  EMVolume temp(this->MaxZ,this->MaxY,this->MaxX);
  /* Filter in the y direction with f2 */
  temp.ConvolutionFilter_workpile(this->Data,filter,0,0,min_filter,max_filter,0,0);
  /* Filter in the x direction with f1 */
  this->ConvolutionFilter_workpile(temp.Data,filter,min_filter,max_filter,0,0,0,0);

  /* Filter in the z direction with f1 */
  temp.ConvolutionFilter_workpile(this->Data,filter,0,0,0,0,min_filter,max_filter);

  *this = temp;

  return 0; /* success */
}
#endif
