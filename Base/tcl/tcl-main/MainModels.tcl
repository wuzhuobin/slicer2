#=auto==========================================================================
# Copyright (c) 1999 Surgical Planning Lab, Brigham and Women's Hospital
#  
# Direct all questions regarding this copyright to slicer@ai.mit.edu.
# The following terms apply to all files associated with the software unless
# explicitly disclaimed in individual files.   
# 
# The authors hereby grant permission to use, copy, (but NOT distribute) this
# software and its documentation for any NON-COMMERCIAL purpose, provided
# that existing copyright notices are retained verbatim in all copies.
# The authors grant permission to modify this software and its documentation 
# for any NON-COMMERCIAL purpose, provided that such modifications are not 
# distributed without the explicit consent of the authors and that existing
# copyright notices are retained in all copies. Some of the algorithms
# implemented by this software are patented, observe all applicable patent law.
# 
# IN NO EVENT SHALL THE AUTHORS OR DISTRIBUTORS BE LIABLE TO ANY PARTY FOR
# DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
# OF THE USE OF THIS SOFTWARE, ITS DOCUMENTATION, OR ANY DERIVATIVES THEREOF,
# EVEN IF THE AUTHORS HAVE BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# 
# THE AUTHORS AND DISTRIBUTORS SPECIFICALLY DISCLAIM ANY WARRANTIES, INCLUDING,
# BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
# PARTICULAR PURPOSE, AND NON-INFRINGEMENT.  THIS SOFTWARE IS PROVIDED ON AN
# 'AS IS' BASIS, AND THE AUTHORS AND DISTRIBUTORS HAVE NO OBLIGATION TO PROVIDE
# MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
#===============================================================================
# FILE:        MainModels.tcl
# DATE:        01/20/2000 09:40
# LAST EDITOR: gering
# PROCEDURES:  
#   MainModelsInit
#   MainModelsUpdateMRML
#   MainModelsShouldBeAVtkClass
#   MainModelsCreate
#   MainModelsRead
#   MainModelsCreateUnreadable
#   MainModelsInitGUIVariables
#   MainModelsDelete
#   MainModelsBuildGUI
#   MainModelsCreateGUI
#   MainModelsPopupCallback
#   MainModelsDeleteGUI
#   MainModelsPopup
#   MainModelsSetActive
#   MainModelsSetColor
#   MainModelsSetVisibility
#   MainModelsRefreshClip
#   MainModelsSetClip
#   MainModelsSetOpacity
#   MainModelsSetCulling
#   MainModelsSetScalarVisibility
#   MainModelsRegisterModel
#   MainModelsWrite
#==========================================================================auto=

#-------------------------------------------------------------------------------
# .PROC MainModelsInit
# .END
#-------------------------------------------------------------------------------
proc MainModelsInit {} {
	global Model Module

	# This proc is called specifically
	# lappend Module(procGUI)  MainModelsBuildGUI

	set Model(idNone) -1
	set Model(activeID) ""
	set Model(freeze) ""

	# Append widgets to list that gets refreshed during UpdateMRML
	set Model(mbActiveList) ""
	set Model(mActiveList)  ""

}

#-------------------------------------------------------------------------------
# .PROC MainModelsUpdateMRML
# .END
#-------------------------------------------------------------------------------
proc MainModelsUpdateMRML {} {
	global Model Gui Module Color

	# Build any new models
	#--------------------------------------------------------
	foreach m $Model(idList) {
		if {[MainModelsCreate $m] >= 0} {
			# Success, so Build GUI
			MainModelsCreateGUI $Gui(wModels).fGrid $m
		} else {
			MainMrmlDeleteNodeDuringUpdate Model $m
		}
	}

	# Delete any old models
	#--------------------------------------------------------
	foreach m $Model(idListDelete) {
		if {[MainModelsDelete $m] == 1} {
			# Success, so delete GUI
			MainModelsDeleteGUI $Gui(wModels).fGrid $m
		}
	}
	# Did we delete the active model?
	if {[lsearch $Model(idList) $Model(activeID)] == -1} {
		MainModelsSetActive [lindex $Model(idList) 0]
	}

	# Refresh Actor and GUI (in case color changed)
	#--------------------------------------------------------
	foreach m $Model(idList) {

		MainModelsSetClip $m
		MainModelsSetColor $m
		MainModelsSetCulling $m
		MainModelsSetVisibility $m
		MainModelsSetScalarVisibility $m
		MainModelsSetOpacity $m
		eval Model($m,mapper) SetScalarRange [Model($m,node) GetScalarRange]

		# Color slider
		set c $Model($m,colorID)
		$Gui(wModels).fGrid.s$m config \
			-troughcolor [MakeColorNormalized [Color($c,node) GetDiffuseColor]]
	}

	# Form the menus 
	#--------------------------------------------------------
	set Model(idListForMenu) $Model(idList)

	# Active Model menu
	foreach menu $Model(mActiveList) {
		$menu delete 0 end
		foreach m $Model(idListForMenu) {
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
# recompiling C++ code.  
#
# This procedure performs what the vtkMrmlModel would do in its constructor.
# 
# .END
#-------------------------------------------------------------------------------
proc MainModelsShouldBeAVtkClass {m} {
	global Model Slice

	# Clipper
	vtkClipPolyData Model($m,clipper)
	Model($m,clipper) SetClipFunction Slice(clipPlanes)
	Model($m,clipper) SetValue 0.0

	# Mapper
	vtkPolyDataMapper Model($m,mapper)

	# Actor
	vtkActor Model($m,actor)
	Model($m,actor) SetMapper Model($m,mapper)

	# Registration
	vtkMatrix4x4 Model($m,rasToWld)
	Model($m,actor) SetUserMatrix [Model($m,node) GetRasToWld]

	# Property
	set Model($m,prop)  [Model($m,actor) GetProperty]

	# For now, the back face color is the same
	Model($m,actor) SetBackfaceProperty $Model($m,prop)
}

#-------------------------------------------------------------------------------
# .PROC MainModelsCreate
#
# This procedure creates a model that was read in from a MRML file.
# To create a model on the fly (such as after segmenting a label map),
# call MainModelsCreateUnreadable
# 
# Returns:
#  1 - success
#  0 - model already exists
# -1 - can't open file
# .END
#-------------------------------------------------------------------------------
proc MainModelsCreate {m} {
    global Model View Slice Gui

	# See if it already exists
	if {[info command Model($m,actor)] != ""} {
		return 0
	}

	MainModelsShouldBeAVtkClass	$m	
	MainModelsInitGUIVariables $m

	# Read it in from disk
	set status [MainModelsRead $m]
	if {$status != 0} {
		return $status
	}

	# Need to call this before MainModelsCreateGUI so the
	# variable Model($m,colorID) is created and valid
	MainModelsSetColor $m

	viewRen AddActor Model($m,actor)

	return 1
}

#-------------------------------------------------------------------------------
# .PROC MainModelsRead
# .END
#-------------------------------------------------------------------------------
proc MainModelsRead {m} {
	global Model Gui

	# If fileName = "", then do nothing
	set fileName [Model($m,node) GetFullFileName]
	if {$fileName == ""} {return}

	# Check fileName
	if {[CheckFileExists $fileName 0] == 0} {
		set str "Cannot read model: '$fileName'"
		puts $str
		tk_messageBox -message $str
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
	}

	# Progress Reporting
	reader SetStartMethod     MainStartProgress
	reader SetProgressMethod "MainShowProgress reader"
	reader SetEndMethod       MainEndProgress

	# Read it in now
	set Gui(progressText) "Reading $name"
	puts "Reading model $name..."
    [reader GetOutput] ReleaseDataFlagOn

	# Delete the reader, leaving the data in Model($m,polyData)
	# polyData will survive as long as it's the input to the mapper
	#
	set Model($m,polyData) [reader GetOutput]
	$Model($m,polyData) Update
	Model($m,mapper) SetInput $Model($m,polyData)

	reader SetOutput ""
	reader Delete

	# Mark this model as saved
	set Model($m,dirty) 0

	return 0
}

#-------------------------------------------------------------------------------
# .PROC MainModelsCreateUnreadable
# Call this routine instead of MainModelsCreate to add a model on the fly.
# .END
#-------------------------------------------------------------------------------
proc MainModelsCreateUnreadable {} {
	global Volume Model View Gui Module

	# DAVE: Ignore adding it to the MRML tree for now
	
	# Find the next available ID
	set m $Model(nextID)
	
	# MRML node
	vtkMrmlModelNode Model($m,node)

	MainModelsShouldBeAVtkClass	$m
	MainModelsInitGUIVariables $m

	# Create a thing
	vtkSphereSource src
	src SetRadius 10
	
	# Delete the src, leaving the data in Model($m,polyData)
	# polyData will survive as long as it's the input to the mapper
	set Model($m,polyData) [src GetOutput]
	$Model($m,polyData) Update
	Model($m,mapper) SetInput $Model($m,polyData)
	src SetOutput ""
	src Delete

	# Need to call this before MainModelsCreateGUI so the
	# variable Model($m,colorID) created and valid
	MainModelsSetColor $m

	viewRen AddActor Model($m,actor)

	# Assign an ID
	set Model($m,id) $m
	incr Model(nextID)
	lappend Model(idList) $m
	set Model(num) [llength $Model(idList)]

	# Mark this model as unsaved
	set Model($m,dirty) 1

	return $m
}

#-------------------------------------------------------------------------------
# .PROC MainModelsInitGUIVariables
# .END
#-------------------------------------------------------------------------------
proc MainModelsInitGUIVariables {m} {
	global Model

	set Model($m,visibility)       [Model($m,node) GetVisibility]
	set Model($m,opacity)          [Model($m,node) GetOpacity]
	set Model($m,scalarVisibility) [Model($m,node) GetScalarVisibility]
	set Model($m,backfaceCulling)  [Model($m,node) GetBackfaceCulling]
	set Model($m,clipping)         [Model($m,node) GetClipping]
}

#-------------------------------------------------------------------------------
# .PROC MainModelsDelete
# If you want a model to be history, this is the procedure you call.
# .END
#-------------------------------------------------------------------------------
proc MainModelsDelete {m} {
	global Model View Gui Dag Module

	# If we've already deleted this one, then do nothing
	if {[info command Model($m,actor)] == ""} {
		return 0
	}

	# Remove actors from renderers
	viewRen RemoveActor Model($m,actor)

	# Delete VTK objects (and remove commands from TCL namespace)
	Model($m,clipper) Delete
	Model($m,mapper) Delete
	Model($m,actor) Delete
	Model($m,rasToWld) Delete
	# The polyData should be gone from reference counting, but I'll make sure:
	catch {Model($m,polyData) Delete}

	# Delete all TCL variables of the form: Model($m,<whatever>)
	foreach name [array names Model] {
		if {[string first "$m," $name] == 0} {
			unset Model($name)
		}
	}

	# Delete ID from array
	set i [lsearch $Model(idList) $m]
	set Model(idList) [lreplace $Model(idList) $i $i]

	# Delete node from dag

	return 1
}

#-------------------------------------------------------------------------------
# .PROC MainModelsBuildGUI
#
# Builds a popup GUI
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
    wm transient $w .
	wm withdraw $w

	# Close button
	set c {button $w.bClose -text "Close" \
		-command "wm withdraw $w" $Gui(WBA)}
		eval [subst $c]

	# Frames
	frame $w.fGrid -bg $Gui(activeWorkspace)
	frame $w.fAll -bg $Gui(activeWorkspace)
	pack $w.fGrid $w.fAll $w.bClose -side top -pady $Gui(pad)

	#-------------------------------------------
	# Models->All frame
	#-------------------------------------------
	set f $w.fAll
	set c {button $f.bAll -text "Show All" -width 10 \
		-command "MainModelsSetVisibility All" $Gui(WBA)}; eval [subst $c]
	set c {button $f.bNone -text "Show None" -width 10 \
		-command "MainModelsSetVisibility None" $Gui(WBA)}; eval [subst $c]
	pack $f.bAll $f.bNone -side left -padx $Gui(pad) -pady 0

	#-------------------------------------------
	# Models->Grid frame
	#-------------------------------------------
	# Done in MainModelsCreateGUI
}

#-------------------------------------------------------------------------------
# .PROC MainModelsCreateGUI
# .END
#-------------------------------------------------------------------------------
proc MainModelsCreateGUI {f m} {
	global Gui Model Color

	# If the GUI already exists, then just change name.
	if {[info command $f.c$m] != ""} {
		$f.c$m config -text "[Model($m,node) GetName]"
		return
	}

	# Name / Visible
	eval {checkbutton $f.c$m \
		-text [Model($m,node) GetName] -variable Model($m,visibility) \
		-width 17 -indicatoron 0 \
		-command "MainModelsSetVisibility $m; Render3D"} $Gui(WCA)

	# menu
	set c {menu $f.c$m.men $Gui(WMA)}; eval [subst $c]
	set men $f.c$m.men
	$men add command -label "Change Color..." -command \
		"MainModelsSetActive $m; ShowColors MainModelsPopupCallback"
	$men add check -label "Clipping" \
		-variable Model($m,clipping) \
		-command "MainModelsSetClip $m; Render3D"
	$men add check -label "Backface culling" \
		-variable Model($m,backfaceCulling) \
		-command "MainModelsSetCulling $m; Render3D"
	$men add check -label "Scalar Visibility" \
		-variable Model($m,scalarVisibility) \
		-command "MainModelsSetScalarVisibility $m; Render3D"
	$men add command -label "Delete Model" -command "MainMrmlDeleteNode Model $m; Render3D"
	$men add command -label "-- Close Menu --" -command "$men unpost"
	bind $f.c$m <Button-3> "$men post %X %Y"

	# Opacity
	set c {entry $f.e${m} -textvariable Model($m,opacity) \
		-width 3 $Gui(WEA)}; eval [subst $c]
	bind $f.e${m} <Return> "MainModelsSetOpacity $m; Render3D"
	bind $f.e${m} <FocusOut> "MainModelsSetOpacity $m; Render3D"
	set c {scale $f.s${m} -from 0.0 -to 1.0 -length 50 \
		-variable Model($m,opacity) \
		-command "MainModelsSetOpacity $m; Render3D" \
		-resolution 0.1 $Gui(WSA) -sliderlength 14 \
		-troughcolor [MakeColorNormalized \
			[Color($Model($m,colorID),node) GetDiffuseColor]]}
		eval [subst $c]

	# Clipping
	set c {checkbutton $f.cClip${m} \
		-variable Model($m,clipping) \
		-command "MainModelsSetClip $m; Render3D" $Gui(WCA) -indicatoron 1}
		eval [subst $c]

	grid $f.c${m} $f.e${m} $f.s${m} $f.cClip$m -pady 2 -padx 2
}

#-------------------------------------------------------------------------------
# .PROC MainModelsPopupCallback
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
# .END
#-------------------------------------------------------------------------------
proc MainModelsDeleteGUI {f m} {
	global Gui Model Color

	# If the GUI already deleted, return
	if {[info command $f.c$m] == ""} {
		return
	}

	# Destroy TK widgets
	destroy $f.c$m
	destroy $f.e$m
	destroy $f.s$m
	destroy $f.cClip$m
}

#-------------------------------------------------------------------------------
# .PROC MainModelsPopup
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
		set Model(prefix)           [file root [default GetFileName]]
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
		set Model(prefix)           [file root [Model($m,node) GetFileName]]
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
# .END
#-------------------------------------------------------------------------------
proc MainModelsSetColor {m {name ""}} {
	global Model Color Gui

	if {$name == ""} {
		set name [Model($m,node) GetColor]
	} else {
		Model($m,node) SetColor $name
	}

	# Use first color by default
	set Model($m,colorID) [lindex $Color(idList) 0]
	foreach c $Color(idList) {
		if {[Color($c,node) GetName] == $name} {
			set Model($m,colorID) $c
		}
	}
	set c $Model($m,colorID)

	$Model($m,prop) SetAmbient       [Color($c,node) GetAmbient]
	$Model($m,prop) SetDiffuse       [Color($c,node) GetDiffuse]
	$Model($m,prop) SetSpecular      [Color($c,node) GetSpecular]
	$Model($m,prop) SetSpecularPower [Color($c,node) GetPower]
	eval $Model($m,prop) SetColor    [Color($c,node) GetDiffuseColor]
}

#-------------------------------------------------------------------------------
# .PROC MainModelsSetVisibility
# .END
#-------------------------------------------------------------------------------
proc MainModelsSetVisibility {model {value ""}} {
	global Model

	if {[string compare $model "None"] == 0} {
		foreach m $Model(idList) {
			set Model($m,visibility) 0
			Model($m,node)  SetVisibility 0
			Model($m,actor) SetVisibility [Model($m,node) GetVisibility] 
		}
	} elseif {[string compare $model "All"] == 0} {
		foreach m $Model(idList) {
			set Model($m,visibility) 1
			Model($m,node)  SetVisibility 1 
			Model($m,actor) SetVisibility [Model($m,node) GetVisibility] 
		}
	} else {
		if {$model == ""} {return}
		set m $model
		if {$value != ""} {
			set Model($m,visibility) $value
		}
		Model($m,node)  SetVisibility $Model($m,visibility)
		Model($m,actor) SetVisibility [Model($m,node) GetVisibility] 
	}
}

#-------------------------------------------------------------------------------
# .PROC MainModelsRefreshClip
# .END
#-------------------------------------------------------------------------------
proc MainModelsRefreshClip {} {
	global Model Slice

	# If no functions are added, then don't clip
	foreach m $Model(idList) {
		MainModelsSetClip $m
	}
}

#-------------------------------------------------------------------------------
# .PROC MainModelsSetClip
# .END
#-------------------------------------------------------------------------------
proc MainModelsSetClip {m} {
	global Model Slice

	if {$m == ""} {return}
		
	set union 0
	foreach s $Slice(idList) {
		set union [expr $union + $Slice($s,addedFunction)]
	}

	# Automatically turn backface culling OFF during clipping

	# Clip
	if {$Model($m,clipping) == 1 && $union > 0} {
		# polyData --> clipper --> mapper
		Model($m,clipper) SetInput $Model($m,polyData)
		Model($m,mapper) SetInput [Model($m,clipper) GetOutput]

		set Model($m,oldCulling) [Model($m,node) GetBackfaceCulling]
		MainModelsSetCulling $m 0
	
	# No clip
	} else {
		# polyData --> mapper
		# The order of the next 2 line is important.  If you are clipping and
		# you set input of the clipper to "" (NULL), then the polyData's
		# reference count is decremented.  This will cause the polyData to be
		# deleted unless you first increment its reference count by setting
		# to be the mapper's input.
		Model($m,mapper) SetInput $Model($m,polyData)
		Model($m,clipper) SetInput ""

		if {[info exists Model($m,oldCulling)] == 1} {
			MainModelsSetCulling $m $Model($m,oldCulling)
		}
	}
}

#-------------------------------------------------------------------------------
# .PROC MainModelsSetOpacity
# .END
#-------------------------------------------------------------------------------
proc MainModelsSetOpacity {m {value ""}} {
	global Model

        if {$value != ""} {
	    if {[ValidateFloat $value] == 1 && $value >= 0.0 \
		    && $value <= 1.0} {
		set Model($m,opacity) $value
	    }
	}
	Model($m,node) SetOpacity $Model($m,opacity)
	$Model($m,prop) SetOpacity [Model($m,node) GetOpacity]
}

#-------------------------------------------------------------------------------
# .PROC MainModelsSetCulling
# .END
#-------------------------------------------------------------------------------
proc MainModelsSetCulling {m {value ""}} {
	global Model

	if {$value != ""} {
		set Model($m,backfaceCulling) $value
	}
	Model($m,node) SetBackfaceCulling $Model($m,backfaceCulling)
	$Model($m,prop) SetBackfaceCulling \
		[Model($m,node) GetBackfaceCulling]

	# If this is the active model, update GUI
	if {$m == $Model(activeID)} {
		set Model(culling) $Model($m,backfaceCulling)
	}
}
 
#-------------------------------------------------------------------------------
# .PROC MainModelsSetScalarVisibility
# .END
#-------------------------------------------------------------------------------
proc MainModelsSetScalarVisibility {m {value ""}} {
	global Model
		
	if {$value != ""} {
		set Model($m,scalarVisibility) $value
	}
	Model($m,node) SetScalarVisibility $Model($m,scalarVisibility)
	Model($m,mapper) SetScalarVisibility \
		[Model($m,node) GetScalarVisibility]

	# If this is the active model, update GUI
	if {$m == $Model(activeID)} {
		set Model(scalarVisibility) $Model($m,backfaceCulling)
	}
}
 
proc MainModelsSetScalarRange {m lo hi} {
	global Model
		
	Model($m,node)   SetScalarRange $lo $hi
	Model($m,mapper) SetScalarRange $lo $hi

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

	Model($m,node) SetFileName "$prefix.vtk"
	Model($m,node) SetFullFileName \
		[file join $Mrml(dir) [Model($m,node) GetFileName]]

	vtkPolyDataWriter writer
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

