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
# FILE:        fMRIEngineSequence.tcl
# PROCEDURES:  
#   fMRIEngineBuildUIForLoad the
#   fMRIEngineBuildUIForSelect the
#   fMRIEngineSetWindowLevelThresholds
#   fMRIEngineUpdateVolume the
#   fMRIEngineDeleteSeq-RunMatch
#   fMRIEngineAddSeq-RunMatch
#   fMRIEngineUpdateRuns
#   fMRIEngineSelectRun
#   fMRIEngineSelectSequence
#   fMRIEngineUpdateSequences
#==========================================================================auto=

proc fMRIEngineUpdateSequenceTab {} {
    global fMRIEngine

    set fMRIEngine(currentTab) "Sequence"
}

  
#-------------------------------------------------------------------------------
# .PROC fMRIEngineBuildUIForLoad
# Creates UI for Load page 
# .ARGS
# parent the parent frame 
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineBuildUIForLoad {parent} {
    global fMRIEngine Gui

    frame $parent.fTop -bg $Gui(activeWorkspace)
    frame $parent.fBot -bg $Gui(activeWorkspace)
    pack $parent.fTop $parent.fBot -side top 
 
    set f $parent.fTop
    # error if no private segment
    if {[catch "package require MultiVolumeReader"]} {
        DevAddLabel $f.lError \
            "Loading function is disabled\n\
            due to the unavailability\n\
            of module MultiVolumeReader." 
        pack $f.lError -side top -pady 30
        return
    }

    MultiVolumeReaderBuildGUI $f 1

    set f $parent.fBot
    set uselogo [image create photo -file \
        $fMRIEngine(modulePath)/tcl/images/LogosForIbrowser.gif]
    eval {label $f.lLogoImages -width 200 -height 45 \
        -image $uselogo -justify center} $Gui(BLA)
    pack $f.lLogoImages -side bottom -padx 0 -pady 0 -expand 0
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineBuildUIForSelect
# Creates UI for Select page 
# .ARGS
# parent the parent frame 
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineBuildUIForSelect {parent} {
    global fMRIEngine Gui

    frame $parent.fTop    -bg $Gui(activeWorkspace) -relief groove -bd 3 
    frame $parent.fBottom -bg $Gui(activeWorkspace) -relief groove -bd 3
    pack $parent.fTop $parent.fBottom -side top -pady 5 -padx 0  

    #-------------------------------------------
    # Top frame 
    #-------------------------------------------
    set f $parent.fTop
    frame $f.fSeqs    -bg $Gui(activeWorkspace) -relief groove -bd 1 
    frame $f.fOK      -bg $Gui(activeWorkspace)
    frame $f.fListbox -bg $Gui(activeWorkspace)
    pack $f.fSeqs $f.fOK $f.fListbox -side top -pady 3 -padx 1  

    #------------------------------
    # Loaded sequences 
    #------------------------------
    set f $parent.fTop.fSeqs

    DevAddLabel $f.lNo "How many runs:"
    eval {entry $f.eRun -width 17 \
        -textvariable fMRIEngine(noOfRuns)} $Gui(WEA)
    set fMRIEngine(noOfRuns) 1

    # Build pulldown menu for all loaded sequences 
    DevAddLabel $f.lSeq "Choose a sequence:"
    set sequenceList [list {none}]
    set df [lindex $sequenceList 0] 
    eval {menubutton $f.mbType -text $df \
        -relief raised -bd 2 -width 17 \
        -menu $f.mbType.m} $Gui(WMBA)
    eval {menu $f.mbType.m} $Gui(WMA)

    # Add menu items
    foreach m $sequenceList {
        $f.mbType.m add command -label $m \
            -command ""
    }

    # Save menubutton for config
    set fMRIEngine(gui,sequenceMenuButton) $f.mbType
    set fMRIEngine(gui,sequenceMenu) $f.mbType.m

    # Build pulldown menu for all runs 
    DevAddLabel $f.lRun "Used for run#:"
    set runList [list {1}]
    set df [lindex $runList 0] 
    eval {menubutton $f.mbType2 -text $df \
        -relief raised -bd 2 -width 17 \
        -menu $f.mbType2.m} $Gui(WMBA)
    bind $f.mbType2 <1> "fMRIEngineUpdateRuns" 
    eval {menu $f.mbType2.m} $Gui(WMA)

    set fMRIEngine(currentSelectedRun) 1

    # Save menubutton for config
    set fMRIEngine(gui,runListMenuButton) $f.mbType2
    set fMRIEngine(gui,runListMenu) $f.mbType2.m
    fMRIEngineUpdateRuns

    blt::table $f \
        0,0 $f.lNo -padx 3 -pady 3 \
        0,1 $f.eRun -padx 2 -pady 3 \
        1,0 $f.lSeq -fill x -padx 3 -pady 3 \
        1,1 $f.mbType -padx 2 -pady 3 \
        2,0 $f.lRun -fill x -padx 3 -pady 3 \
        2,1 $f.mbType2 -padx 2 -pady 3 

    #------------------------------
    # OK  
    #------------------------------
    set f $parent.fTop.fOK
    DevAddButton $f.bOK "OK" "fMRIEngineAddSeq-RunMatch" 6 
    grid $f.bOK -padx 2 

    #-----------------------
    # List box  
    #-----------------------
    set f $parent.fTop.fListbox
    frame $f.fBox -bg $Gui(activeWorkspace)
    frame $f.fAction  -bg $Gui(activeWorkspace)
    pack $f.fBox $f.fAction -side top -fill x -pady 1 -padx 2 

    set f $parent.fTop.fListbox.fBox
    DevAddLabel $f.lSeq "Specified runs:"
    scrollbar $f.vs -orient vertical -bg $Gui(activeWorkspace)
    set fMRIEngine(seqVerScroll) $f.vs
    listbox $f.lb -height 4 -bg $Gui(activeWorkspace) \
        -yscrollcommand {$::fMRIEngine(seqVerScroll) set}
    set fMRIEngine(seqListBox) $f.lb
    $fMRIEngine(seqVerScroll) configure -command {$fMRIEngine(seqListBox) yview}

    blt::table $f \
        0,0 $f.lSeq -cspan 2 -pady 5 -fill x \
        1,0 $fMRIEngine(seqListBox) -padx 1 -pady 1 \
        1,1 $fMRIEngine(seqVerScroll) -fill y -padx 1 -pady 1

    #-----------------------
    # Action  
    #-----------------------
    set f $parent.fTop.fListbox.fAction
    DevAddButton $f.bDelete "Delete" "fMRIEngineDeleteSeq-RunMatch" 6 
    grid $f.bDelete -padx 2 -pady 2 

    #-------------------------------------------
    # Bottom frame 
    #-------------------------------------------
    set f $parent.fBottom
    frame $f.fLabel   -bg $Gui(activeWorkspace)
    frame $f.fButtons -bg $Gui(activeWorkspace)
    frame $f.fSlider  -bg $Gui(activeWorkspace)
    pack $f.fLabel $f.fButtons $f.fSlider -side top -fill x -pady 1 -padx 2 

    set f $parent.fBottom.fLabel
    DevAddLabel $f.lLabel "Navigate the sequence:"
    pack $f.lLabel -side top -fill x -pady 1 -padx 2 

    set f $parent.fBottom.fButtons
    DevAddButton $f.bHelp "?" "fMRIEngineHelpLoadVolumeAdjust" 2
    DevAddButton $f.bSet "Set Window/Level/Thresholds" \
        "fMRIEngineSetWindowLevelThresholds" 30 
    grid $f.bHelp $f.bSet -padx 1 

    set f $parent.fBottom.fSlider
    DevAddLabel $f.lVolno "Volume index:"
    eval { scale $f.sSlider \
        -orient horizontal \
        -from 0 -to 0 \
        -resolution 1 \
        -bigincrement 10 \
        -length 120 \
        -state active \
        -command {fMRIEngineUpdateVolume}} \
        $Gui(WSA) {-showvalue 1}
    grid $f.lVolno $f.sSlider 

    set fMRIEngine(slider) $f.sSlider
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineSetWindowLevelThresholds
# For a time series, set window, level, and low/high thresholds for all volumes
# with the first volume's values
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineSetWindowLevelThresholds {} {
   global fMRIEngine Volume 

    if {[info exists fMRIEngine(noOfVolumes)] == 0} {
        return
    }

    set low [Volume($fMRIEngine(firstMRMLid),node) GetLowerThreshold]
    set win [Volume($fMRIEngine(firstMRMLid),node) GetWindow]
    set level [Volume($fMRIEngine(firstMRMLid),node) GetLevel]
    set fMRIEngine(lowerThreshold) $low

    set i $fMRIEngine(firstMRMLid)
    while {$i <= $fMRIEngine(lastMRMLid)} {
        # If AutoWindowLevel is ON, 
        # we can't set new values for window and level.
        Volume($i,node) AutoWindowLevelOff
        Volume($i,node) SetWindow $win 
        Volume($i,node) SetLevel $level 
 
        Volume($i,node) AutoThresholdOff
        Volume($i,node) ApplyThresholdOn
        Volume($i,node) SetLowerThreshold $low 
        incr i
    }
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineUpdateVolume
# Updates image volume as user moves the slider 
# .ARGS
# volumeNo the volume number
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineUpdateVolume {volumeNo} {
    global fMRIEngine

    if {$volumeNo == 0} {
#        DevErrorWindow "Volume number must be greater than 0."
        return
    }

    set v [expr $volumeNo-1]
    set id [expr $fMRIEngine(firstMRMLid)+$v]

    MainSlicesSetVolumeAll Back $id 
    RenderAll
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineDeleteSeq-RunMatch
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineDeleteSeq-RunMatch {} {
    global fMRIEngine 

    set curs [$fMRIEngine(seqListBox) curselection]
    if {$curs != ""} {
        set first [lindex $curs 0] 
        set last [lindex $curs end]
        $fMRIEngine(seqListBox) delete $first $last
    }
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineAddSeq-RunMatch
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineAddSeq-RunMatch {} {
    global fMRIEngine 

    # Add a sequence-run match
    if {! [info exists fMRIEngine(currentSelectedSequence)] ||
        $fMRIEngine(currentSelectedSequence) == "none"} {
        DevErrorWindow "Select a valid sequence."
        return
    }

    if {! [info exists fMRIEngine(currentSelectedRun)] ||
        $fMRIEngine(currentSelectedRun) == "none"} {
        DevErrorWindow "Select a valid run."
        return
    }

    set str \
        "r$fMRIEngine(currentSelectedRun):$fMRIEngine(currentSelectedSequence)"
    set i 0
    set found 0
    set size [$fMRIEngine(seqListBox) size]
    while {$i < $size} {  
        set v [$fMRIEngine(seqListBox) get $i] 
        if {$v != ""} {
            set i1 1 
            set i2 [string first ":" $v]
            set r [string range $v $i1 [expr $i2-1]] 
            set r [string trim $r]

            if {$r == $fMRIEngine(currentSelectedRun)} {
                set found 1
                break
            }
        }

        incr i
    }

    if {$found} {
        DevErrorWindow "The r$r has been specified."
    } else {
        $fMRIEngine(seqListBox) insert end $str 
        set fMRIEngine($fMRIEngine(currentSelectedRun),sequenceName) \
            $fMRIEngine(currentSelectedSequence)
    }
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineUpdateRuns
# Chooses one sequence from the sequence list loaded within the Ibrowser module 
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineUpdateRuns {} {
    global fMRIEngine 

    set runs [string trim $fMRIEngine(noOfRuns)]
    if {$runs < 1} {
        DevErrorWindow "No of runs must be at least 1."
    } else { 
        $fMRIEngine(gui,runListMenu) delete 0 end
        set count 1
        while {$count <= $runs} {
            $fMRIEngine(gui,runListMenu) add command -label $count \
                -command "fMRIEngineSelectRun $count"
            incr count
        }
    }
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineSelectRun
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineSelectRun {run} {
    global fMRIEngine 

    # configure menubutton
    $fMRIEngine(gui,runListMenuButton) config -text $run
    set fMRIEngine(currentSelectedRun) $run
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineSelectSequence
# Chooses one sequence from the sequence list loaded within the Ibrowser module 
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineSelectSequence {seq} {
    global fMRIEngine Ibrowser MultiVolumeReader

    # configure menubutton
    $fMRIEngine(gui,sequenceMenuButton) config -text $seq
    set fMRIEngine(currentSelectedSequence) $seq
    if {$seq == "none"} {
        return
    }

    set l [string trim $seq]

    if {[info exists MultiVolumeReader(sequenceNames)]} {
        set found [lsearch -exact $MultiVolumeReader(sequenceNames) $seq]
        if {$found >= 0} {
            set fMRIEngine(firstMRMLid) $MultiVolumeReader($seq,firstMRMLid) 
            set fMRIEngine(lastMRMLid) $MultiVolumeReader($seq,lastMRMLid)
            set fMRIEngine(volumeExtent) $MultiVolumeReader($seq,volumeExtent) 
            set fMRIEngine(noOfVolumes) $MultiVolumeReader($seq,noOfVolumes) 
        }
    }

    # Sets range for the volume slider
    $fMRIEngine(slider) configure -from 1 -to $fMRIEngine(noOfVolumes)
    # Sets the first volume in the sequence as the active volume
    MainVolumesSetActive $fMRIEngine(firstMRMLid)
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineUpdateSequences
# Updates sequence list loaded within the Ibrowser module 
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineUpdateSequences {} {
    global fMRIEngine Ibrowser MultiVolumeReader 

    # clears the menu 
    $fMRIEngine(gui,sequenceMenu) delete 0 end 

    # checks sequence loaded from fMRIEngine
    set b [info exists MultiVolumeReader(sequenceNames)] 
    set n [expr {$b == 0 ? 0 : [llength $MultiVolumeReader(sequenceNames)]}]

    $fMRIEngine(gui,sequenceMenu) add command -label "none" \
        -command "fMRIEngineSelectSequence none"

    if {$n > 0} {
        set i 0 
        while {$i < $n} {
            set name [lindex $MultiVolumeReader(sequenceNames) $i]
            $fMRIEngine(gui,sequenceMenu) add command -label $name \
                -command "fMRIEngineSelectSequence $name"
            incr i
        }
    }
}



