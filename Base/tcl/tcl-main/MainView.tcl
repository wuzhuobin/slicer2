#=auto==========================================================================
# Copyright (c) 2000 Surgical Planning Lab, Brigham and Women's Hospital
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
# FILE:        MainView.tcl
# PROCEDURES:  
#   MainViewInit
#   MainViewBuildVTK
#   MainViewBuildGUI
#   MainViewSetBackgroundColor
#   MainViewSetFov
#   MainViewLightFollowCamera
#   MainViewNavReset
#   MainViewRotate
#   MainViewNavRotate
#   MainViewSetStereo
#   MainViewSpin
#   MainViewSetWelcome
#   MainViewResetFocalPoint
#   MainViewSetFocalPoint
#   MainViewSaveView
#   MainViewSaveViewPopup
#   MainViewWriteView
#   MainViewStorePresets
#==========================================================================auto=

#-------------------------------------------------------------------------------
# .PROC MainViewInit
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainViewInit {} {
	global Module View Gui Path Preset Volume

	lappend Module(procStorePresets) MainViewStorePresets
	lappend Module(procRecallPresets) MainViewRecallPresets
	set Module(View,presets) "viewUp='0 0 1' position='0 750 0' \
focalPoint='0 0 0' clippingRange='21 2001' \
viewMode='Normal' viewBgColor='Blue'"

	# The MainViewBuildGUI proc is called specifically
	lappend Module(procVTK)  MainViewBuildVTK

        set m MainView
        lappend Module(versions) [ParseCVSInfo $m \
		{$Revision: 1.22 $} {$Date: 2000/10/02 19:57:38 $}]

	set View(viewerHeightNormal) 656
	set View(viewerWidth)  956 
	set View(viewerHeight) 956 
	if {$Gui(pc) == 1} {
		set View(viewerHeightNormal) 400
		set View(viewerWidth)  700 
		set View(viewerHeight) 700 
	}

	# Configurable
	set View(mode) Normal
	# Changed by Delphine
	set View(viewerWidth)  768 
	set View(viewerHeight) 700 
	set View(toolbarPosition) Top
	set View(bgColor) ".7 .7 .9"
	set View(bgName) Blue
	set View(fov) 220.0
	set View(spin) 0
	set View(spinDir) Right
	set View(spinMs) 5 
	set View(spinDegrees) 2 
	set View(stereo) 0
	set View(stereoType) RedBlue
	set View(closeupVisibility) On
	set View(createMagWin) Yes
	set View(parallelScale) $View(fov)

	# Bug in OpenGL on Windows98 version II ??
	if {$Gui(pc) == 1} {
		set View(createMagWin) No
		set View(closeupVisibility) Off
	}

	# Init
	set View(rotateDegrees) 15
	set View(baselineClippingRange) "1 2001"
	set View(endoscopicClippingRange) "1 1000"
	set View(magWin) Welcome
	set View(inWin) none
	set View(viewPrefix) view
	set View(ext) .tif
}

#-------------------------------------------------------------------------------
# .PROC MainViewBuildVTK
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainViewBuildVTK {} {
	global View Slice

	# Set background color

        eval viewRen SetBackground $View(bgColor)

	# Closeup magnification of the slice with the cursor over it
	#--------------------------------------------
	
	#  [ActiveOutput] -----> mag -> magCursor -> magMapper

	# Create closeup magnification
	vtkImageCloseUp2D View(mag)
	View(mag) SetInput [Slicer GetOutput 0]
	View(mag) SetRadius 12
	View(mag) SetMagnification 7
	set View(closeupMag) 7

	# Closeup Cursor
	vtkImageCrossHair2D View(magCursor)
	View(magCursor) SetInput [View(mag) GetOutput]
	View(magCursor) SetCursor 87 87
	View(magCursor) BullsEyeOn
	View(magCursor) SetBullsEyeWidth 7
	View(magCursor) ShowCursorOn 
	View(magCursor) IntersectCrossOff
	View(magCursor) SetCursorColor 1 1 .5 
	View(magCursor) SetNumHashes 0 
	View(magCursor) SetHashLength 6
	View(magCursor) SetHashGap 10 
	View(magCursor) SetMagnification 1 
}

#-------------------------------------------------------------------------------
# .PROC MainViewBuildGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainViewBuildGUI {} {
	global Gui View Slice viewWin

	#-------------------------------------------
	# Frame Hierarchy:
	#-------------------------------------------
	# Nav
	#	Top
	#	  Dir
	#     Move
	#       Rotate
	#       FOV
	#   Bot
	#     Preset
	#     Center
	#     Save
	#     Parallel
	#-------------------------------------------

	#-------------------------------------------
	# View->Nav Frame
	#-------------------------------------------
	set f $Gui(fNav)
	
	frame $f.fTop -bg $Gui(activeWorkspace)
	frame $f.fBot -bg $Gui(activeWorkspace)
	pack $f.fTop -side top -padx 0 -pady 0 -fill both -expand true
	pack $f.fBot -side top -padx 0 -pady 0 -fill both -expand true

	#-------------------------------------------
	# View->Nav->Top Frame
	#-------------------------------------------
	set f $Gui(fNav).fTop
	
	frame $f.fDir     -bg $Gui(activeWorkspace) -bd $Gui(borderWidth) -relief sunken
#	frame $f.fPreset  -bg $Gui(activeWorkspace)
	frame $f.fMove    -bg $Gui(activeWorkspace)
	
#	pack $f.fDir $f.fPreset $f.fMove -side left -padx 3 -pady 0
	pack $f.fDir $f.fMove -side left -padx 3 -pady 0

	#-------------------------------------------
	# View->Nav->Top->Dir Frame
	#-------------------------------------------
	set f $Gui(fNav).fTop.fDir
	
	# Create control for setting view Direction
	foreach pict "N R L A P S I" {
		image create photo iDir$pict \
			-file [ExpandPath [file join gui "dir$pict.ppm"]]
	}		
	eval {label $f.lDir -image iDirN -width 74 -height 74 -anchor w} $Gui(WLA)
	bind $f.lDir <1>      {if {[MainViewNavReset %x %y click] == 1} {Render3D}}
	bind $f.lDir <Enter>  {MainViewNavReset %x %y      }
	bind $f.lDir <Leave>  {MainViewNavReset %x %y leave}
	bind $f.lDir <Motion> {MainViewNavReset %x %y      }
	pack $f.lDir
	set Gui(fDir) $f.lDir


	#-------------------------------------------
	# View->Nav->Top->Move Frame
	#-------------------------------------------
	set f $Gui(fNav).fTop.fMove
	
	frame $f.fRotate  -bg $Gui(activeWorkspace)
	frame $f.fFov  -bg $Gui(activeWorkspace)

# Comment out spin button to avoid bug when hit presets during spin	
	# MainViewSpin button
#    eval {checkbutton $f.cMainViewSpin \
#        -text "Spin" -variable View(spin) -width 6 \
#        -indicatoron 0 -command "MainViewSpin"} $Gui(WCA)

	pack $f.fRotate $f.fFov -side top -pady 2 
#	pack $f.fRotate $f.cMainViewSpin -side top -pady 3 
	
	#-------------------------------------------
	# View->Nav->Top->Move->Rotate Frame
	#-------------------------------------------
	set f $Gui(fNav).fTop.fMove.fRotate
	
	# Create control for Rotating the view
	foreach pict "None Left Right Down Up" {
		image create photo iRotate${pict} \
			-file [ExpandPath [file join gui "rotate$pict.gif"]]			
	}
	label $f.lRotate -image iRotateNone -relief sunken -bd $Gui(borderWidth)
	bind $f.lRotate <1>      {MainViewNavRotate %W %x %y click}
	bind $f.lRotate <Enter>  {MainViewNavRotate %W %x %y      }
	bind $f.lRotate <Leave>  {MainViewNavRotate %W %x %y leave}
	bind $f.lRotate <Motion> {MainViewNavRotate %W %x %y      }

	pack $f.lRotate -side top -padx 0 -pady 0 

	#-------------------------------------------
	# View->Nav->Top->Move->Fov Frame
	#-------------------------------------------
	set f $Gui(fNav).fTop.fMove.fFov

	eval {label $f.lFov -text "FOV:"} $Gui(WLA)
	eval {entry $f.eFov -textvariable View(fov) -width 7} $Gui(WEA)
	bind $f.eFov <Return> {MainViewSetFov; RenderAll}
        TooltipAdd $f.eFov "field of view"
	pack $f.lFov $f.eFov -side left -padx 2 -pady 0

	#-------------------------------------------
	# View->Nav->Bot Frame
	#-------------------------------------------
	set f $Gui(fNav).fBot

	frame $f.fSave -bg $Gui(activeWorkspace)
	frame $f.fPreset  -bg $Gui(activeWorkspace)
	frame $f.fCenter  -bg $Gui(activeWorkspace)
	frame $f.fParallel  -bg $Gui(activeWorkspace)

	pack $f.fPreset $f.fCenter $f.fSave $f.fParallel -side top -pady 2 -fill x

	#-------------------------------------------
	# View->Nav->Bot->Preset Frame
	#-------------------------------------------
	set f $Gui(fNav).fBot.fPreset
	set View(fPreset) $f

	eval {label $f.lPreset -text "View Presets:"} $Gui(WLA)
	pack $f.lPreset -side left -padx 5 -pady 0

	# Preset Button
	foreach p "1 2 3" {
	    eval {button $f.c$p -text $p -width 2} $Gui(WBA)
	    bind $f.c$p <ButtonPress>   "MainOptionsPreset $p Press"
	    bind $f.c$p <ButtonRelease> "MainOptionsPreset $p Release"
	    TooltipAdd $f.c$p "Click to recall, hold down to save."
	    pack $f.c$p -side left -padx 2 
	}
	
	#-------------------------------------------
	# View->Nav->Bot->Center Frame
	#-------------------------------------------
	set f $Gui(fNav).fBot.fCenter

	# Focalpoint button
	eval {button $f.bFocus -text "Move Focal Point to Center" -width 26 \
		-command "MainViewResetFocalPoint; RenderAll"} $Gui(WBA)
 
	pack $f.bFocus -side left -padx 3 -pady 0

	#-------------------------------------------
	# View->Nav->Bot->Save Frame
	#-------------------------------------------
	set f $Gui(fNav).fBot.fSave

	eval {button $f.bSave -text "Save 3D" -width 7 \
		-command "MainViewSaveView"} $Gui(WBA)
	eval {entry $f.eSave -textvariable View(viewPrefix)} $Gui(WEA)
	bind $f.eSave <Return> {MainViewSaveViewPopup}
        TooltipAdd $f.bSave "Save the 3D window in the chosen filename."

	pack $f.bSave -side left -padx 3
	pack $f.eSave -side left -padx 2 -expand 1 -fill x

	#-------------------------------------------
	# View->Nav->Bot->Parallel Frame
	#-------------------------------------------
	set f $Gui(fNav).fBot.fParallel

	# Parallel button
	eval {checkbutton $f.cParallel \
        -text "Parallel" -variable View(parallelProjection) -width 7 \
        -indicatoron 0 -command "MainViewSetParallelProjection"} $Gui(WCA)
        TooltipAdd $f.cParallel "Toggle parallel/perspective projection"

	# Scale Label
	eval {label $f.lParallelScale -text "Scale:"} $Gui(WLA)

	#  Scale entry box
	eval {entry $f.eParallelScale -textvariable View(parallelScale)} $Gui(WEA)
        TooltipAdd $f.eParallelScale "Scale for parallel projection"

	pack $f.cParallel $f.lParallelScale $f.eParallelScale \
		-side left -padx 3
}

#-------------------------------------------------------------------------------
# .PROC MainViewSetBackgroundColor
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainViewSetBackgroundColor {{col ""}} {
    global View Module
    
    
    # set View(bgName) if called with an argument
    if {$col != ""} {
	if {$col == "Blue" || $col == "Black" || $col == "Midnight"} {
	    set View(bgName) $col
	} else {
	    return
	}   
    }	
	
    switch $View(bgName) {
	"Blue" {
	    set View(bgColor) "0.7 0.7 0.9"
	}
	"Black" {
	    set View(bgColor) "0 0 0"
	}
	"Midnight" {
	    set View(bgColor) "0 0 0.3"
	}
    }
    foreach m $Module(Renderers) {
	eval $m SetBackground $View(bgColor)
    }
}

#-------------------------------------------------------------------------------
# .PROC MainViewSetFov
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainViewSetFov {} {
	global View Gui Slice

	Slicer SetFieldOfView $View(fov)
	MainViewNavReset 55 42 click
	MainViewNavReset 0 0 leave

	# Update slice offset, registration annotation
	MainAnnoSetFov
	MainSlicesSetFov
}

#-------------------------------------------------------------------------------
# .PROC MainViewSetParallelProjection
# Turn on/off parallel projection for the camera.
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainViewSetParallelProjection {} {
    global View Gui Slice

    puts $View(parallelProjection)

    if {$View(parallelProjection) == 1} {
	if {[ValidateFloat $View(parallelScale)] == 0} {
	    tk_messageBox -message "The scale must be a number."
	    set View(parallelScale) $View(fov)
	}    
	$View(viewCam) ParallelProjectionOn
	$View(viewCam) SetParallelScale $View(parallelScale)
    } else {
	$View(viewCam) ParallelProjectionOff
    }	

    Render3D
}

#-------------------------------------------------------------------------------
# .PROC MainViewLightFollowCamera
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainViewLightFollowCamera {} {
	global View
	
	# 3D Viewer

	set lights [viewRen GetLights]

	$lights InitTraversal
	set currentLight [$lights GetNextItem]
	if {$currentLight != ""} {
		eval $currentLight SetPosition   [$View(viewCam) GetPosition]
		eval $currentLight SetFocalPoint [$View(viewCam) GetFocalPoint]
	}

	puts "[$currentLight GetPosition]"
	puts "[$currentLight GetFocalPoint]"
    }


#-------------------------------------------------------------------------------
# .PROC MainViewNavReset
#
# Returns 1 if window should be rendered
# .END
#-------------------------------------------------------------------------------
proc MainViewNavReset {x y {cmd ""}} {
	global dirWin View Target Gui

	if {$cmd == "leave"} {
		$Gui(fDir) config -cursor top_left_arrow -image iDirN
		return 0
	}
	set directions "R L A P S I"
	set xList  "10 65 55 17 40 40"
	set yList  "36 23 42 13 10 65"

	set fp [$View(viewCam) GetFocalPoint]
	set r [lindex $fp 0]
	set a [lindex $fp 1]
	set s [lindex $fp 2]

	foreach dir $directions {
		set i [lsearch $directions $dir]
		set X [lindex  $xList  $i]
		set Y [lindex  $yList  $i]

		if {$x > [expr $X - 10] && $x < [expr $X + 10] && \
			$y > [expr $Y - 10] && $y < [expr $Y + 10]} {
			
			$Gui(fDir) config -cursor hand2 -image iDir$dir

			if {$cmd == "click"} {
				set d [expr $View(fov) * 3]

				switch $dir {
					R {
						$View(viewCam) SetPosition   [expr $r+$d] $a   $s
						$View(viewCam) SetViewUp     0   0   1
					}
					A {
						$View(viewCam) SetPosition   $r   [expr $a+$d] $s
						$View(viewCam) SetViewUp     0   0   1
					}
					S {
						$View(viewCam) SetPosition    $r   $a    [expr $s+$d]
						$View(viewCam) SetViewUp     0   1   0
					}
					L {
						$View(viewCam) SetPosition   [expr $r-$d] $a   $s
						$View(viewCam) SetViewUp     0   0   1
					}
					P {
						$View(viewCam) SetPosition    $r   [expr $a-$d] $s
						$View(viewCam) SetViewUp     0   0   1
					}
					I {
						$View(viewCam) SetPosition    $r   $a    [expr $s-$d]
						$View(viewCam) SetViewUp     0   1   0
					}
				}
				eval $View(viewCam) SetClippingRange $View(baselineClippingRange)
				$View(viewCam) ComputeViewPlaneNormal
				$View(viewCam) OrthogonalizeViewUp

				MainViewLightFollowCamera
				return 1
			}
			return 0
		}
	}
	$Gui(fDir) config -cursor top_left_arrow -image iDirN
}

#-------------------------------------------------------------------------------
# .PROC MainViewRotate
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainViewRotate {dir {deg rotate}} {
	global View

	if {$deg == "rotate"} {
		set p $View(rotateDegrees)
	} else {
		set p $deg
	}			
	set n [expr -$p]
	
	switch $dir {
		Down  {$View(viewCam) Elevation $p }
		Up    {$View(viewCam) Elevation $n }
		Left  {$View(viewCam) Azimuth $p }
		Right {$View(viewCam) Azimuth $n }
	}
	$View(viewCam) OrthogonalizeViewUp

	MainViewLightFollowCamera
	Render3D
}

#-------------------------------------------------------------------------------
# .PROC MainViewNavRotate
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainViewNavRotate {W x y {cmd ""}} {

	set directions "Up Down Left Right"
	set xList      "28 28 9 47"
	set yList      " 9 47 28 28"

	if {$cmd == "leave"} {
		$W config -cursor top_left_arrow -image iRotateNone
		return
	}
	foreach dir $directions {
		set i [lsearch $directions $dir]
		set X [lindex  $xList  $i]
		set Y [lindex  $yList  $i]

		if {$x > [expr $X - 10] && $x < [expr $X + 10] && \
			$y > [expr $Y - 10] && $y < [expr $Y + 10]} {
			$W config -cursor hand2 -image iRotate${dir}
			if {$cmd == "click"} {
			    MainViewRotate $dir
			}
			return
		}
	}
	$W config -cursor top_left_arrow -image iRotateNone
}

#-------------------------------------------------------------------------------
# .PROC MainViewSetStereo
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainViewSetStereo {} {
	global viewWin View

	if {$View(stereo) == "1"} {
		$viewWin SetStereoTypeTo$View(stereoType)
		$viewWin StereoRenderOn
	} else {
		$viewWin StereoRenderOff
	}
}

#-------------------------------------------------------------------------------
# .PROC MainViewSpin
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainViewSpin {} {
	global View

	if {$View(spin) == "1"} {
		MainViewRotate $View(spinDir) $View(spinDegrees)
		update idletasks
		after $View(spinMs) MainViewSpin
	}
}

#-------------------------------------------------------------------------------
# .PROC MainViewSetWelcome
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainViewSetWelcome {win} {
	global Edit Gui Slice View

	# Do nothing if no change
	if {$win == $View(magWin)} {return}

	if {$win == "Controls"} {
		# The gui may not be created yet
		if {[info exists Gui(fNav)] == 1} {
			raise $Gui(fNav)
		}
	} elseif {$win == "Welcome"} {
		if {[info exists Gui(fWelcome)] == 1} {
			raise $Gui(fWelcome)
		}
	} else {
		if {$View(createMagWin) == "Yes" && $View(closeupVisibility) == "On"} {
			if {[info exists Gui(fMagBorder)] == 1} {
				raise $Gui(fMagBorder)
				set s [string index $win 2]
				View(mag) SetInput [Slicer GetActiveOutput $s]
				magMapper SetInput [View(magCursor) GetOutput]
				magWin Render
			}
		}
	}
	
	set View(magWin) $win
}
		
#-------------------------------------------------------------------------------
# .PROC MainViewResetFocalPoint
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainViewResetFocalPoint {} {
	global View Slice
				
	MainViewSetFocalPoint 0 0 0
}

#-------------------------------------------------------------------------------
# .PROC MainViewSetFocalPoint
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainViewSetFocalPoint {x y z} {
	global Slice View

	set View(focalPoint) "$x $y $z"
	eval $View(viewCam) SetFocalPoint $View(focalPoint)
	$View(viewCam) ComputeViewPlaneNormal
	$View(viewCam) OrthogonalizeViewUp

	MainViewLightFollowCamera

	#SLICES
	Slicer ComputeNTPFromCamera $View(viewCam)

# BUG: This causes slice offset to not work with presets
#	foreach s $Slice(idList) {
#		if {[lsearch "Axial Sagittal Coronal Perp InPlane0 InPlane90 \
#			InPlaneNeg90" [Slicer GetOrientString $s]] != -1} {
#			MainSlicesSetOffset $s 0
#		}
#	}

	MainAnnoUpdateFocalPoint $x $y $z
}

#-------------------------------------------------------------------------------
# .PROC MainViewSaveView
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainViewSaveView {} {
	global Mrml View

    # Prefix cannot be blank
	if {$View(viewPrefix) == ""} {
		tk_messageBox -message "Please specify a file name."
		return
	}

	# Get a unique filename by appending a number to the prefix
	set filename [MainFileFindUniqueName $Mrml(dir) $View(viewPrefix) $View(ext)]

	MainViewWriteView $filename
}

#-------------------------------------------------------------------------------
# .PROC MainViewSaveViewPopup
# Provide a popup for saving the 3D view to disk.
# See also: MainViewSaveView
# .END
#-------------------------------------------------------------------------------
proc MainViewSaveViewPopup {} {
	global View Mrml Gui

	# Cannot have blank prefix
	if {$View(viewPrefix) == ""} {
		set View(viewPrefix) view
	}

 	# Show popup initialized to the last file saved
	set filename [file join $Mrml(dir) $View(viewPrefix)]
	set dir [file dirname $filename]
	set typelist {
		{"TIFF File" {".tif"}}
		{"PPM File" {".ppm"}}
		{"BMP File" {".bmp"}}
		{"All Files" {*}}
	}
	set filename [tk_getSaveFile -title "Save 3D View" -defaultextension $View(ext)\
		-filetypes $typelist -initialdir "$dir" -initialfile $filename]

	# Do nothing if the user cancelled
	if {$filename == ""} {return}

	MainViewWriteView $filename
}

#-------------------------------------------------------------------------------
# .PROC MainViewWriteView
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainViewWriteView {filename} {
	global viewWin Mrml View Gui

	MainFileCreateDirectory $filename
	
	# Write it
	set ext [file extension $filename]
	switch $ext {
	".tif" {
		vtkWindowToImageFilter filter
		filter SetInput $viewWin

		vtkTIFFWriter writer
		writer SetInput [filter GetOutput]
		writer SetFileName $filename
		writer Write
		filter Delete
		writer Delete
	}
	".bmp" {
		vtkWindowToImageFilter filter
		filter SetInput $viewWin

		vtkBMPWriter writer
		writer SetInput [filter GetOutput]
		writer SetFileName $filename
		writer Write
		filter Delete
		writer Delete
	}
	".ppm" {
		$viewWin SetFileName $filename
		$viewWin SaveImageAsPPM
	}
	}
	puts "Saved view: $filename"

	# Store the new prefix for next time
	set root $Mrml(dir)
	set absPrefix [file rootname $filename]
	if {$Gui(pc) == 1} {
		set absPrefix [string tolower $absPrefix]
		set root [string tolower $Mrml(dir)]
	}
	if {[regexp "^$root/(\[^0-9\]*)(\[0-9\]*)" $absPrefix match relPrefix num] == 1} {
		set View(viewPrefix) $relPrefix
	} else {
		set View(viewPrefix) [file rootname $absPrefix]
	}
	set View(ext) [file extension $filename]
}

#-------------------------------------------------------------------------------
# .PROC MainViewStorePresets
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc MainViewStorePresets {p} {
	global Preset View

	set Preset(View,$p,position)      [$View(viewCam) GetPosition]
	set Preset(View,$p,viewUp)        [$View(viewCam) GetViewUp]
	set Preset(View,$p,focalPoint)    [$View(viewCam) GetFocalPoint]
	set Preset(View,$p,clippingRange) [$View(viewCam) GetClippingRange]
	set Preset(View,$p,viewMode)      $View(mode)
	set Preset(View,$p,viewBgColor)   $View(bgName)
}
	    
proc MainViewRecallPresets {p} {
	global Preset View

	eval $View(viewCam) SetPosition      $Preset(View,$p,position)
	eval $View(viewCam) SetViewUp        $Preset(View,$p,viewUp)
	eval $View(viewCam) SetClippingRange $Preset(View,$p,clippingRange)

	eval MainViewSetFocalPoint $Preset(View,$p,focalPoint)
	MainViewerSetMode $Preset(View,$p,viewMode)
	MainViewSetBackgroundColor $Preset(View,$p,viewBgColor)
}
