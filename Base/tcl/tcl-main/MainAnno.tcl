#=auto==========================================================================
# (c) Copyright 2003 Massachusetts Institute of Technology (MIT) All Rights Reserved.
#
# This software ("3D Slicer") is provided by The Brigham and Women's 
# Hospital, Inc. on behalf of the copyright holders and contributors. 
# Permission is hereby granted, without payment, to copy, modify, display 
# and distribute this software and its documentation, if any, for internal 
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
# FILE:        MainAnno.tcl
# PROCEDURES:  
#   MainAnnoInit
#   MainAnnoBuildVTK
#   MainAnnoBuildGUI
#   MainAnnoUpdateFocalPoint
#   MainAnnoSetFov
#   MainAnnoSetVisibility
#   MainAnnoSetCrossVisibility
#   MainAnnoSetHashesVisibility
#   MainAnnoSetColor
#   MainAnnoStorePresets
#   MainAnnoRecallPresets
#   MainAnnoSetPixelDisplayFormat mode
#==========================================================================auto=


#-------------------------------------------------------------------------------
# .PROC MainAnnoInit
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainAnnoInit {} {
    global Module Anno Gui

    # Define Procedures
    lappend Module(procStorePresets) MainAnnoStorePresets
    lappend Module(procRecallPresets) MainAnnoRecallPresets

        # Set version info
        lappend Module(versions) [ParseCVSInfo MainAnno \
        {$Revision: 1.22 $} {$Date: 2003/03/13 22:30:55 $}]

    # Preset Defaults
    set Module(Anno,presets) "box='1' axes='0' outline='0' letters='1' cross='0'\
hashes='1' mouse='1'"

    set Anno(box) 1
    set Anno(axes) 0
    set Anno(outline) 0
    set Anno(letters) 1
    set Anno(cross) 0
    set Anno(hashes) 1
    set Anno(mouse) 1

    set Anno(color) "1 1 0.5"
    set Anno(mmHashGap) 5
    set Anno(mmHashDist) 10
    set Anno(numHashes) 5
    set Anno(boxFollowFocalPoint) 1
    set Anno(axesFollowFocalPoint) 0
    set Anno(letterSize) 0.05
    set Anno(cursorMode) RAS
    set Anno(cursorModePrev) RAS
    # default display of floating point pixel values
    set Anno(pixelDispFormat) %.f

    if {$Gui(smallFont) == 0} {
        set Anno(fontSize) 16
    } else {
        set Anno(fontSize) 14
    }

    # Cursor anno: RAS, Back & Fore pixels
    #---------------------------------------------
    set Anno(mouseList) "cur1 cur2 cur3 msg curBack curFore"
    set Anno(y256) "237 219 201 40 22 4"
    set Anno(y512) "492 474 456 40 22 4"

    # Orient anno: top bot left right
    #---------------------------------------------
    set Anno(orientList) "top bot right left"
    set Anno(orient,x256) "130 130 240 1"
    set Anno(orient,x512) "258 258 496 1"
    set Anno(orient,y256) "240 4 131 131"
    set Anno(orient,y512) "495 4 259 259"
}

#-------------------------------------------------------------------------------
# .PROC MainAnnoBuildVTK
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainAnnoBuildVTK {} {
    global Gui Anno View Slice 

  
    #---------------------------------------------
    # 3D VIEW ANNO
    #---------------------------------------------

    set fov2 [expr $View(fov) / 2]

    #---------------------#
    # Bounding Box
    #---------------------#
    MakeVTKObject Outline box
    boxActor SetScale $fov2 $fov2 $fov2
    boxActor SetPickable 0
     [boxActor GetProperty] SetColor 1.0 0.0 1.0

    #---------------------#
    # Axes
    #---------------------#
    foreach axis "x y z" {
        vtkLineSource ${axis}Axis
            ${axis}Axis SetResolution 10
        vtkPolyDataMapper ${axis}AxisMapper
            ${axis}AxisMapper SetInput [${axis}Axis GetOutput]
        vtkActor ${axis}AxisActor
            ${axis}AxisActor SetMapper ${axis}AxisMapper
            ${axis}AxisActor SetScale $fov2 $fov2 $fov2
            ${axis}AxisActor SetPickable 0
            [${axis}AxisActor GetProperty] SetColor 1.0 0.0 1.0

        MainAddActor ${axis}AxisActor
    }
    set pos  1.2
    set neg -1.2
    xAxis SetPoint1 $neg 0    0
    xAxis SetPoint2 $pos 0    0
    yAxis SetPoint1 0    $neg 0
    yAxis SetPoint2 0    $pos 0
    zAxis SetPoint1 0    0    $neg
    zAxis SetPoint2 0    0    $pos

    #---------------------#
    # RAS axis labels
    #---------------------#    
    set scale [expr $View(fov) * $Anno(letterSize) ]

    foreach axis "R A S L P I" {
        vtkVectorText ${axis}Text
            ${axis}Text SetText "${axis}"
        vtkPolyDataMapper  ${axis}Mapper
            ${axis}Mapper SetInput [${axis}Text GetOutput]
        vtkFollower ${axis}Actor
            ${axis}Actor SetMapper ${axis}Mapper
            ${axis}Actor SetScale  $scale $scale $scale 
            ${axis}Actor SetPickable 0
            if {$View(bgName)=="White"} {
                [${axis}Actor GetProperty] SetColor 0 0 1
            } else {
                [${axis}Actor GetProperty] SetColor 1 1 1
            }
        [${axis}Actor GetProperty] SetDiffuse 0.0
        [${axis}Actor GetProperty] SetAmbient 1.0
        [${axis}Actor GetProperty] SetSpecular 0.0
        # add only to the Main View window
        viewRen AddActor ${axis}Actor

    }
    set pos [expr   $View(fov) * 0.6]
    set neg [expr - $View(fov) * 0.6]
    RActor SetPosition $pos 0.0  0.0
    AActor SetPosition 0.0  $pos 0.0
    SActor SetPosition 0.0  0.0  $pos 
    LActor SetPosition $neg 0.0  0.0
    PActor SetPosition 0.0  $neg 0.0
    IActor SetPosition 0.0  0.0  $neg 

    
}

#-------------------------------------------------------------------------------
# .PROC MainAnnoBuildGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainAnnoBuildGUI {} {
    global Gui Anno View Slice
    
    #---------------------------------------------
    # SLICE ANNO
    #---------------------------------------------
    
    set Anno(actorList) ""
    
    # Line along distance being measured, and radii for arcs
    #---------------------------------------------
    foreach name "r1 r2" {
        foreach s $Slice(idList) {
            vtkLineSource Anno($s,$name,source)
            vtkPolyDataMapper2D Anno($s,$name,mapper)
                Anno($s,$name,mapper) SetInput \
                    [Anno($s,$name,source) GetOutput]
            vtkActor2D Anno($s,$name,actor)
                Anno($s,$name,actor) SetMapper \
                    Anno($s,$name,mapper)
                Anno($s,$name,actor) SetLayerNumber 1
                eval [Anno($s,$name,actor) GetProperty] \
                    SetColor $Anno(color)
                Anno($s,$name,actor) SetVisibility 0
            sl${s}Imager AddActor2D Anno($s,$name,actor)
        }
    }

    # Cursor anno: RAS, Back & Fore pixels
    #---------------------------------------------
    foreach name $Anno(mouseList) y256 $Anno(y256) y512 $Anno(y512) {    
        foreach s $Slice(idList) {
            vtkTextMapper Anno($s,$name,mapper)
                Anno($s,$name,mapper) SetInput ""
            if {[info commands vtkTextProperty] != ""} {
               [Anno($s,$name,mapper) GetTextProperty] SetFontFamilyToTimes
               [Anno($s,$name,mapper) GetTextProperty] SetFontSize $Anno(fontSize)
               [Anno($s,$name,mapper) GetTextProperty] BoldOn
               [Anno($s,$name,mapper) GetTextProperty] ShadowOn
            } else {
                Anno($s,$name,mapper) SetFontFamilyToTimes
                Anno($s,$name,mapper) SetFontSize $Anno(fontSize)
                Anno($s,$name,mapper) BoldOn
                Anno($s,$name,mapper) ShadowOn
            }
            vtkActor2D Anno($s,$name,actor)
                Anno($s,$name,actor) SetMapper \
                    Anno($s,$name,mapper)
                Anno($s,$name,actor) SetLayerNumber 1
                eval [Anno($s,$name,actor) GetProperty] \
                    SetColor $Anno(color)
                Anno($s,$name,actor) SetVisibility 0
            sl${s}Imager AddActor2D Anno($s,$name,actor)
            [Anno($s,$name,actor) GetPositionCoordinate] \
                SetValue 1 $y256
        }
        set Anno($name,rect256) "1 $y256 40 [expr $y256+18]"
        set Anno($name,rect512) "1 $y512 40 [expr $y512+18]"
    }

    # Orient anno: top bot left right
    #---------------------------------------------
    foreach name $Anno(orientList) \
        x256 $Anno(orient,x256) x512 "$Anno(orient,x512)" y256 "$Anno(orient,y256)" y512 $Anno(orient,y512) {
            
        foreach s $Slice(idList) {
            vtkTextMapper Anno($s,$name,mapper)
                Anno($s,$name,mapper) SetInput ""
            if {[info commands vtkTextProperty] != ""} {
               [Anno($s,$name,mapper) GetTextProperty] SetFontFamilyToTimes
               [Anno($s,$name,mapper) GetTextProperty] SetFontSize $Anno(fontSize)
               [Anno($s,$name,mapper) GetTextProperty] BoldOn
               [Anno($s,$name,mapper) GetTextProperty] ShadowOn
            } else {
                Anno($s,$name,mapper) SetFontFamilyToTimes
                Anno($s,$name,mapper) SetFontSize $Anno(fontSize)
                Anno($s,$name,mapper) BoldOn
                Anno($s,$name,mapper) ShadowOn
            }
            vtkActor2D Anno($s,$name,actor)
                Anno($s,$name,actor) SetMapper \
                    Anno($s,$name,mapper)
                Anno($s,$name,actor) SetLayerNumber 1
                eval [Anno($s,$name,actor) GetProperty] \
                    SetColor $Anno(color)
                Anno($s,$name,actor) SetVisibility 1 
            sl${s}Imager AddActor2D Anno($s,$name,actor)
            [Anno($s,$name,actor) GetPositionCoordinate] \
                SetValue $x256 $y256
        }
    }


    #---------------------#
    # Cameras 
    #---------------------#    

    # Make anno letters follow camera
    foreach axis "R A S L P I" {
        ${axis}Actor SetCamera $View(viewCam)
    }

}

#-------------------------------------------------------------------------------
# .PROC MainAnnoUpdateFocalPoint
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainAnnoUpdateFocalPoint {{xFP ""} {yFP ""} {zFP ""}} {
    global Anno View

    if {$xFP == ""} {
        set fp [$View(viewCam) GetFocalPoint]
        set xFP [lindex $fp 0]
        set yFP [lindex $fp 1]
        set zFP [lindex $fp 2]
    }

    if {$Anno(boxFollowFocalPoint) == 0} {
        boxActor SetPosition 0 0 0
    } else {
        boxActor SetPosition $xFP $yFP $zFP
    }

    if {$Anno(axesFollowFocalPoint) == 0} {
        set xFP 0
        set yFP 0
        set zFP 0
    }
    xAxisActor SetPosition $xFP $yFP $zFP
    yAxisActor SetPosition $xFP $yFP $zFP
    zAxisActor SetPosition $xFP $yFP $zFP

    set pos [expr   $View(fov) * 0.6]
    set neg [expr - $View(fov) * 0.6]
    RActor SetPosition [expr $pos+$xFP] $yFP  $zFP
    AActor SetPosition $xFP  [expr $pos+$yFP] $zFP
    SActor SetPosition $xFP  $yFP  [expr $pos+$zFP] 
    LActor SetPosition [expr $neg+$xFP] $yFP  $zFP
    PActor SetPosition $xFP  [expr $neg+$yFP] $zFP
    IActor SetPosition $xFP  $yFP  [expr $neg+$zFP] 
}

#-------------------------------------------------------------------------------
# .PROC MainAnnoSetFov
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainAnnoSetFov {} {
    global Anno View

    set fov2 [expr $View(fov) / 2]
    foreach axis "x y z" {
        ${axis}AxisActor SetScale $fov2 $fov2 $fov2
    }
    boxActor SetScale $fov2 $fov2 $fov2

    set scale [expr $View(fov) * $Anno(letterSize) ]
    foreach axis "R A S L P I" {
        ${axis}Actor SetScale  $scale $scale $scale 
    }
    set pos [expr   $View(fov) * 0.6]
    set neg [expr - $View(fov) * 0.6]
    RActor SetPosition $pos 0.0  0.0
    AActor SetPosition 0.0  $pos 0.0
    SActor SetPosition 0.0  0.0  $pos 
    LActor SetPosition $neg 0.0  0.0
    PActor SetPosition 0.0  $neg 0.0
    IActor SetPosition 0.0  0.0  $neg 
}

#-------------------------------------------------------------------------------
# .PROC MainAnnoSetVisibility
#
# Checks the Anno Array and sets visibility of the following objects
#   The cube in the 3D scene
#   The Axes in the 3D scene
#   The letters in the 3D scene (RASLPI)
#   The outline around the slices in the 3D scene
#   The Cross Hairs in the 2D scene
#   The Hash Marks on the Cross Hairs in the 2D scene
#   The Letters in the 2D scene.
#   Everything in Slice(idlist)
#
# Visibility is set using the vtkActor Setvisibility command.
#
# usage: MainAnnoSetVisibility
# .END
#-------------------------------------------------------------------------------
proc MainAnnoSetVisibility {} {
    global Slice Anno AnnoEdit Anno

    boxActor SetVisibility $Anno(box)
    
    foreach u "x y z" {
        ${u}AxisActor  SetVisibility $Anno(axes)
    }
    foreach u "R A S L P I" {
        ${u}Actor      SetVisibility $Anno(letters)
    }

    MainAnnoSetCrossVisibility  slices $Anno(cross)
    MainAnnoSetHashesVisibility slices $Anno(hashes)
    MainAnnoSetCrossVisibility  mag    $Anno(cross)
    MainAnnoSetHashesVisibility mag    $Anno(hashes)

    foreach s $Slice(idList) {
        if {$Anno(outline) == 1} {
            Slice($s,outlineActor) SetVisibility $Slice($s,visibility)
        } else {
            Slice($s,outlineActor) SetVisibility 0
        } 
        foreach name "$Anno(orientList)" {
            Anno($s,$name,actor) SetVisibility $Anno(mouse) 
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC MainAnnoSetCrossVisibility
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainAnnoSetCrossVisibility {win vis} {
    global Slice

    Slicer SetShowCursor $vis
}

#-------------------------------------------------------------------------------
# .PROC MainAnnoSetHashesVisibility
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainAnnoSetHashesVisibility {win vis} {
    global Slice

    if {$vis == 1} {
        set vis 5
    }
    Slicer SetNumHashes $vis
}

#-------------------------------------------------------------------------------
# .PROC MainAnnoSetColor
# SLICER DAVE not called
# .END
#-------------------------------------------------------------------------------
proc MainAnnoSetColor {color} {
    global Slice

    eval Slicer SetCursorColor $color
}

#-------------------------------------------------------------------------------
# .PROC MainAnnoStorePresets
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainAnnoStorePresets {p} {
    global Preset Anno

    foreach key $Preset(Anno,keys) {
        set Preset(Anno,$p,$key) $Anno($key)
    }
}

#-------------------------------------------------------------------------------
# .PROC MainAnnoRecallPresets
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainAnnoRecallPresets {p} {
    global Preset Anno

    foreach key $Preset(Anno,keys) {
        set Anno($key) $Preset(Anno,$p,$key)
    }
    MainAnnoSetVisibility
}


#-------------------------------------------------------------------------------
# .PROC MainAnnoSetPixelDisplayFormat
#  Set the display formatting used when the pixel values
# are shown above the 2D slices.  Options are int display,
# two decimal points, or full floating-point display.
# This procedure is here in case a module in the slicer
# wants to set things up to view non-standard data, say floats.
#
# FUTURE IDEAS:
# It would be nice if this sort of setting could be pushed/
# popped like the bindings stack that Peter wrote (Events.tcl).
# This would allow modules to control the visualization
# but not interfere with other modules.
# .ARGS
# str mode can be default, decimal, or full
# .END
#-------------------------------------------------------------------------------
proc MainAnnoSetPixelDisplayFormat {mode} {
    global Anno

    switch $mode {
    "default" {
        set Anno(pixelDispFormat) %.f
    } 
    "decimal" {
        set Anno(pixelDispFormat) %6.2f
    } 
    "full" {        
        set Anno(pixelDispFormat) %f
    } 
    }
}
