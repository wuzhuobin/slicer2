/**************************************************************************
*
* File:          $RCSfile: slansp.c,v $
* Module:        CLAPACK function
* Part of:       Gandalf Library
*
* Revision:      $Revision: 1.1.2.1 $
* Last edited:   $Date: 2007/10/14 02:26:49 $
* Author:        $Author: ruetz $
* Copyright:     Modifications (c) 2000 Imagineer Software Limited
*
* Notes:         
* Private func:  
* History:       Modified from original CLAPACK source code 
*
**************************************************************************/

#include <math.h>
#include <gandalf/linalg/clapack/slansp.h>
#include <gandalf/linalg/clapack/slassq.h>
#include <gandalf/common/compare.h>

/* only define this function locally if there is no LAPACK installed */
#if !defined(HAVE_LAPACK) || defined(FORCE_LOCAL_LAPACK)

/* modified from CLAPACK source */

float gan_slansp(Gan_LapackNormType norm, Gan_LapackUpLoFlag upper, long n,
                 float *ap, float *work)
{
   /* System generated locals */
   float ret_val, d__1;
   /* Local variables */
   float absa;
   long i__, j, k;
   float scale;
   float value = 0.0F;
   float sum;

   /* Function Body */
   if (n == 0)
      value = 0.0F;
   else if (norm == GAN_NORMTYPE_MAXABSVAL)
   {
      /*        Find max(abs(A(i,j))). */
      value = 0.0F;
      if (upper)
      {
         k = 0;
         for (j = 0; j < n; ++j)
         {
            for (i__ = k; i__ <= k+j; ++i__)
               value = gan_max2_d(value, fabs(ap[i__]));

            k += j+1;
         }
      }
      else
      {
         k = 0;
         for (j = 0; j < n; ++j)
         {
            for (i__ = k; i__ <= k+n-j-1; ++i__)
               value = gan_max2_d(value, fabs(ap[i__]));

            k = k+n-j;
         }
      }
   }
   else if (norm == GAN_NORMTYPE_INFINITY)
   {
      /*        Find normI(A) ( = norm1(A), since A is symmetric). */
      value = 0.0F;
      k = 0;
      if (upper)
      {
         for (j = 0; j < n; ++j)
         {
            sum = 0.0F;
            for (i__ = 0; i__ <= j; ++i__)
            {
               absa = fabs(ap[k]);
               sum += absa;
               work[i__] += absa;
               ++k;
            }

            work[j] = sum + fabs(ap[k]);
            ++k;
         }

         for (i__ = 0; i__ < n; ++i__)
            /* Computing MAX */
            value = gan_max2_d(value, work[i__]);
      }
      else
      {
         for (i__ = 0; i__ < n; ++i__)
            work[i__] = 0.0F;

         for (j = 0; j < n; ++j)
         {
            sum = work[j] + fabs(ap[k]);
            ++k;
            for (i__ = j + 1; i__ < n; ++i__)
            {
               absa = fabs(ap[k]);
               sum += absa;
               work[i__] += absa;
               ++k;
            }

            value = gan_max2_d(value,sum);
         }
      }
   }
   else if (norm == GAN_NORMTYPE_FROBENIUS)
   {
      /*        Find normF(A). */
      scale = 0.0F;
      sum = 1.0F;
      k = 1;
      if (upper)
      {
         for (j = 1; j < n; ++j)
         {
            gan_slassq(j-1, &ap[k], 1, &scale, &sum);
            k += j+1;
         }
      }
      else
      {
         for (j = 0; j < n-1; ++j)
         {
            gan_slassq(n-j-1, &ap[k], 1, &scale, &sum);
            k = k+n-j;
         }
      }

      sum *= 2;
      k = 0;
      for (i__ = 0; i__ < n; ++i__)
      {
         if (ap[k] != 0.0F)
         {
            absa = fabs(ap[k]);
            if (scale < absa)
            {
               /* Computing 2nd power */
               d__1 = scale / absa;
               sum = sum * (d__1 * d__1) + 1.0F;
               scale = absa;
            }
            else
            {
               /* Computing 2nd power */
               d__1 = absa / scale;
               sum += d__1 * d__1;
            }
         }

         if (upper)
            k = k+i__+2;
         else
            k = k+n-i__+2;
      }

      value = scale*sqrt(sum);
   }

   ret_val = value;
   return ret_val;
}

#endif /* #if !defined(HAVE_LAPACK) || defined(FORCE_LOCAL_LAPACK) */