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
# FILE:        MainModels.tcl
# PROCEDURES:  
#   MainModelsInit
#   MainModelsUpdateMRML
#   MainModelsShouldBeAVtkClass
#   MainModelsCreate
#   MainModelsRead
#   MainModelsInitGUIVariables
#   MainModelsDelete
#   MainModelsBuildGUI
#   MainModelsCreateGUI widget int int
#   MainModelsRefreshGUI
#   MainModelsPopupCallback
#   MainModelsDeleteGUI
#   MainModelsDestroyGUI
#   MainModelsPopup
#   MainModelsSetActive
#   MainModelsSetColor
#   MainModelsSetVisibility
#   MainModelsRefreshClipping when to
#   MainModelsSetClipping m value
#   MainModelsSetOpacityInit
#   MainModelsSetOpacity
#   MainModelsSetCulling
#   MainModelsSetScalarVisibility
#   MainModelsRegisterModel
#   MainModelsWrite
#   MainModelsStorePresets
#   MainModelsRaiseScalarBar m
#   MainModelsRemoveScalarBar m
#   MainModelsToggleScalarBar m
#   MainModelsChangeRenderer
#==========================================================================auto=


#-------------------------------------------------------------------------------
# .PROC MainModelsInit
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainModelsInit {} {
    global Model Module

    # This proc is called specifically
    # lappend Module(procGUI)  MainModelsBuildGUI

    # Define Procedures
    lappend Module(procStorePresets) MainModelsStorePresets
    lappend Module(procRecallPresets) MainModelsRecallPresets
    set Module(Models,presets) ""

        # Set version info
        lappend Module(versions) [ParseCVSInfo MainModels \
        {$Revision: 1.54 $} {$Date: 2003/03/13 22:30:56 $}]

    set Model(idNone) -1
    set Model(activeID) ""
    set Model(freeze) ""

    # Append widgets to list that gets refreshed during UpdateMRML
    set Model(mbActiveList) ""
    set Model(mActiveList)  ""

    # Props
    set Model(name) ""
    set Model(prefix) ""
    set Model(visibility) 1
    set Model(opacity) 1.0
    set Model(clipping) 0
    set Model(culling) 1
    set Model(scalarVisibility) 0
    set Model(scalarLo) 0
    set Model(scalarHi) 100
    set Model(desc) ""
        set Model(activeRenderer) viewRen
}

#-------------------------------------------------------------------------------
# .PROC MainModelsUpdateMRML
#
# This proc is called whenever the MRML scene graph changes.
# It updates everything except the GUI for all models.  
# This means reading/deleting polydata, updating actors, and redoing
# any existing menus of models in Model(mActiveList). (These are menus to
# select the active model in the Models module and may be in other modules).
#
#
# Updating GUIs for all models is done in tcl-modules/Models.tcl 
# since if the module is not loaded, no GUIs should exist!
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainModelsUpdateMRML {} {
    global Model Gui Module Color ModelGroup

    # Build any new models
    #--------------------------------------------------------
    foreach m $Model(idList) {
        if {[MainModelsCreate $m] > 0} {
            
            # Mark it as not being created on the fly 
            # since it was added from the Data module or read in from MRML
            set Model($m,fly) 0
            
            # Read
            if {[MainModelsRead $m] < 0} {
            # failed
            MainMrmlDeleteNodeDuringUpdate Model $m
            }
        }
    }
    
    set f $Model(fScrolledGUI)
    
    # Delete any old models
    #--------------------------------------------------------
    foreach m $Model(idListDelete) {
        MainModelsDelete $m
    }
    # Did we delete the active model?
    if {[lsearch $Model(idList) $Model(activeID)] == -1} {
        MainModelsSetActive [lindex $Model(idList) 0]
    }

    # Delete any old model groups
    #--------------------------------------------------------
    foreach mg $ModelGroup(idListDelete) {
        MainModelGroupsDelete $f $mg
    }
    

    # Refresh Actor (in case color changed)
    #--------------------------------------------------------
    
    foreach m $Model(idList) {
        
        # save the current active renderer
        set activeRenderer $Model(activeRenderer)
        foreach rend $Module(Renderers) {
            set Model(activeRenderer) $rend
            MainModelsSetClipping $m
            MainModelsSetColor $m
            MainModelsSetCulling $m
            MainModelsSetVisibility $m
            MainModelsSetScalarVisibility $m
            MainModelsSetOpacity $m
            
            eval Model($m,mapper,$rend) SetScalarRange [Model($m,node) GetScalarRange]
        }
        set Model(activeRenderer) $activeRenderer
        
        foreach mg $ModelGroup(idList) {
            # second parameter "1" means: this group only, doesn't affect
            # anything that is below in the hierarchy
            catch {MainModelGroupsSetOpacity $mg 1}
        }
    }

    # Form the Active Model menu 
    #--------------------------------------------------------
    
    foreach menu $Model(mActiveList) {
        $menu delete 0 end
        
        foreach m $Model(idList) {
            $menu add command -label [Model($m,node) GetName] \
                -command "MainModelsSetActive $m"
        }
    }

    # In case we changed the name of the active model
    MainModelsSetActive $Model(activeID)
}

#-------------------------------------------------------------------------------
# .PROC MainModelsShouldBeAVtkClass
#
# There should be a vtkMrmlModel class just like there is a vtkMrmlVolume
# class.  However, developers are hacking new model code on the fly and
# probably benefit more by only having to change tcl scripts rather than
# recompiling C++ code, right Peter?  
#
# This procedure performs what the vtkMrmlModel would do in its constructor.
#
#  With this procedure, a same model will have as many actors and properties 
#  as there are renderers. This is to be able to set different properties (ie
#  opacity) on different renderers for the same model
# 
# .END
#-------------------------------------------------------------------------------
proc MainModelsShouldBeAVtkClass {m} {
    global Model Slice Module

    foreach r $Module(Renderers) {
    # Mapper
    vtkPolyDataMapper Model($m,mapper,$r)
    }
    # Create a sphere as a default model
    vtkSphereSource src
    src SetRadius 10
    
    # Delete the src, leaving the data in Model($m,polyData)
    # polyData will survive as long as it's the input to the mapper
    #
    set Model($m,polyData) [src GetOutput]
    $Model($m,polyData) Update
    foreach r $Module(Renderers) {
    Model($m,mapper,$r) SetInput $Model($m,polyData)
    }
    src SetOutput ""
    src Delete

    # Clipper
    vtkClipPolyData Model($m,clipper)
    Model($m,clipper) SetClipFunction Slice(clipPlanes)
    Model($m,clipper) SetValue 0.0

        vtkMatrix4x4 Model($m,rasToWld)
    
        foreach r $Module(Renderers) {

        # Actor
        vtkActor Model($m,actor,$r)
        Model($m,actor,$r) SetMapper Model($m,mapper,$r)
        
        # Registration
        Model($m,actor,$r) SetUserMatrix [Model($m,node) GetRasToWld]

        # Property
        set Model($m,prop,$r)  [Model($m,actor,$r) GetProperty]

        # For now, the back face color is the same as the front
        Model($m,actor,$r) SetBackfaceProperty $Model($m,prop,$r)
    }
    set Model($m,clipped) 0
    set Model($m,displayScalarBar) 0

}

#-------------------------------------------------------------------------------
# .PROC MainModelsCreate
#
# This procedure creates a model but does not read it.
#
# Returns:
#  1 - success
#  0 - model already exists
# .END
#-------------------------------------------------------------------------------
proc MainModelsCreate {m} {
    global Model View Slice Gui Module

    # See if it already exists
    foreach r $Module(Renderers) {
        if {[info command Model($m,actor,$r)] != ""} {
        return 0
        }
    }

    MainModelsShouldBeAVtkClass    $m    

    MainModelsInitGUIVariables $m

    # Need to call this before MainModelsCreateGUI so the
    # variable Model($m,colorID) is created and valid
    MainModelsSetColor $m

    # Do not create the GUI here, that is done in Models.tcl
    #MainModelsCreateGUI $Gui(wModels).fGrid $m

    MainAddModelActor $m
    
    # Mark it as unsaved and created on the fly.
    # If it actually isn't being created on the fly, I can't tell that from
    # inside this procedure, so the "fly" variable will be set to 0 in the
    # MainModelsUpdateMRML procedure.
    set Model($m,dirty) 1
    set Model($m,fly) 1

    return 1
}

#-------------------------------------------------------------------------------
# .PROC MainModelsRead
# Reads in a model from disk.  The other vtk objects, etc. associated
# with the model must already have been created using MainModelsCreate.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainModelsRead {m} {
    global Model Gui Module

    # If fileName = "", then do nothing
    set fileName [Model($m,node) GetFullFileName]
    if {$fileName == ""} {
        DevWarningWindow "MainModelsRead: empty filename"
        return
    }

    # Check fileName
    if {[CheckFileExists $fileName] == 0} {
        DevWarningWindow "MainModelsRead: File does not exist, filename = $fileName"
        return -1
    }
    set name [Model($m,node) GetName]

    # Reader
    set suffix [file extension $fileName]
    if {$suffix == ".g"} {
        vtkBYUReader reader
        reader SetGeometryFileName $fileName
    } elseif {$suffix == ".vtk"} {
        vtkPolyDataReader reader
        reader SetFileName $fileName
    }  elseif {$suffix == ".orig" || $suffix == ".inflated" || $suffix == ".pial"} {
        # read in a free surfer file
        vtkFSSurfaceReader reader
        reader SetFileName $fileName
    }


    # Progress Reporting
    reader SetStartMethod     MainStartProgress
    reader SetProgressMethod "MainShowProgress reader"
    reader SetEndMethod       MainEndProgress

    # Read it in now
    set Gui(progressText) "Reading $name"
    puts "Reading model $m $name..."
    
    # NOTE: if I have the following line, then when I
    # set the clipper's input to be Model($m,polyData), then
    # polyData (being the reader's output) releases it's polygon
    # data while still existing as a VTK object.
    # So if I clip, then unclip a model, the model disappears.
    # I'm leaving the following line here to ensure no one uses it:
    # [reader GetOutput] ReleaseDataFlagOff

    # Delete the reader, leaving the data in Model($m,polyData)
    # polyData will survive as long as it's the input to the mapper
    #
    set Model($m,polyData) [reader GetOutput]
    $Model($m,polyData) Update
    foreach r $Module(Renderers) {
        Model($m,mapper,$r) SetInput $Model($m,polyData)
    }
    reader SetOutput ""
    reader Delete

    # Mark this model as saved
    set Model($m,dirty) 0

    return 1
}

#-------------------------------------------------------------------------------
# .PROC MainModelsInitGUIVariables
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainModelsInitGUIVariables {m} {
    global Model RemovedModels

    set Model($m,visibility)       [Model($m,node) GetVisibility]
    set Model($m,opacity)          [Model($m,node) GetOpacity]
    set Model($m,scalarVisibility) [Model($m,node) GetScalarVisibility]
    set Model($m,backfaceCulling)  [Model($m,node) GetBackfaceCulling]
    set Model($m,clipping)         [Model($m,node) GetClipping]
    # set expansion to 1 if variable doesn't exist
    if {[info exists Model($m,expansion)] == 0} {
        set Model($m,expansion)    1
    }
    # set RemovedModels to 0 if variable doesn't exist
    if {[info exists RemovedModels($m)] == 0} {
        set RemovedModels($m) 0
    }
}

#-------------------------------------------------------------------------------
# .PROC MainModelsDelete
# If you want a model to be history, this is the procedure you call.
# .ARG
#  int m the id number of the model to be deleted.
# .END
#-------------------------------------------------------------------------------
proc MainModelsDelete {m} {
    global Model View Gui Dag Module

    # If we've already deleted this one, then do nothing
        foreach r $Module(Renderers) {
        if {[info command Model($m,actor,$r)] == ""} {
        return 0
        }
    }

    # Remove actors from renderers

    MainRemoveModelActor $m
    
    # Delete VTK objects (and remove commands from TCL namespace)
    Model($m,clipper) Delete
        foreach r $Module(Renderers) {
        Model($m,mapper,$r) Delete    
        Model($m,actor,$r) Delete
    }
    Model($m,rasToWld) Delete

    # The polyData should be gone from reference counting, but I'll make sure:
    catch {Model($m,polyData) Delete}

    # Delete all TCL variables of the form: Model($m,<whatever>)
    foreach name [array names Model] {
        if {[string first "$m," $name] == 0} {
            unset Model($name)
        }
    }

    MainModelsDeleteGUI $Gui(wModels).fGrid $m
    
    return 1
}

#-------------------------------------------------------------------------------
# .PROC MainModelsBuildGUI
#
# Builds the basic part of the Models GUI. (creates the popup window
# and the frames)  The rest is done in MainModelsCreateGUI
# for each model, so that it can be redrawn when needed.
# .END
#-------------------------------------------------------------------------------
proc MainModelsBuildGUI {} {
    global Gui Model

    #-------------------------------------------
    # Models Popup Window
    #-------------------------------------------
    set w .wModels
    set Gui(wModels) $w
    toplevel $w -class Dialog -bg $Gui(activeWorkspace)
    wm title $w "Models"
    wm iconname $w Dialog
    wm protocol $w WM_DELETE_WINDOW "wm withdraw $w"
    if {$Gui(pc) == "0"} {
        wm transient $w .
    }
    wm withdraw $w

    # Close button
    eval {button $w.bClose -text "Close" -command "wm withdraw $w"} $Gui(WBA)

    # Frames
    frame $w.fGrid -bg $Gui(activeWorkspace)
    frame $w.fAll -bg $Gui(activeWorkspace)
    pack $w.fGrid $w.fAll $w.bClose -side top -pady $Gui(pad)

    #-------------------------------------------
    # Models->All frame
    #-------------------------------------------
    set f $w.fAll
    eval {button $f.bAll -text "Show All" -width 10 \
        -command "MainModelsSetVisibility All"} $Gui(WBA)
    eval {button $f.bNone -text "Show None" -width 10 \
        -command "MainModelsSetVisibility None"} $Gui(WBA)
    pack $f.bAll $f.bNone -side left -padx $Gui(pad) -pady 0

    #-------------------------------------------
    # Models->Grid frame
    #-------------------------------------------
    set f $Gui(wModels).fGrid
    eval {label $f.lV -text Visibility} $Gui(WLA)
    eval {label $f.lO -text Opacity} $Gui(WLA)
#    eval {label $f.lC -text Clip} $Gui(WLA)
#    grid $f.lV $f.lO $f.lC -pady 2 -padx 2
    grid $f.lV $f.lO -pady 2 -padx 2
    grid $f.lO -columnspan 2
#    grid $f.lC -column 3

    # Rest Done in MainModelsCreateGUI

}

#-------------------------------------------------------------------------------
# .PROC MainModelsCreateGUI
# Makes the GUI for each model on the Models->Display panel.
# This is called for each new model.
# Also makes the popup menu that comes up when you right-click a model.
#
# .ARGS
# f widget the frame to create the GUI in
# m int the id of the model
# hlevel int the indentation to use when building the GUI
# .END
#-------------------------------------------------------------------------------
proc MainModelsCreateGUI {f m {hlevel 0}} {
    global Gui Model Color


        # puts "Creating GUI for model $m"        
    # If the GUI already exists, then just change name.
    if {[info command $f.c$m] != ""} {
        $f.c$m config -text "[Model($m,node) GetName]"
        return 0
    }

    # Name / Visible
    
    eval {checkbutton $f.c$m \
        -text [Model($m,node) GetName] -variable Model($m,visibility) \
        -width 17 -indicatoron 0 \
        -command "MainModelsSetVisibility $m; Render3D"} $Gui(WCA)
    $f.c$m configure -bg [MakeColorNormalized \
            [Color($Model($m,colorID),node) GetDiffuseColor]]
    $f.c$m configure -selectcolor [MakeColorNormalized \
            [Color($Model($m,colorID),node) GetDiffuseColor]]
            
    # Add a tool tip if the string is too long for the button
    if {[string length [Model($m,node) GetName]] > [$f.c$m cget -width]} {
        TooltipAdd $f.c$m [Model($m,node) GetName]
    }
    
    eval {label $f.l1_$m -text "" -width 1} $Gui(WLA)
    
    # menu
    eval {menu $f.c$m.men} $Gui(WMA)
    set men $f.c$m.men
    $men add command -label "Change Color..." -command \
        "MainModelsSetActive $m; ShowColors MainModelsPopupCallback"
    $men add check -label "Clipping" \
        -variable Model($m,clipping) \
        -command "MainModelsSetClipping $m; Render3D"
    $men add check -label "Backface culling" \
        -variable Model($m,backfaceCulling) \
        -command "MainModelsSetCulling $m; Render3D"
    $men add check -label "Scalar Visibility" \
        -variable Model($m,scalarVisibility) \
        -command "MainModelsSetScalarVisibility $m; Render3D"
    $men add check -label "Scalar Bar" \
        -variable Model($m,displayScalarBar) \
        -command "MainModelsToggleScalarBar $m; Render3D"
    $men add command -label "Delete Model" -command "MainMrmlDeleteNode Model $m; Render3D"
    $men add command -label "-- Close Menu --" -command "$men unpost"
    bind $f.c$m <Button-3> "$men post %X %Y"
    
    # Opacity    
    eval {entry $f.e${m} -textvariable Model($m,opacity) -width 3} $Gui(WEA)
    bind $f.e${m} <Return> "MainModelsSetOpacity $m; Render3D"
    bind $f.e${m} <FocusOut> "MainModelsSetOpacity $m; Render3D"
    eval {scale $f.s${m} -from 0.0 -to 1.0 -length 40 \
        -variable Model($m,opacity) \
        -command "MainModelsSetOpacityInit $m $f.s$m" \
        -resolution 0.1} $Gui(WSA) {-sliderlength 14 \
        -troughcolor [MakeColorNormalized \
            [Color($Model($m,colorID),node) GetDiffuseColor]]}
    
    # Clipping
#    eval {checkbutton $f.cClip${m} -variable Model($m,clipping) \
    -command "MainModelsSetClipping $m; Render3D"} $Gui(WCA) {-indicatoron 1}

#    grid $f.c${m} $f.e${m} $f.s${m} $f.cClip$m -pady 2 -padx 2
    
    set l1_command $f.l1_${m}
    set c_command $f.c${m}
    
    for {set i 0} {$i<[expr $hlevel+1]} {incr i} {
        lappend l1_command "-"
    }
    
    for {set i 5} {$i>$hlevel} {incr i -1} {
        lappend c_command "-"
    }
    
    eval grid $l1_command $c_command $f.e${m} $f.s${m} -pady 2 -padx 2 -sticky we

    return 1
}

#-------------------------------------------------------------------------------
# .PROC MainModelsRefreshGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainModelsRefreshGUI {m c} {
    global Model

    # This was from Dave
    # I shouldn't have to do this test, but making sure
    #if {[lsearch $Color(idList) $c] != -1}
    
    # Find the GUI components
    set f $Model(fScrolledGUI)
    set slider $f.s$m
    set button $f.c$m

    # Find the color for this model
    if {$c != ""} {
    set rgb [Color($c,node) GetDiffuseColor]
    } else {
    set rgb "0 0 0"
    }
    set color [MakeColorNormalized $rgb]

    # Color slider and colored checkbuttons
    # catch is important here, because the GUI variables for
    # models may have not been initialized yet
    ColorSlider $slider $rgb
    catch {$button configure -bg $color}
    catch {$button configure -selectcolor $color}

}


#-------------------------------------------------------------------------------
# .PROC MainModelsPopupCallback
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainModelsPopupCallback {} {
    global Label Model

    set m $Model(activeID)
    if {$m == ""} {return}

    Model($m,node) SetColor $Label(name)
    MainModelsSetColor $m
    MainUpdateMRML
}

#-------------------------------------------------------------------------------
# .PROC MainModelsDeleteGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainModelsDeleteGUI {f m} {
    global Gui Model Color

    # If the GUI is already deleted, return
    if {[info command $f.c$m] == ""} {
        return 0
    }

    # Destroy TK widgets
    destroy $f.c$m
    destroy $f.e$m
    destroy $f.s$m
    destroy $f.l1_$m
#    destroy $f.cClip$m

    return 1
}

#-------------------------------------------------------------------------------
# .PROC MainModelsDestroyGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainModelsDestroyGUI {} {
    global Model

    set f $Model(fScrolledGUI)

    # delete all models in hierarchy tree
    
    Mrml(dataTree) InitTraversal
    set node [Mrml(dataTree) GetNextItem]
    while {$node != ""} {
        if {[string compare -length 8 $node "ModelRef"] == 0} {
            set CurrentModelID [SharedModelLookup [$node GetModelRefID]]
            if {$CurrentModelID != -1} {
                MainModelsDeleteGUI $f $CurrentModelID
            }
        }
        if {[string compare -length 10 $node "ModelGroup"] == 0} {
            MainModelGroupsDeleteGUI $f [$node GetID]
        }
        set node [Mrml(dataTree) GetNextItem]
    }
    
}

#-------------------------------------------------------------------------------
# .PROC MainModelsPopup
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainModelsPopup {X Y} {
    global Gui

    # Recreate window if user killed it
    if {[winfo exists $Gui(wModels)] == 0} {
        MainModelsBuildGUI
    }
    
    ShowPopup $Gui(wModels) $X $Y
}

#-------------------------------------------------------------------------------
# .PROC MainModelsSetActive
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainModelsSetActive {m} {
    global Model Label

    if {$Model(freeze) == 1} {return}
    
    set Model(activeID) $m

    # Change button text
    if {$m == ""} {
        foreach mb $Model(mbActiveList) {
            $mb config -text "None"
        }
    } elseif {$m == "NEW"} {
        foreach mb $Model(mbActiveList) {
            $mb config -text "NEW"
        }
        # Use defaults
        vtkMrmlModelNode default
        set Model(name)             [default GetName]
                set Model(FileName)         ""
        set Model(prefix)           [file root [default GetFileName]]
        set Model(visibility)       [default GetVisibility]
        set Model(opacity)          [default GetOpacity]
        set Model(culling)          [default GetBackfaceCulling]
        set Model(scalarVisibility) [default GetScalarVisibility]
        set Model(scalarLo)         [lindex [default GetScalarRange] 0]
        set Model(scalarHi)         [lindex [default GetScalarRange] 1]
        set Model(desc)             [default GetDescription]
        LabelsSetColor              [default GetColor]
        default Delete
    } else {
        foreach mb $Model(mbActiveList) {
            $mb config -text [Model($m,node) GetName]
        }
        set Model(name)             [Model($m,node) GetName]
        set Model(FileName)         [Model($m,node) GetFileName]
        set Model(prefix)           [file root [Model($m,node) GetFileName]]
        set Model(visibility)       [Model($m,node) GetVisibility]
        set Model(clipping)         [Model($m,node) GetClipping]
        set Model(opacity)          [Model($m,node) GetOpacity]
        set Model(culling)          [Model($m,node) GetBackfaceCulling]
        set Model(scalarVisibility) [Model($m,node) GetScalarVisibility]
        set Model(scalarLo)         [lindex [Model($m,node) GetScalarRange] 0]
        set Model(scalarHi)         [lindex [Model($m,node) GetScalarRange] 1]
        set Model(desc)             [Model($m,node) GetDescription]
        LabelsSetColor              [Model($m,node) GetColor]
    }    
}

#-------------------------------------------------------------------------------
# .PROC MainModelsSetColor
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainModelsSetColor {m {name ""}} {
    global Model Color Gui Module

    if {$name == ""} {
        set name [Model($m,node) GetColor]
    } else {
        Model($m,node) SetColor $name
    }

    # Use second color by default
    set Model($m,colorID) [lindex $Color(idList) 1]
    foreach c $Color(idList) {
        if {[Color($c,node) GetName] == $name} {
            set Model($m,colorID) $c
        }
    }
    set c $Model($m,colorID)
        foreach r $Module(Renderers) {
        $Model($m,prop,$r) SetAmbient       [Color($c,node) GetAmbient]
        $Model($m,prop,$r) SetDiffuse       [Color($c,node) GetDiffuse]
        $Model($m,prop,$r) SetSpecular      [Color($c,node) GetSpecular]
        $Model($m,prop,$r) SetSpecularPower [Color($c,node) GetPower]
        eval $Model($m,prop,$r) SetColor    [Color($c,node) GetDiffuseColor]
    }
}

#-------------------------------------------------------------------------------
# .PROC MainModelsSetVisibility
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainModelsSetVisibility {model {value ""}} {
    global Model ModelGroup Module

    if {[string compare $model "None"] == 0} {
    foreach m $Model(idList) {
        set Model($m,visibility) 0
        Model($m,node)  SetVisibility 0
        # set the visibility for the chosen screen
        Model($m,actor,$Model(activeRenderer)) SetVisibility [Model($m,node) GetVisibility] 

    }
    foreach mg $ModelGroup(idList) {
        set ModelGroup($mg,visibility) 0
        ModelGroup($mg,node) SetVisibility 0
    }
    } elseif {[string compare $model "All"] == 0} {
    foreach m $Model(idList) {
        set Model($m,visibility) 1
        Model($m,node)  SetVisibility 1
        Model($m,actor,$Model(activeRenderer)) SetVisibility [Model($m,node) GetVisibility] 

    }
    foreach mg $ModelGroup(idList) {
        set ModelGroup($mg,visibility) 1
        ModelGroup($mg,node) SetVisibility 1
    }
    } else {
    if {$model == ""} {return}
    set m $model
    # Check if model exists
    if {[lsearch $Model(idList) $m] == -1} {
        return
    }
    if {$value != ""} {
        set Model($m,visibility) $value
    }
    Model($m,node)  SetVisibility $Model($m,visibility)

        Model($m,actor,$Model(activeRenderer)) SetVisibility [Model($m,node) GetVisibility] 
    
    # If this is the active model, update GUI
    if {$m == $Model(activeID)} {
        set Model(visibility) [Model($m,node) GetVisibility]
    }
    }
}

#-------------------------------------------------------------------------------
# .PROC MainModelsRefreshClipping
# 
# .ARGS
#  Called when the Clipping of a model is Changed. It calls 
#  MainModelsSetClipping to refresh the clipping of every model
# .END
#-------------------------------------------------------------------------------
proc MainModelsRefreshClipping {} {
    global Model Slice

    # For each model, do the appropriate Clipping
    foreach m $Model(idList) {
        MainModelsSetClipping $m
    }
}

#-------------------------------------------------------------------------------
# .PROC MainModelsSetClipping
# 
# .ARGS
#  int m the id number of the model.
#  int value \"\" means refresh.  Otherwise Sets Model(m,clipping) to value.
# .END
#-------------------------------------------------------------------------------
proc MainModelsSetClipping {m {value ""}} {
    global Model Slice Module

    if {$m == ""} {return}

    if {$value != ""} {
        set Model($m,clipping) $value
    }
    Model($m,node) SetClipping $Model($m,clipping)
        
        # Count the number of slices that Cut:
    set union 0
    foreach s $Slice(idList) {
        set union [expr $union + $Slice($s,addedFunction)]
    }

    # Automatically turn backface culling OFF during clipping

    # If we should be clipped, and we're not, then CLIP IT.
    #
    if {$Model($m,clipping) == 1 && $union > 0 && $Model($m,clipped) == 0} {

        set Model($m,clipped) 1

        #   polyData --> clipper --> mapper
        Model($m,clipper) SetInput $Model($m,polyData)
        foreach r $Module(Renderers) {
        Model($m,mapper,$r)  SetInput [Model($m,clipper) GetOutput]
        }
        # Show backface
        set Model($m,oldCulling) [Model($m,node) GetBackfaceCulling]
        MainModelsSetCulling $m 0
    
    # If we shouldn't be clipped, and we are, then UN-CLIP IT.
    #
    } elseif {($Model($m,clipping) == 0 || $union <= 0) && $Model($m,clipped) == 1} {

        set Model($m,clipped) 0

        foreach r $Module(Renderers) {
        Model($m,mapper,$r) SetInput $Model($m,polyData)
        }
        Model($m,clipper) SetInput ""

        MainModelsSetCulling $m $Model($m,oldCulling)
    }

    # If this is the active model, update GUI
    if {$m == $Model(activeID)} {
            set Model(clipping) [Model($m,node) GetClipping]
    }
}

#-------------------------------------------------------------------------------
# .PROC MainModelsSetOpacityInit
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainModelsSetOpacityInit {m widget {value ""}} {

    $widget config -command "MainModelsSetOpacity $m; Render3D"
}

#-------------------------------------------------------------------------------
# .PROC MainModelsSetOpacity
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainModelsSetOpacity {m {value ""}} {
    global Model

    # Check if model exists
    if {[lsearch $Model(idList) $m] == -1} {
        return
    }
    if {$value != ""} {
        if {[ValidateFloat $value] == 1 && $value >= 0.0 \
          && $value <= 1.0} {
            set Model($m,opacity) $value
        }
    }
    Model($m,node) SetOpacity $Model($m,opacity)
    #set the opacity in the screen chosen by the user
    $Model($m,prop,$Model(activeRenderer)) SetOpacity [Model($m,node) GetOpacity]
    
    
    # If this is the active model, update GUI
    if {$m == $Model(activeID)} {
            set Model(opacity) [Model($m,node) GetOpacity]
    }
}


#-------------------------------------------------------------------------------
# .PROC MainModelsSetCulling
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainModelsSetCulling {m {value ""}} {
    global Model Module

    if {$value != ""} {
        set Model($m,backfaceCulling) $value
    }
    Model($m,node) SetBackfaceCulling $Model($m,backfaceCulling)
    
    
    #set the backface culling in the screen chosen by the user
    $Model($m,prop,$Model(activeRenderer)) SetBackfaceCulling \
        [Model($m,node) GetBackfaceCulling]
    
    # If this is the active model, update GUI
    if {$m == $Model(activeID)} {
        set Model(backfaceCulling) [Model($m,node) GetBackfaceCulling]
    }
    
    }
    
#-------------------------------------------------------------------------------
# .PROC MainModelsSetScalarVisibility
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainModelsSetScalarVisibility {m {value ""}} {
    global Model Module
        
    if {$value != ""} {
        set Model($m,scalarVisibility) $value
    }
    Model($m,node) SetScalarVisibility $Model($m,scalarVisibility)

    Model($m,mapper,$Model(activeRenderer)) SetScalarVisibility \
        [Model($m,node) GetScalarVisibility]
    
    # If this is the active model, update GUI
    if {$m == $Model(activeID)} {
            set Model(scalarVisibility) [Model($m,node) GetScalarVisibility]
    }
}
 
proc MainModelsSetScalarRange {m lo hi} {
    global Model Module
        
    Model($m,node)   SetScalarRange $lo $hi
    foreach r $Module(Renderers) {
    Model($m,mapper,$r) SetScalarRange $lo $hi
    }
    # If this is the active model, update GUI
    if {$m == $Model(activeID)} {
        set Model(scalarLo) $lo
        set Model(scalarHi) $hi
    }
}
 
#-------------------------------------------------------------------------------
# .PROC MainModelsRegisterModel
#
# Register model m using the rasToWld
# .END
#-------------------------------------------------------------------------------
proc MainModelsRegisterModel {m rasToWld} {
    global Model

    Model($m,rasToWld) DeepCopy rasToWld
}

#-------------------------------------------------------------------------------
# .PROC MainModelsWrite
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainModelsWrite {m prefix} {
    global Model Gui Mrml

    if {$m == ""} {return}
    if {$prefix == ""} {
        tk_messageBox -message "Please provide a file prefix."
        return
    }

    # I don't understand this, but the model disappears from view after the
    # call to "writer Write", unless the model has been edited, like smoothed.
    # So don't write it if it's not dirty.
    if {$Model($m,dirty) == 0} {
        tk_messageBox -message \
            "This model will not be saved\nbecause it has not been changed\n\
since the last time it was saved."
        return
    }

    Model($m,node) SetFileName [MainFileGetRelativePrefix $prefix].vtk
    Model($m,node) SetFullFileName \
        [file join $Mrml(dir) [Model($m,node) GetFileName]]

    vtkPolyDataWriter writer
#        writer SetFileTypeToASCII
    writer SetInput $Model($m,polyData)
    writer SetFileType 2
    writer SetFileName [Model($m,node) GetFullFileName]
    set Gui(progressText) "Writing [Model($m,node) GetName]"
    puts "Writing model: '[Model($m,node) GetFullFileName]'"
    writer SetStartMethod     MainStartProgress
    writer SetProgressMethod "MainShowProgress writer"
    writer SetEndMethod       MainEndProgress
    writer Write

    writer SetInput ""
    writer Delete

    set Model($m,dirty) 0
}

#-------------------------------------------------------------------------------
# .PROC MainModelsStorePresets
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainModelsStorePresets {p} {
    global Preset Model

    foreach m $Model(idList) {
        set Preset(Models,$p,$m,visibility) $Model($m,visibility)
        set Preset(Models,$p,$m,opacity)    $Model($m,opacity)
        set Preset(Models,$p,$m,clipping)   $Model($m,clipping)
        set Preset(Models,$p,$m,backfaceCulling)   $Model($m,backfaceCulling)
    }
}
        
proc MainModelsRecallPresets {p} {
    global Preset Model

    foreach m $Model(idList) {
        if {[info exists Preset(Models,$p,$m,visibility)] == 1} {
            MainModelsSetVisibility $m $Preset(Models,$p,$m,visibility)
        }
        if {[info exists Preset(Models,$p,$m,opacity)] == 1} {
            MainModelsSetOpacity $m $Preset(Models,$p,$m,opacity)
        }
        if {[info exists Preset(Models,$p,$m,clipping)] == 1} {
            MainModelsSetClipping $m $Preset(Models,$p,$m,clipping)
        }
        if {[info exists Preset(Models,$p,$m,backfaceCulling)] == 1} {
            MainModelsSetCulling $m $Preset(Models,$p,$m,backfaceCulling)
        }
    }    
}


#-------------------------------------------------------------------------------
# .PROC MainModelsRaiseScalarBar
# Display a scalar bar: what colors the numbers are displayed as.
# Should only be used if the model has scalars and they are
# visible..
# .ARGS
# int m model id that should get the bar displayed.  Optional, defaults to idActive.
# .END
#-------------------------------------------------------------------------------
proc MainModelsRaiseScalarBar { {m ""} } {

    global viewWin Model Module
    
    if {$m == ""} {
    set m $Model(activeID)
    }

    # if another model has the scalar bar, kill it
    foreach sb $Model(idList) {
    if {$sb != $m} {
        MainModelsRemoveScalarBar $sb
    }
    }

    # if this model doesn't have scalars visible, 
    # don't show the bar
    if {$Model($m,scalarVisibility) == 0} {
    tk_messageBox -message "Please turn Scalar Visibility on for this model before displaying the scalar bar."
    # turn off the check box
    set Model($m,displayScalarBar) 0
    return
    }

    # make scalar bar
    vtkScalarBarActor bar$m 
    # save name in our array so can use info exists later
    set Model($m,scalarBar) bar$m

    # get lookup table
    set lut [Model($m,mapper,viewRen) GetLookupTable]

    # set up scalar bar 
    $Model($m,scalarBar) SetLookupTable $lut
    $Model($m,scalarBar) SetMaximumNumberOfColors [$lut GetNumberOfColors]
    set numlabels [expr [$lut GetNumberOfColors] + 1]
    if {$numlabels > 10} {
    set numlabels 10
    }
    $Model($m,scalarBar) SetNumberOfLabels $numlabels
    
    # add actor (bar) to scene
    viewRen AddActor2D $Model($m,scalarBar)
}


#-------------------------------------------------------------------------------
# .PROC MainModelsRemoveScalarBar
# Kill scalar bar if it is displayed
# .ARGS
# int m model id that should get the bar displayed.  Optional, defaults to idActive.
# .END
#-------------------------------------------------------------------------------
proc MainModelsRemoveScalarBar { {m ""} } {

    global viewWin Model

    if {$m == ""} {
    set m $Model(activeID)
    }

    # if there's a scalar bar, kill it.
    if {[info exists Model($m,scalarBar)] == 1} {

    # remove from vtk and tcl-lands!
    viewRen RemoveActor $Model($m,scalarBar)
    $Model($m,scalarBar) Delete
    set Model($m,displayScalarBar) 0
    unset Model($m,scalarBar)
    }

}

#-------------------------------------------------------------------------------
# .PROC MainModelsToggleScalarBar
# Turn scalar bar on/off depending on current state
# .ARGS
# int m model id that should get the bar displayed.  Optional, defaults to idActive.
# .END
#-------------------------------------------------------------------------------
proc MainModelsToggleScalarBar {m} {
    
    global Model

    if {$Model($m,displayScalarBar) == 0} {
    MainModelsRemoveScalarBar $m
    } else {
    MainModelsRaiseScalarBar $m
    }    
}

#-------------------------------------------------------------------------------
# .PROC MainModelsChangeRenderer
# This is called when the user chooses in which screen (renderer) s/he wants 
# to change the attributes of the models
# 
# str r the name of the renderer
# .END
#-------------------------------------------------------------------------------
proc MainModelsSetRenderer {r} {
    
    global Model
    
    set Model(activeRenderer) $r
    # change the opacity sliders
    foreach m $Model(idList) {
    set opacity [$Model($m,prop,$Model(activeRenderer)) GetOpacity]
    MainModelsSetOpacity $m $opacity
    set scalarvisibility [Model($m,mapper,$Model(activeRenderer)) GetScalarVisibility] 
    MainModelsSetScalarVisibility $m $scalarvisibility
    set backfaceculling [$Model($m,prop,$Model(activeRenderer)) GetBackfaceCulling]
    MainModelsSetCulling $m $backfaceculling
    set visibility  [Model($m,actor,$Model(activeRenderer)) GetVisibility]
    MainModelsSetVisibility $m $visibility
    }
}


