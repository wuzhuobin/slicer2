/**
 * File:          $RCSfile: bitmap_test.c,v $
 * Module:        Binary image test program
 * Part of:       Gandalf Library
 *
 * Revision:      $Revision: 1.1.2.1 $
 * Last edited:   $Date: 2007/10/14 02:20:15 $
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

#include <gandalf/TestFramework/cUnit.h>
#include <gandalf/image/bitmap_test.h>
#include <gandalf/image/io/image_io.h>
#include <gandalf/image/image_bit.h>
#include <gandalf/common/misc_error.h>

#ifdef WIN32
        #include <windows.h>
#endif

/* only do display for stand-alone version of program */
#ifdef BITMAP_TEST_MAIN
#include <gandalf/image/image_display.h>
#ifdef __APPLE__
#include <OpenGL/gl.h>
#include <OpenGL/glu.h>
#include <GLUT/glut.h>
#else
#include <GL/gl.h>
#include <GL/glu.h>
#include <GL/glut.h>
#endif
static int window_id;
#endif /* #ifdef BITMAP_TEST_MAIN */

static Gan_Image *img=NULL;

#ifdef BITMAP_TEST_MAIN
/* Displays the image on the screen */
static void display_image(void)
{
   /* display image */
   glRasterPos2i ( 0, 0 );
   gan_image_display ( img );
   glFlush();
}
#endif /* #ifdef BITMAP_TEST_MAIN */

static Gan_Bool setup_test(void)
{
   printf("\nSetup for bitmap_test completed!\n\n");
   return GAN_TRUE;
}

static Gan_Bool teardown_test(void)
{
   printf("\nTeardown for bitmap_test completed!\n\n");
   return GAN_TRUE;
}

static Gan_Bool
 print_file_contents ( Gan_Image *image )
{
   unsigned i, j;

   cu_assert ( image->format == GAN_GREY_LEVEL_IMAGE &&
               image->type == GAN_BOOL );
   for ( i = 0; i < image->height; i++ )
   {
      printf ( "\"" );
      for ( j = 0; j < image->width; j++ )
         printf ( "%c", gan_image_get_pix_b(image,i,j) ? '1' : '0' );

      printf ( "\",\n" );
   }

   return GAN_TRUE;
}

#ifdef BITMAP_TEST_MAIN   
#define QUIT 99

static void ModeMenu ( int entry )
{
   switch ( entry )
   {
      case QUIT:
        glutDestroyWindow ( window_id );
        gan_image_free ( img );
        exit(EXIT_SUCCESS);
        break;
        
      default:
        fprintf ( stderr, "illegal menu entry %d\n", entry );
        exit(EXIT_FAILURE);
        break;
   }
}
#endif /* #ifdef BITMAP_TEST_MAIN */

/* Runs the vision bitmap test functions */
static Gan_Bool run_test(void)
{
   char *image_file = acBuildPathName(TEST_INPUT_PATH,"gandalf_bw.png");

   /* read image from file */
   img = gan_image_read ( image_file, GAN_PNG_FORMAT, NULL, NULL, NULL );
   cu_assert ( img != NULL );

   /* only set to 1 when regenerating data for string at the bottom of
      this file */
   if(0)
      cu_assert ( print_file_contents ( img ) );

#ifdef BITMAP_TEST_MAIN   
   cu_assert ( gan_display_new_window ( img->height, img->width, 1.0,
                                        image_file, 0, 0, &window_id ) );

   glutDisplayFunc ( display_image );

   /* Setup the menu, which is available by right clicking on the image */
   glutCreateMenu( ModeMenu );
   glutAddMenuEntry ( "Quit", QUIT );
   glutAttachMenu(GLUT_RIGHT_BUTTON);

   /* enter event handling loop */
   glutMainLoop();

   /* shouldn't get here */
   return GAN_FALSE;
#else
   {
      unsigned i, j;

      /* compare image with precompiled string generated by
         print_file_contents() */
      cu_assert ( img->format == GAN_GREY_LEVEL_IMAGE &&
                  img->type == GAN_BOOL );
      for ( i = 0; i < img->height; i++ )
         for ( j = 0; j < img->width; j++ )
         {
            cu_assert ( (gan_image_get_pix_b ( img, i, j ) == GAN_TRUE)
                        ? (img_string[i][j] == '1')
                        : (img_string[i][j] == '0') );
         }
   }

   /* success */
   gan_image_free ( img );
   return GAN_TRUE;
#endif
}

#ifdef BITMAP_TEST_MAIN

int main ( int argc, char *argv[] )
{
   /* turn on error tracing */
   gan_err_set_trace ( GAN_ERR_TRACE_ON );

   setup_test();
   if ( run_test() )
      printf ( "Tests ran successfully!\n" );
   else
   {
      printf ( "At least one test failed\n" );
      printf ( "Gandalf errors:\n" );
      gan_err_default_reporter();
   }
   
   teardown_test();
   gan_heap_report(NULL);
   return 0;
}

#else

/* This function registers the unit tests to a cUnit_test_suite. */
cUnit_test_suite *bitmap_test_build_suite(void)
{
   cUnit_test_suite *sp;

   /* Get a new test session */
   sp = cUnit_new_test_suite("bitmap_test suite");

   cUnit_add_test(sp, "bitmap_test", run_test);

   /* register a setup and teardown on the test suite 'bitmap_test' */
   if (cUnit_register_setup(sp, setup_test) != GAN_TRUE)
      printf("Error while setting up test suite bitmap_test");

   if (cUnit_register_teardown(sp, teardown_test) != GAN_TRUE)
      printf("Error while tearing down test suite bitmap_test");

   return( sp );
}

#endif /* #ifdef BITMAP_TEST_MAIN */