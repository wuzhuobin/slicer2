/**
 * File:          $RCSfile: camera_equidistant.h,v $
 * Module:        Equidistant camera functions
 * Part of:       Gandalf Library
 *
 * Revision:      $Revision: 1.1.2.1 $
 * Last edited:   $Date: 2007/10/14 02:33:13 $
 * Author:        $Author: ruetz $
 * Copyright:     (c) 2000 Imagineer Software Limited
 */

/* This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

#ifndef _GAN_CAMERA_EQUIDISTANT_H
#define _GAN_CAMERA_EQUIDISTANT_H

#include <stdio.h>
#include <gandalf/vision/camera.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * \addtogroup Vision
 * \{
 */

/**
 * \addtogroup Camera
 * \{
 */

Gan_Bool gan_camera_build_equidistant ( Gan_Camera *camera,
                                        double zh, double fx, double fy,
                                        double x0, double y0 );

/**
 * \}
 */

/**
 * \}
 */

#ifdef __cplusplus
}
#endif

#endif /* #ifndef _GAN_CAMERA_EQUIDISTANT_H */