#=auto==========================================================================
# (c) Copyright 2005 Massachusetts Institute of Technology (MIT) All Rights Reserved.
#
# This software ("3D Slicer") is provided by The Brigham and Women's 
# Hospital, Inc. on behalf of the copyright holders and contributors. 
# Permission is hereby granted, without payment, to copy, modify, display 
# and distribute this software and its documentation, if any, for 
# research purposes only, provided that (1) the above copyright notice and 
# the following four paragraphs appear on all copies of this software, and 
# (2) that source code to any modifications to this software be made 
# publicly available under terms no more restrictive than those in this 
# License Agreement. Use of this software constitutes acceptance of these 
# terms and conditions.
# 
# 3D Slicer Software has not been reviewed or approved by the Food and 
# Drug Administration, and is for non-clinical, IRB-approved Research Use 
# Only.  In no event shall data or images generated through the use of 3D 
# Slicer Software be used in the provision of patient care.
# 
# IN NO EVENT SHALL THE COPYRIGHT HOLDERS AND CONTRIBUTORS BE LIABLE TO 
# ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL 
# DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, 
# EVEN IF THE COPYRIGHT HOLDERS AND CONTRIBUTORS HAVE BEEN ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.
# 
# THE COPYRIGHT HOLDERS AND CONTRIBUTORS SPECIFICALLY DISCLAIM ANY EXPRESS 
# OR IMPLIED WARRANTIES INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
# WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND 
# NON-INFRINGEMENT.
# 
# THE SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS 
# IS." THE COPYRIGHT HOLDERS AND CONTRIBUTORS HAVE NO OBLIGATION TO 
# PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
# 
#
#===============================================================================
# FILE:        DTMRIODF.tcl
# PROCEDURES:  
#   DTMRIRegInit
#   DTMRIBuildVTKODF
#   DTMRIBuildODFFrame
#   DTMRIUpdateReformatType
#   DTMRIODFUpdate
#==========================================================================auto=
#-------------------------------------------------------------------------------
# .PROC DTMRIRegInit
#  This procedure is called from DTMRIInit and initializes the
#  Tensor Registration Module.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIODFInit {} {

  global DTMRI Volume

  set DTMRI(InputODF) $Volume(idNone)
  set DTMRI(ODF,scaleFactor) 2
  set DTMRI(ODF,minODF) 0
  set DTMRI(ODF,maxODF) 0.02
  # whether we are currently displaying glyphs
  set DTMRI(mode,visualizationType,glyphsODFOn) 0ff
  set DTMRI(mode,visualizationType,glyphsODFOnList) {On Off}
  set DTMRI(mode,visualizationType,glyphsODFOnList,tooltip) [list \
                                "Display each DTMRI as a glyph\n(for example a line or ellipsoid)" \
                                "Do not display glyphs" ]

}

#-------------------------------------------------------------------------------
# .PROC DTMRIBuildVTKODF
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIBuildVTKODF {} {
    global DTMRI Module
    
    set object glyphsODF
    foreach plane "0 1 2" {
    #DTMRIMakeVTKObject vtkDTMRIGlyph $object
    
    #DTMRIMakeVTKObject vtkHighAngularResolutionGlyph $object$plane
    #DTMRI(vtk,glyphsODF$plane) SetInput ""
    DTMRIMakeVTKObject vtkODFGlyph $object$plane
    DTMRI(vtk,glyphsODF$plane) SetInput ""
    }
}    
    



#-------------------------------------------------------------------------------
# .PROC DTMRIBuildODFFrame
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIBuildODFFrame {} {

  global Gui Module Volume DTMRI

  set fODF $Module(DTMRI,fODF);

  set f $fODF


  foreach frame "Input Display Reformat Scale" {
  frame $f.f$frame -bg $Gui(backdrop)
  pack $f.f$frame -side top -padx $Gui(pad) -pady $Gui(pad) -fill x
  }
  
  set f $fODF.fInput
  
  DevAddSelectButton DTMRI $f InputODF "ODF: " Pack "Select ODF volume." 20
  lappend Volume(mbInputODF) $f.mbInputODF
  lappend Volume(mInputODF) $f.mbInputODF.m

  
  set f $fODF.fDisplay

   eval {label $f.lVis -text "Display Glyphs: "} $Gui(WLA)
   pack $f.lVis -side left -pady $Gui(pad) -padx $Gui(pad)
    # Add menu items
    foreach vis $DTMRI(mode,visualizationType,glyphsODFOnList) \
    tip $DTMRI(mode,visualizationType,glyphsODFOnList,tooltip) {
        eval {radiobutton $f.r$vis \
              -text $vis \
              -command "DTMRIODFUpdate" \
              -value $vis \
              -variable DTMRI(mode,visualizationType,glyphsODFOn) \
              -indicatoron 0} $Gui(WCA)

        pack $f.r$vis -side left -fill x
        TooltipAdd $f.r$vis $tip
    }
    
  set f $fODF.fReformat
    DevAddLabel $f.l "Glyphs on Slice:"
    pack $f.l -side left -padx $Gui(pad) -pady 0

    set colors [list  $Gui(slice0) $Gui(slice1) $Gui(slice2) $Gui(activeWorkspace) $Gui(activeWorkspace)]
    set widths [list  2 2 2 4 4]

    foreach vis $DTMRI(mode,reformatTypeList) \
    tip $DTMRI(mode,reformatTypeList,tooltips) \
    text $DTMRI(mode,reformatTypeList,text) \
    color $colors \
    width $widths {
        eval {radiobutton $f.rMode$vis \
              -text "$text" -value "$vis" \
              -variable DTMRI(mode,reformatType) \
              -command {DTMRIODFUpdateReformatType} \
              -indicatoron 0 } $Gui(WCA) \
        {-bg $color -selectcolor $color -width $width}
        pack $f.rMode$vis -side left -padx 0 -pady 0
        TooltipAdd  $f.rMode$vis $tip
    }
    
   set f  $fODF.fScale
   
   DevAddLabel $f.l "Scale Factor:"
   
   eval {entry $f.e -justify right -width 4 \
          -textvariable DTMRI(ODF,scaleFactor)  } $Gui(WEA)
   
   eval {scale $f.s -from 1 \
                          -to 10    \
          -variable  DTMRI(ODF,scaleFactor)\
      -command {DTMRIODFUpdateScale} \
          -orient vertical     \
          -resolution 0.1      \
          } $Gui(WSA)
   
   pack $f.l $f.e $f.s -side left -padx $Gui(pad) -pady 0
}
 
proc DTMRIODFUpdateScale { val } {

 global DTMRI
 
 foreach plane {0 1 2} {
      DTMRI(vtk,glyphsODF$plane) SetScaleFactor $DTMRI(ODF,scaleFactor)
 }
 
 #Render3D
}      
 
#-------------------------------------------------------------------------------
# .PROC DTMRIUpdateReformatType
#  Reformat the requested slice (from GUI input) or all.  Then call
#  pipeline update proc (DTMRIUpdate) to make this happen.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIODFUpdateReformatType {} {
    global DTMRI

    set mode $DTMRI(mode,reformatType)

    set result ok

    # make sure we don't display all DTMRIs by accident
    switch $mode {
        "None" {
            set message "This will display ALL DTMRIs.  If the volume is not masked using a labelmap or threshold ROI, this may take a long time or not work on your machine.  Proceed?"
            set result [tk_messageBox -type okcancel -message $message]
        }
    }

    # display what was requested
    if {$result == "ok"} {
        DTMRIODFUpdate
    }
}


#-------------------------------------------------------------------------------
# .PROC DTMRIODFUpdate
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIODFUpdate {} {
 
 
    global DTMRI Slice Volume Label Gui Tensor

    set t $DTMRI(InputODF)
    if {$t == "" || $t == $Volume(idNone)} {
        puts "DTMRIODFUpdate: Can't visualize Nothing"
        return
    }

    # reset progress text for any filter that uses the blue bar
    set Gui(progressText) "Working..."

    #------------------------------------
    # preprocessing pipeline
    #------------------------------------
    
        #------------------------------------
    # visualization pipeline
    #------------------------------------
    #set mode $DTMRI(mode,visualizationType)
    set mode $DTMRI(mode,visualizationType,glyphsODFOn)
    puts "Setting glyph mode $mode for DTMRI $t"
    
    switch $mode {
        "On" {
            puts "glyphs! $DTMRI(mode,glyphType)"
            
            # Find input to pipeline
            #------------------------------------
            set slice $DTMRI(mode,reformatType)

        # find ijk->ras rotation to apply to each DTMRI
        #vtkTransform t2 
        #DTMRICalculateIJKtoRASRotationMatrix t2 $t
        #puts "Lauren testing rm -y"
        #t2 Scale 1 -1 1
        #puts [[t2 GetMatrix] Print]
        #DTMRI(vtk,glyphs) SetTensorRotationMatrix [t2 GetMatrix]
        #t2 Delete

    set transform DTMRI(vtk,glyphs,trans)
    $transform SetMatrix [Volume($t,node)  GetWldToIjk]
    # Now it's ijk to ras
    $transform Inverse

    # Remove the voxel scaling from the matrix.
    # -------------------------------------
    scan [Volume($t,node) GetSpacing] "%g %g %g" res_x res_y res_z

    # We want -y since vtk flips the y axis
    #puts "Not flipping y"
    #set res_y [expr -$res_y]
    $transform Scale [expr 1.0 / $res_x] [expr 1.0 / $res_y] \
    [expr 1.0 / $res_z]

    # Remove the translation part from the last column.
    # (This was in there to center the volume in the cube.)
    # -------------------------------------
    [$transform GetMatrix] SetElement 0 3 0
    [$transform GetMatrix] SetElement 1 3 0
    [$transform GetMatrix] SetElement 2 3 0
    # Set element (4,4) to 1: homogeneous point
    [$transform GetMatrix] SetElement 3 3 1
    
    set node Volume($t,node)
    
    foreach plane {0 1 2} {
      DTMRI(vtk,glyphsODF$plane) SetTensorRotationMatrix [DTMRI(vtk,glyphs,trans) GetMatrix]
      DTMRI(vtk,glyphsODF$plane) SetFieldOfView [Slicer GetFieldOfView]
      DTMRI(vtk,glyphsODF$plane) SetWldToIjkMatrix [$node GetWldToIjk]
      DTMRI(vtk,glyphsODF$plane) SetScaleFactor $DTMRI(ODF,scaleFactor)
      DTMRI(vtk,glyphsODF$plane) SetMinODF $DTMRI(ODF,minODF)
      DTMRI(vtk,glyphsODF$plane) SetMaxODF $DTMRI(ODF,maxODF)
      DTMRI(vtk,glyphsODF$plane) SetFieldOfView [Slicer GetFieldOfView]    
      }
    if {$slice != "None"} {
       foreach plane $slice {
           # We are reformatting a slice of glyphs
           DTMRI(vtk,glyphsODF$plane) SetInput [Volume($t,vol) GetOutput]
       set m [Slicer GetReformatMatrix $plane]
       DTMRI(vtk,glyphsODF$plane) SetVolumePositionMatrix $m
        }       
     }
     # Append glyphs
     #------------------------------------
     #Disconnect previous glyphs
       set prevnumInputs [DTMRI(vtk,glyphs,append) GetNumberOfInputs]
          for {set i 0} {$i < $prevnumInputs} {incr i} {
            DTMRI(vtk,glyphs,append) SetInputByNumber $i ""
          }     
        if {$slice != "None"} {
          set numInputs [llength $slice]
          DTMRI(vtk,glyphs,append) SetNumberOfInputs $numInputs
          foreach plane $slice {
            DTMRI(vtk,glyphs,append) SetInputByNumber [expr $plane%$numInputs] [DTMRI(vtk,glyphsODF$plane) GetOutput]
          }
        } else {
          set numInputs 1
          DTMRI(vtk,glyphs,append) SetNumberOfInputs $numInputs
          DTMRI(vtk,glyphs,append) SetInputByNumber 0 [DTMRI(vtk,glyphsODF0) GetOutput]
        }         
     
        # for ODF don't use normals filter before mapper
        #DTMRI(vtk,glyphs,mapper) SetInput \
        #[DTMRI(vtk,glyphs,append) GetOutput]
    
    DTMRI(vtk,glyphs,mapper) SetInput [DTMRI(vtk,glyphsODF$slice) GetOutput]
    
    #Change LookUp Table
    DTMRI(vtk,glyphs,mapper) SetLookupTable [DTMRI(vtk,glyphsODF0) GetColorTable]
    DTMRI(vtk,glyphs,mapper) UseLookupTableScalarRangeOn
    
            # in case this is the first time we load a tensor volume, 
            # place the actors in the scene now. (Now that there is input
            # to the pipeline this will not cause errors.)
            if {$DTMRI(glyphs,actorsAdded) == 0} {
                DTMRIAddAllActors
            }

            # Make actor visible
            #------------------------------------
            DTMRI(vtk,glyphs,actor) VisibilityOn
        [DTMRI(vtk,glyphs,actor) GetProperty] SetDiffuse .1
        [DTMRI(vtk,glyphs,actor) GetProperty] SetSpecular .1
          
    }
    
     "Off" {
            puts "Turning off DTMRI visualization"

            # make invisible so output
            # not requested from pipeline anymore
            #------------------------------------
            DTMRI(vtk,glyphs,actor) VisibilityOff
        }
      }
    # make sure the scalars are updated (if we have anything displayed)
    if {$mode != "None" && $DTMRI(glyphs,actorsAdded)==1} {
        DTMRIUpdateGlyphScalarRange
    }
      
      Render3D    
             
}
   
