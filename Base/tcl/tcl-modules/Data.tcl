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
# FILE:        Data.tcl
# PROCEDURES:  
#   DataInit
#   DataUpdateMRML
#   DataBuildGUI
#   DataDisplayTree
#   DataPostRightMenu
#   DataGetTypeFromNode
#   DataGetIdFromNode
#   DataClipboardCopy
#   DataClipboardPaste
#   DataCutNode
#   DataDeleteNode
#   DataCopyNode
#   DataPasteNode
#   DataEditNode
#   DataAddModel
#   DataAddMatrix
#   DataAddTransform
#   DataAddVolume
#   DataEnter
#   DataExit
#==========================================================================auto=

#-------------------------------------------------------------------------------
# .PROC DataInit
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DataInit {} {
	global Data Module Path MRMLDefaults

	# Define Tabs
	set m Data
	set Module($m,row1List) "Help List"
	set Module($m,row1Name) "Help List"
	set Module($m,row1,tab) List

	# Define Procedures
	set Module($m,procGUI) DataBuildGUI
	set Module($m,procMRML) DataUpdateMRML
	set Module($m,procEnter) DataEnter
	set Module($m,procExit) DataExit

	# Define Dependencies
	set Module($m,depend) "Events"

	# Set version info
	lappend Module(versions) [ParseCVSInfo $m \
		{$Revision: 1.21 $} {$Date: 2000/02/25 16:26:28 $}]

	set Data(index) ""
	set Data(clipboard) ""
}

#-------------------------------------------------------------------------------
# .PROC DataUpdateMRML
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DataUpdateMRML {} {
	global Gui Model Slice Module Color Volume Label

	# List of nodes
	DataDisplayTree
}

#-------------------------------------------------------------------------------
# .PROC DataBuildGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DataBuildGUI {} {
	global Gui Data Model Slice Module Label

	#-------------------------------------------
	# Frame Hierarchy:
	#-------------------------------------------
	# Help
	# List
	#   Btns
	#   Menu
	#   Title
	#   List
	#-------------------------------------------

	#-------------------------------------------
	# Help frame
	#-------------------------------------------
	set help "
The 3D Slicer can be thought of as a MRML browser.  MRML is the 3D Slicer's 
language for describing 3D scenes of medical data. 
<P>
The <B>List</B> tab 
lists the contents of the MRML file currently being viewed.  To save the 
current file, or open a different one, use the <B>File</B> menu. 
<P>
To view or edit an item's properties, double-click on it's name in the list. 
To copy, delete, or move it, click on it with the right mouse button to 
show a menu of options. 
<BR><B>TIP:</B> Observe the keyboard shortcuts on the menu and use these 
to quickly cut and paste items.

"
	regsub -all "\n" $help { } help
	MainHelpApplyTags Data $help
	MainHelpBuildGUI Data

	#-------------------------------------------
	# List frame
	#-------------------------------------------
	set fList $Module(Data,fList)
	set f $fList

	frame $f.fMenu  -bg $Gui(activeWorkspace)
	frame $f.fBtns  -bg $Gui(activeWorkspace)
	frame $f.fTitle -bg $Gui(activeWorkspace)
	frame $f.fList  -bg $Gui(activeWorkspace)

	pack $f.fBtns $f.fMenu $f.fTitle -side top -padx $Gui(pad) -pady $Gui(pad) 
	pack $f.fList -side top -expand 1 -padx $Gui(pad) -pady $Gui(pad) -fill both

	#-------------------------------------------
	# Images
	#-------------------------------------------

	set Data(imgSave) [image create photo -file \
		[ExpandPath [file join gui save.gif]]]

	set Data(imgOpen) [image create photo -file \
		[ExpandPath [file join gui open.gif]]]

	foreach img "Volume Model" {
		set Data(img${img}Off) [image create photo -file \
			[ExpandPath [file join gui [Uncap $img]Off.ppm]]]
		set Data(img${img}On) [image create photo -file \
			[ExpandPath [file join gui [Uncap $img]On.ppm]]]
	}

	#-------------------------------------------
	# List->Btns frame
	#-------------------------------------------
	set f $fList.fBtns
	
	eval {button $f.bVolume -image $Data(imgVolumeOff) \
		-command "DataAddVolume"} $Gui(WBA)
	set Data(bVolume) $f.bVolume
	bind $Data(bVolume) <Enter> \
		"$Data(bVolume) config -image $Data(imgVolumeOn)"
	bind $Data(bVolume) <Leave> \
		"$Data(bVolume) config -image $Data(imgVolumeOff)"

	eval {button $f.bModel  -image $Data(imgModelOff) \
		-command "DataAddModel"} $Gui(WBA)
	set Data(bModel) $f.bModel
	bind $Data(bModel) <Enter> \
		"$Data(bModel) config -image $Data(imgModelOn)"
	bind $Data(bModel) <Leave> \
		"$Data(bModel) config -image $Data(imgModelOff)"

	pack $f.bVolume $f.bModel -side left -padx $Gui(pad)

	#-------------------------------------------
	# List->Menu frame
	#-------------------------------------------
	set f $fList.fMenu

	eval {button $f.bTransform  -text "Add Transform" \
		-command "DataAddTransform"} $Gui(WBA)
	eval {button $f.bEnd  -text "Add Matrix" \
		-command "DataAddMatrix"} $Gui(WBA)

	pack $f.bTransform $f.bEnd -side left -padx $Gui(pad)

	#-------------------------------------------
	# List->Title frame
	#-------------------------------------------
	set f $fList.fTitle
	
	eval {label $f.lTitle -text "MRML File Contents:"} $Gui(WTA)
	pack $f.lTitle 

	#-------------------------------------------
	# List->List frame
	#-------------------------------------------
	set f $fList.fList

	set Data(fNodeList) [ScrolledListbox $f.list 0 0 -selectmode extended]
	bind $Data(fNodeList) <Button-3>  {DataPostRightMenu %X %Y}
	bind $Data(fNodeList) <Double-1>  {DataEditNode}

	# initialize key-bindings (and hide class Listbox Control button ops)
	set Data(eventMgr) [subst { \
		Listbox,<Control-Button-1>  {} \
		Listbox,<Control-B1-Motion>  {} \
		all,<Control-e> {DataEditNode} \
		all,<Control-x> {DataCutNode} \
		all,<Control-v> {DataPasteNode} \
		all,<Control-d> {DataDeleteNode} }]

#	bind all <Control-c> {DataCopyNode}

	pack $f.list -side top -expand 1 -fill both

	# Menu for right mouse button

	eval {menu $f.list.mRight} $Gui(WMA)
	set Data(rightMenu) $f.list.mRight
	set m $Data(rightMenu)
	set id 0

	set Data(rightMenu,Edit)   $id
	$m add command -label "Edit (Ctrl+e)" -command "DataEditNode"
	incr id
	set Data(rightMenu,Cut)    $id
	$m add command -label "Cut (Ctrl+x)" -command "DataCutNode"
	incr id
#	set Data(rightMenu,Copy)   $id
#	$m add command -label "Copy (Ctrl+c)" -command "DataCopyNode"
#	incr id
	set Data(rightMenu,Paste)  $id
	$m add command -label "Paste (Ctrl+v)" -command "DataPasteNode" \
		-state disabled
	incr id
	set Data(rightMenu,Delete)  $id
	$m add command -label "Delete (Ctrl+d)" -command "DataDeleteNode"
	$m add command -label "-- Close Menu --" -command "$Data(rightMenu) unpost"

}

#-------------------------------------------------------------------------------
# .PROC DataDisplayTree
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DataDisplayTree {{index end}} {
	global Data

	# Clear old
	$Data(fNodeList) delete 0 end

	# Insert new
	set depth 0
    set tree Mrml(dataTree)
	$tree InitTraversal
    set node [$tree GetNextItem]
    while {$node != ""} {

		set class [$node GetClassName]

		# Add node-dependent descriptions
		switch $class {
			vtkMrmlModelNode {
				set desc [$node GetDescription]
				set name [$node GetName]
				if {$desc == ""} {
					set desc [file root [file tail [$node GetFileName]]]
				}
				if {$name == ""} {set name $desc}
				set line "Model: $name"
			}
			vtkMrmlVolumeNode {
				set desc [$node GetDescription]
				set name [$node GetName]
				if {$desc == ""} {
					set desc [file root [file tail [$node GetFilePrefix]]]
				}
				if {$name == ""} {set name $desc}
				if {[$node GetLabelMap] == "1"} {
					set line "Label: $name"
				} else {	
					set line "Volume: $name"
				}
			}
			vtkMrmlColorNode {
				set desc [$node GetDescription]
				set name [$node GetName]
				if {$name == ""} {set name $desc}
				if {$desc == ""} {
					set desc [$node GetDiffuseColor]
				}
				set line "Color: $name"
			}
			vtkMrmlMatrixNode {
				set desc [$node GetDescription]
				set name [$node GetName]
				if {$name == ""} {set name $desc}
				set line "Matrix: $name"
			}
			vtkMrmlTransformNode {
				set line "Transform"
			}
			vtkMrmlEndTransformNode {
				set line "EndTransform"
			}
			vtkMrmlOptionsNode {
				set name [$node GetContents]
				set line "Options: $name"
			}
		}
		
		if {$class == "vtkMrmlEndTransformNode"} {
			set depth [expr $depth - 1]
		}

		set tabs ""
		for {set i 0} {$i < $depth} {incr i} {
			set tabs "${tabs}   "
		}
		$Data(fNodeList) insert end ${tabs}$line

		if {$class == "vtkMrmlTransformNode"} {
			incr depth
		}

		# Traverse
        set node [$tree GetNextItem]
	}
	if {$index == ""} {
		set index "end"
	}
	$Data(fNodeList) selection set $index $index
}

#-------------------------------------------------------------------------------
# .PROC DataPostRightMenu
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DataPostRightMenu {x y} {
	global Data Gui

	# Get selection from listbox
	set index [$Data(fNodeList) curselection]

	# If no selection, then disable certain menu entries
	set m $Data(rightMenu)
	if {$index == ""} {
		foreach entry "Cut Edit Delete" {
			$m entryconfigure $Data(rightMenu,$entry) -state disabled
		}
	} else {
		foreach entry "Cut Edit Delete" {
			$m entryconfigure $Data(rightMenu,$entry) -state normal
		}
	}

	# Show menu
	$m post $x $y
}

#-------------------------------------------------------------------------------
# .PROC DataGetTypeFromNode
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DataGetTypeFromNode {node} {

	if {[regexp {(.*)\((.*),} $node match nodeType id] == 0} {
		tk_messageBox -message "Ooops! node='$node'"
		return ""
	}
	return $nodeType
}

#-------------------------------------------------------------------------------
# .PROC DataGetIdFromNode
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DataGetIdFromNode {node} {

	if {[regexp {(.*)\((.*),} $node match nodeType id] == 0} {
		tk_messageBox -message "Ooops!"
		return ""
	}
	return $id
}

#-------------------------------------------------------------------------------
# .PROC DataClipboardCopy
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DataClipboardCopy {nodes} {
	global Data Mrml Volume Model Transform EndTransform Matrix Options
        global Color 
	
	# If the clipboard already has a node(s), delete it
	if {$Data(clipboard) != ""} {
	    foreach node $Data(clipboard) {
			set nodeType [DataGetTypeFromNode $node]
			set id [DataGetIdFromNode $node]
			
			# For the next line to work, Volume, Model, etc need to
			# be on the "global" line of this procedure
			MainMrmlDeleteNode $nodeType $id
			RenderAll
	    }
	}

	# Copy the node(s) to the clipboard
	set Data(clipboard) $nodes
	
	# Enable paste
	$Data(rightMenu) entryconfigure $Data(rightMenu,Paste) -state normal
}

#-------------------------------------------------------------------------------
# .PROC DataClipboardPaste
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DataClipboardPaste {} {
	global Data Mrml
	
	set newNodes $Data(clipboard)
	set Data(clipboard) ""
	$Data(rightMenu) entryconfigure $Data(rightMenu,Paste) -state disabled

	return $newNodes
}

#-------------------------------------------------------------------------------
# .PROC DataCutNode
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DataCutNode {} {
    global Data Mrml
    
    # Get the index of selected node(s)
    set selection [$Data(fNodeList) curselection]
    if {$selection == ""} {return}
 
    # If Transform selected, remove whole thing. Ignore End Tr. if unmatched.
    set remove [DataCheckSelectedTransforms $selection \
	    [$Data(fNodeList) index end]]
    if {$remove == ""} {return}

    # Identify node(s)
    foreach node $remove {
	lappend nodes [Mrml(dataTree) GetNthItem $node]
    }

    # Remove node(s) from the MRML tree
    foreach node $nodes {
	Mrml(dataTree) RemoveItem $node 
    }
	
    # Copy to clipboard
    DataClipboardCopy $nodes
    
    MainUpdateMRML
}

#-------------------------------------------------------------------------------
# .PROC DataDeleteNode
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DataDeleteNode {} {
    global Data Mrml Volume Model Transform EndTransform Matrix Color Options
    
    # Get the index of selected node(s)
    set selection [$Data(fNodeList) curselection]
    if {$selection == ""} {return}

    # If Transform selected, remove whole thing. Ignore End Tr. if unmatched.
    set remove [DataCheckSelectedTransforms $selection \
	    [$Data(fNodeList) index end]]
    if {$remove == ""} {return}
    
    # Identify node(s)
    foreach node $remove {
	lappend nodes [Mrml(dataTree) GetNthItem $node]
    }
    
    foreach node $nodes {
	# Delete
	set nodeType [DataGetTypeFromNode $node]
	set id [DataGetIdFromNode $node]
	# For the next line to work, Volume, Model, etc need to
	# be on the "global" line of this procedure
	MainMrmlDeleteNode $nodeType $id
    }
    
    RenderAll
}

#-------------------------------------------------------------------------------
# .PROC DataCopyNode
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DataCopyNode {} {
	global Data Mrml

	# Get the index of selected node(s)
	set selection [$Data(fNodeList) curselection]
	if {$selection == ""} {return}

	# Identify node(s)
	foreach node $selection {
	    lappend nodes [Mrml(dataTree) GetNthItem $node]
	}
	# Copy to clipboard
	DataClipboardCopy $nodes

}

#-------------------------------------------------------------------------------
# .PROC DataPasteNode
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DataPasteNode {} {
	global Data Mrml

	# If there's nothing to paste, do nichts
	if {$Data(clipboard) == ""} {
		return
	}

	# Empty list is a special case
	if {[$Data(fNodeList) index end] == 0} {
	    foreach node [DataClipboardPaste] {	
		Mrml(dataTree) AddItem $node 
	    }
	    MainUpdateMRML
	    return
	}

	# Get the index of selected node(s)
	set selection [$Data(fNodeList) curselection]

	if {$selection == ""} {
	    tk_messageBox -message "First select an item to paste after."
		return
	}
	
	# Find the last selected node to paste after
	set last [expr [llength $selection] - 1]
	set lastSel [Mrml(dataTree) GetNthItem [lindex $selection $last]]

	
	# Paste from clipboard
	set newNodes [DataClipboardPaste]
	
	# Figure out which item each node should be pasted after
	set prevNodes "$lastSel [lrange $newNodes 0 [expr \
		[llength $newNodes] - 2]]"

	# Insert into MRML tree after the last selected node
	foreach node $newNodes prev $prevNodes {
	    Mrml(dataTree) InsertAfterItem $prev $node
	}

	MainUpdateMRML
}

#-------------------------------------------------------------------------------
# .PROC DataEditNode
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DataEditNode {} {
	global Data Mrml Model

	# Get the selected node
	set selection [$Data(fNodeList) curselection]

	# Edit only one node
	if {[llength $selection] != 1} {
	    tk_messageBox -message "Please select only one node to edit."
	    return
	}

	set node [Mrml(dataTree) GetNthItem $selection]

	set class [$node GetClassName]
	switch $class {
	"vtkMrmlVolumeNode" {
		set id [DataGetIdFromNode $node]
		MainVolumesSetActive $id
		if {[IsModule Volumes] == 1} {
			Tab Volumes row1 Display
		}
	}
	"vtkMrmlModelNode" {
		set id [DataGetIdFromNode $node]
		MainModelsSetActive $id
		if {[IsModule Models] == 1} {
			set Model(propertyType) Basic
			Tab Models row1 Props
		}
	}
	"vtkMrmlMatrixNode" {
		set id [DataGetIdFromNode $node]
		MainMatricesSetActive $id
		if {[IsModule Matrices] == 1} {
			Tab Matrices row1 Manual
		}
	}
	"vtkMrmlOptionsNode" {
		set id [DataGetIdFromNode $node]
		MainOptionsSetActive $id
		if {[IsModule Options] == 1} {
			Tab Options row1 Props
		}
	}
	}
}

#-------------------------------------------------------------------------------
# .PROC DataAddModel
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DataAddModel {} {
	global Model Module

	if {[IsModule Models] == 1} {
		set Model(propertyType) Basic
		ModelsSetPropertyType
		MainModelsSetActive NEW
		set Model(freeze) 1
		Tab Models row1 Props
		set Module(freezer) "Data row1 List"
	}
}

#-------------------------------------------------------------------------------
# .PROC DataAddMatrix
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DataAddMatrix {} {
	global Matrix Module

	if {[IsModule Matrices] == 1} {
		set Matrix(propertyType) Basic
		MatricesSetPropertyType
		MainMatricesSetActive NEW
		set Matrix(freeze) 1
		Tab Matrices row1 Props
		set Module(freezer) "Data row1 List"
	}
}

#-------------------------------------------------------------------------------
# .PROC DataAddTransform
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DataAddTransform {} {
    global Transform Matrix EndTransform Data

    # Add Transform, Matrix, EndTransform

    # Lauren fix this (vtk function to paste before since 1st sel can be 1st node)
    
    # Transform will enclose selected nodes
    set selection [$Data(fNodeList) curselection]

    # Check that transform will only enclose transform-end transform pairs.
    set numTrans [DataCountTransforms $selection]
    
    # Empty list, no selection, or partial transform in selection: put Transform at end	
    if {[$Data(fNodeList) index end] == 0 || $selection == "" || [lindex $selection 0] == 0 || $numTrans != 0} {
	set append 1
    } else {
	set append 0
	# Paste before first selected node: fix if it is the first node
	set firstSel [Mrml(dataTree) GetNthItem [expr [lindex $selection 0] - 1]]
	set last [expr [llength $selection] - 1]
	set lastSel [Mrml(dataTree) GetNthItem [lindex $selection $last]]
	puts "$firstSel $lastSel"
    }
    
    
    # Transform
    set i $Transform(nextID)
    incr Transform(nextID)
    lappend Transform(idList) $i
    vtkMrmlTransformNode Transform($i,node)
    set n Transform($i,node)
    $n SetID $i
    if {$append == 1} {
	Mrml(dataTree) AddItem $n
    } else {
	Mrml(dataTree) InsertAfterItem $firstSel $n
    }
# for now: later, use InsertBefore for matrix and don't need to save transform
    set t $n

    # Matrix
    set i $Matrix(nextID)
    incr Matrix(nextID)
    lappend Matrix(idList) $i
    vtkMrmlMatrixNode Matrix($i,node)
    set n Matrix($i,node)
    $n SetID $i
    $n SetName manual
# for now: later, use InsertBefore.
    Mrml(dataTree) InsertAfterItem $t $n
    MainMatricesSetActive $i

    # EndTransform
    set i $EndTransform(nextID)
    incr EndTransform(nextID)
    lappend EndTransform(idList) $i
    vtkMrmlEndTransformNode EndTransform($i,node)
    set n EndTransform($i,node)
    $n SetID $i
    if {$append == 1} {
	Mrml(dataTree) AddItem $n
    } else {
	Mrml(dataTree) InsertAfterItem $lastSel $n
    }

    MainUpdateMRML

}


#-------------------------------------------------------------------------------
# .PROC DataAddVolume
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DataAddVolume {} {
	global Volume Module

	if {[IsModule Volumes] == 1} {
		set Volume(propertyType) Basic
		VolumesSetPropertyType
		MainVolumesSetActive NEW
		set Volume(freeze) 1
		Tab Volumes row1 Props
		set Module(freezer) "Data row1 List"
	}
}

# Returns the number of open transforms in the selected area
proc DataCountTransforms {selection {start ""} {end ""}} {
    global Mrml
    
    set T "0"
    foreach line $selection {
	set node [Mrml(dataTree) GetNthItem $line]
	set class [$node GetClassName]
	switch $class {
	    vtkMrmlTransformNode {
		incr T
	    }
	    vtkMrmlEndTransformNode {
		incr T -1
	    } 
	}
    }
    return $T
}

# If partial Transform nodes were in selection, find the rest of the node 
# and add it to the selection.  Else if unmatched End Transform nodes were 
# selected, remove them from the selection.
proc DataCheckSelectedTransforms {selection lastItem} {
    global Mrml

    set numTrans [DataCountTransforms $selection]

    # Return if the selection contains only matching T-ET pairs
    if {$numTrans == 0} {
	return $selection
    }

    # If open Transforms are in selection ($numTrans>0), find the rest of 
    # their contents.
    if {$numTrans > 0} {
	set TList ""
	set line [lindex $selection end]
	incr line

	# T is the number of nested transforms we are inside; numTrans is the 
	# number of transforms whose contents we want to find.
	set T $numTrans
	
	while {$T > 0 && $line < $lastItem} {
	    set node [Mrml(dataTree) GetNthItem $line]
	    set class [$node GetClassName]
	    switch $class {
		vtkMrmlTransformNode {
		    incr T
		}
		vtkMrmlMatrixNode {
		    if {$T <= $numTrans} {
			lappend TList $line
		    }
		}
		vtkMrmlEndTransformNode {
		    if {$T <= $numTrans} {
			lappend TList $line
		    }
		    incr T -1
		}
	    }
	    # Get the next line
	    incr line
	}
	
	# Add the transform contents to the selection
	return [concat $selection $TList]
    }

    # If there are unmatched End Transform tags ($numTrans<0), remove them 
    # from the selection.
    set ETList ""
    set line [lindex $selection 0]
    set lastSel [lindex $selection end]
    # number of open transforms above selection: find ETs that match them
    set numOpenTrans [expr  - $numTrans]
    # T is the number of nested transforms we are inside
    set T $numOpenTrans
    
    while {$T > 0 && $line <= $lastSel} {
	set node [Mrml(dataTree) GetNthItem $line]
	set class [$node GetClassName]
	switch $class {
	    vtkMrmlTransformNode {
		incr T
	    }
	    vtkMrmlEndTransformNode {
		if {$T <= $numOpenTrans} {
		    lappend ETList $line
		}
		incr T -1
	    }
	}
	# Get the next line
	incr line
    }

    #Remove items we are saving from the selection
    foreach item $ETList {
	set index [lsearch -exact $selection $item]
	set selection [lreplace $selection $index $index]
    }
    return $selection
}


#-------------------------------------------------------------------------------
# .PROC DataEnter
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DataEnter {} { 
    global Data

    array set mgr $Data(eventMgr)
    pushEventManager mgr

}

#-------------------------------------------------------------------------------
# .PROC DataExit
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DataExit {} {

    popEventManager
}