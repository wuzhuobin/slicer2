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
# FILE:        fMRIEngineParadigmDesign.tcl
# PROCEDURES:  
#   fMRIEngineBuildUIForParadigmDesign  the
#   fMRIEngineShowConditionToEdit
#   fMRIEngineDeleteCondition
#   fMRIEngineSelectRunForConditionConfig
#   fMRIEngineUpdateRunsForConditionConfig
#   fMRIEngineSelectRunForConditionShow
#   fMRIEngineUpdateRunsForConditionShow
#   fMRIEngineIdenticalizeConditions
#   fMRIEngineAddOrEditCondition
#   fMRIEngineShowConditions
#==========================================================================auto=

#-------------------------------------------------------------------------------
# .PROC fMRIEngineBuildUIForParadigmDesign 
# Creates UI for task "Paradigm Design" 
# .ARGS
# parent the parent frame 
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineBuildUIForParadigmDesign {parent} {
    global fMRIEngine Gui

    frame $parent.fTop   -bg $Gui(activeWorkspace) -relief groove -bd 1 
    frame $parent.fBot   -bg $Gui(activeWorkspace) -relief groove -bd 1
    pack $parent.fTop $parent.fBot \
        -side top -fill x -pady 2 -padx 1 

    #-------------------------------------------
    # Top frame 
    #-------------------------------------------
    #-----------------------
    # Configure a condition 
    #-----------------------
    set f $parent.fTop
    frame $f.fUp      -bg $Gui(activeWorkspace) 
    frame $f.fMiddle  -bg $Gui(activeWorkspace) -relief groove -bd 1 
    frame $f.fDown    -bg $Gui(activeWorkspace)
    pack $f.fUp $f.fMiddle $f.fDown -side top -fill x -pady 1 -padx 2 
 
    set f $parent.fTop.fUp
    frame $f.fChoice  -bg $Gui(activeWorkspace) 
    frame $f.fLabel   -bg $Gui(activeWorkspace)
    pack $f.fChoice $f.fLabel -side top -fill x -pady 2 -padx 1 

    set f $parent.fTop.fUp.fChoice
    DevAddButton $f.bHelp "?" "fMRIEngineHelpSetupBlockEventMixed" 2 
    foreach param "blocked event-related mixed" \
        name "{Blocked} {Event-r} {Mixed}" {
        eval {radiobutton $f.r$param -width 6 -text $name \
            -variable fMRIEngine(paradigmDesignType) -value $param \
            -relief raised -offrelief raised -overrelief raised \
            -command "" \
            -selectcolor white} $Gui(WEA)
    } 
    $f.rblocked select
    grid $f.bHelp $f.rblocked $f.revent-related $f.rmixed \
        -padx 0 -pady 1 -sticky e

    set f $parent.fTop.fUp.fLabel
    eval {checkbutton $f.cRunIdentical \
        -variable fMRIEngine(checkbuttonRunIdentical) \
        -text "All runs are identical"} $Gui(WEA) 
    bind $f.cRunIdentical <1> "fMRIEngineSelectRunForConditionConfig 1" 
#    bind $f.cRunIdentical <1> "fMRIEngineIdenticalizeConditions" 
    $f.cRunIdentical select 

    # Build pulldown menu for all runs 
    DevAddLabel $f.lConf "Configure a condition for run#:"
    set runList [list {1}]
    set df [lindex $runList 0] 
    eval {menubutton $f.mbType -text $df \
        -relief raised -bd 2 -width 8 \
        -menu $f.mbType.m} $Gui(WMBA)
    bind $f.mbType <1> "fMRIEngineUpdateRunsForConditionConfig" 
    eval {menu $f.mbType.m} $Gui(WMA)

    # Add menu items
    foreach m $runList  {
        $f.mbType.m add command -label $m \
            -command "fMRIEngineUpdateRunsForConditionConfig" 
    }

    set fMRIEngine(curRunForConditionConfig) 1

    # Save menubutton for config
    set fMRIEngine(gui,runListMenuButtonForConditionConfig) $f.mbType
    set fMRIEngine(gui,runListMenuForConditionConfig) $f.mbType.m

    blt::table $f \
        0,0 $f.cRunIdentical -cspan 2 -fill x -padx 3 -pady 3 \
        1,0 $f.lConf -padx 2 -pady 3 \
        1,1 $f.mbType -fill x -padx 2 -pady 3 

    set f $parent.fTop.fMiddle
    # Entry fields (the loop makes a frame for each variable)
    set fMRIEngine(paramConfigLabels) \
        [list {Title} {TR} {Start Vol} {Onsets} {Durations}]
    set fMRIEngine(paramConfigEntries) \
        [list title tr startVol onsets durations]
    set i 0      
    set len [llength $fMRIEngine(paramConfigLabels)]
    while {$i < $len} { 

        set name [lindex $fMRIEngine(paramConfigLabels) $i]
        set param [lindex $fMRIEngine(paramConfigEntries) $i]
 
        eval {label $f.l$param -text "$name:"} $Gui(WLA)
        eval {entry $f.e$param -width 23 -textvariable fMRIEngine(entry,$param)} $Gui(WEA)

        grid $f.l$param $f.e$param -padx 1 -pady 1 -sticky e
        grid $f.e$param -sticky w

        incr i
    }

    #-----------------------
    # Add or update 
    #-----------------------
    set f $parent.fTop.fDown
    DevAddButton $f.bOK "OK" "fMRIEngineAddOrEditCondition" 6 
    grid $f.bOK -padx 1 -pady 2 

    #-------------------------------------------
    # Bottom frame 
    #-------------------------------------------
    set f $parent.fBot
    frame $f.fUp      -bg $Gui(activeWorkspace)
    frame $f.fMiddle  -bg $Gui(activeWorkspace)
    frame $f.fDown    -bg $Gui(activeWorkspace)
    pack $f.fUp $f.fMiddle $f.fDown -side top -fill x -pady 1 -padx 1 

    set f $parent.fBot.fUp
    # Build pulldown menu for all runs 
    DevAddLabel $f.l "Specified conditions for run#:"
    set runList [list {1}]
    set df [lindex $runList 0] 
    eval {menubutton $f.mbType -text $df \
        -relief raised -bd 2 -width 8 \
        -menu $f.mbType.m} $Gui(WMBA)
    bind $f.mbType <1> "fMRIEngineUpdateRunsForConditionShow" 
    eval {menu $f.mbType.m} $Gui(WMA)

    # Add menu items
    foreach m $runList  {
        $f.mbType.m add command -label $m \
            -command "fMRIEngineUpdateRunsForConditionShow" 
    }

    set fMRIEngine(curRunForConditionShow) 1 

    # Save menubutton for config
    set fMRIEngine(gui,runListMenuButtonForConditionShow) $f.mbType
    set fMRIEngine(gui,runListMenuForConditionShow) $f.mbType.m
    blt::table $f \
        0,0 $f.l -padx 2 -pady 3 \
        0,1 $f.mbType -fill x -padx 2 -pady 3

    set f $parent.fBot.fMiddle
    scrollbar $f.vs -orient vertical -bg $Gui(activeWorkspace)
    set fMRIEngine(condsVerScroll) $f.vs
    listbox $f.lb -height 5 -bg $Gui(activeWorkspace) \
        -yscrollcommand {$::fMRIEngine(condsVerScroll) set}
    set fMRIEngine(condsListBox) $f.lb
    $fMRIEngine(condsVerScroll) configure -command {$fMRIEngine(condsListBox) yview}

    blt::table $f \
        0,0 $fMRIEngine(condsListBox) -padx 1 -pady 1 \
        0,1 $fMRIEngine(condsVerScroll) -fill y -padx 1 -pady 1

    #-----------------------
    # Action  
    #-----------------------
    set f $parent.fBot.fDown
    DevAddButton $f.bDelete "Delete" "fMRIEngineDeleteCondition" 6 
    DevAddButton $f.bView "Edit" "fMRIEngineShowConditionToEdit" 6 
    grid $f.bView $f.bDelete -padx 1 -pady 2 
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineShowConditionToEdit
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineShowConditionToEdit {} {
    global fMRIEngine 

    set curs [$fMRIEngine(condsListBox) curselection]
    if {$curs != ""} {
        set con [$fMRIEngine(condsListBox) get $curs] 
        if {$con != ""} {
            set i 1 
            set i2 [string first ":" $con]
            set run [string range $con $i [expr $i2-1]] 
            set title [string range $con [expr $i2+1] end] 
       }

        set run [string trim $run]
        set title [string trim $title]
        set found [lsearch -exact $fMRIEngine($run,conditionList) $title]

        if {$found >= 0} {
            if {! $fMRIEngine(checkbuttonRunIdentical) &&
                $fMRIEngine(noOfRuns) > 1} {
                fMRIEngineSelectRunForConditionConfig $run 
            }

            set fMRIEngine(entry,title) $fMRIEngine($run,$title,title)
            set fMRIEngine(entry,tr) $fMRIEngine($run,tr)
            set fMRIEngine(entry,startVol) $fMRIEngine($run,$title,startVol)
            set fMRIEngine(entry,onsets) $fMRIEngine($run,$title,onsets)
            set fMRIEngine(entry,durations) $fMRIEngine($run,$title,durations)
        }

        set fMRIEngine(indexForEdit,condsListBox) $curs

    } else {
        DevErrorWindow "Select a condition to edit."
    }
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineDeleteCondition
# Deletes a condition 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineDeleteCondition {} {
    global fMRIEngine

    set curs [$fMRIEngine(condsListBox) curselection]
    if {$curs != ""} {
        set con [$fMRIEngine(condsListBox) get $curs] 
        if {$con != ""} {
            set i 1 
            set i2 [string first ":" $con]
            set run [string range $con $i [expr $i2-1]] 
            set title [string range $con [expr $i2+1] end] 
        }

        set run [string trim $run]
        set title [string trim $title]
        set found [lsearch -exact $fMRIEngine($run,conditionList) $title]

        if {$found >= 0} {
            $fMRIEngine(condsListBox) delete $curs 

            if {! $fMRIEngine(checkbuttonRunIdentical)} {
                set fMRIEngine($run,conditionList) \
                    [lreplace $fMRIEngine($run,conditionList) $found $found]
                unset -nocomplain fMRIEngine($run,$title,title)
                unset -nocomplain fMRIEngine($run,$title,startVol)
                unset -nocomplain fMRIEngine($run,$title,onsets)
                unset -nocomplain fMRIEngine($run,$title,durations)
            } else {
                for {set r 1} {$r <= $fMRIEngine(noOfRuns)} {incr r} {
                    set fMRIEngine($r,conditionList) \
                        [lreplace $fMRIEngine($r,conditionList) $found $found]
                    unset -nocomplain fMRIEngine($r,$title,title)
                    unset -nocomplain fMRIEngine($r,$title,startVol)
                    unset -nocomplain fMRIEngine($r,$title,onsets)
                    unset -nocomplain fMRIEngine($r,$title,durations)
                }
            }

            fMRIEngineShowConditions 
       }
    } else {
        DevErrorWindow "Select a condition to delete."
    }
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineSelectRunForConditionConfig
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineSelectRunForConditionConfig {run} {
    global fMRIEngine 

    # configure menubutton
    $fMRIEngine(gui,runListMenuButtonForConditionConfig) config -text $run
    set fMRIEngine(curRunForConditionConfig) $run 
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineUpdateRunsForConditionConfig
# Chooses one sequence from the sequence list loaded within the Ibrowser module 
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineUpdateRunsForConditionConfig {} {
    global fMRIEngine 

    if {! $fMRIEngine(checkbuttonRunIdentical)} {
        set runs [string trim $fMRIEngine(noOfRuns)]
        if {$runs < 1} {
            DevErrorWindow "No of runs must be at least 1."
        } else { 
            $fMRIEngine(gui,runListMenuForConditionConfig) delete 0 end
            set count 1
            while {$count <= $runs} {
                $fMRIEngine(gui,runListMenuForConditionConfig) add command -label $count \
                    -command "fMRIEngineSelectRunForConditionConfig $count"
                incr count
            } 
        }
    } else {
        $fMRIEngine(gui,runListMenuForConditionConfig) delete 0 end
        $fMRIEngine(gui,runListMenuForConditionConfig) add command -label 1\
            -command "fMRIEngineSelectRunForConditionConfig 1"
    }
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineSelectRunForConditionShow
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineSelectRunForConditionShow {run} {
    global fMRIEngine 

    # configure menubutton
    $fMRIEngine(gui,runListMenuButtonForConditionShow) config -text $run
    set fMRIEngine(curRunForConditionShow) $run 

    fMRIEngineShowConditions 
}

 
#-------------------------------------------------------------------------------
# .PROC fMRIEngineUpdateRunsForConditionShow
# Chooses one sequence from the sequence list loaded within the Ibrowser module 
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineUpdateRunsForConditionShow {} {
    global fMRIEngine 

    set runs [string trim $fMRIEngine(noOfRuns)]
    if {$runs < 1} {
        DevErrorWindow "No of runs must be at least 1."
    } else { 
        $fMRIEngine(gui,runListMenuForConditionShow) delete 0 end
        if {$runs > 1} {
            $fMRIEngine(gui,runListMenuForConditionShow) add command -label All \
                -command "fMRIEngineSelectRunForConditionShow All"
        }

        set count 1
        while {$count <= $runs} {
            $fMRIEngine(gui,runListMenuForConditionShow) add command -label $count \
                -command "fMRIEngineSelectRunForConditionShow $count"
            incr count
        }   
    }
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineIdenticalizeConditions
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineIdenticalizeConditions {} {
    global fMRIEngine 

    fMRIEngineSelectRunForConditionConfig 1

    # If we have multiple runs, copy all conditions of Run# 1 
    # to the rest of runs.
    if {$fMRIEngine(checkbuttonRunIdentical)} {
        set runs [string trim $fMRIEngine(noOfRuns)]
        if {$runs > 1} {
            $fMRIEngine(gui,runListMenuForConditionConfig) delete 0 end
            set count 2 
            while {$count <= $runs} {
                set fMRIEngine($count,$title,title) $fMRIEngine(1,$title,title)  
                set fMRIEngine($count,$title,startVol) $fMRIEngine(1,$title,startVol) 
                set fMRIEngine($count,$title,onsets) $fMRIEngine(1,$title,onsets) 
                set fMRIEngine($count,$title,durations) $fMRIEngine(1,$title,durations) 

                incr count
            } 

            fMRIEngineShowConditions 
        }
    } 

}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineEditCondition
# Edits a condition 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineEditCondition {} {
    global fMRIEngine

    set title [string trim $fMRIEngine(entry,title)]
    set tr [string trim $fMRIEngine(entry,tr)]
    set startVol [string trim $fMRIEngine(entry,startVol)]
    set onsets [string trim $fMRIEngine(entry,onsets)]
    set durations [string trim $fMRIEngine(entry,durations)]

    set curs [$fMRIEngine(condsListBox) curselection]
    if {$curs != ""} {
        set con [$fMRIEngine(condsListBox) get $curs] 
        if {$con != ""} {
            set i 1 
            set i2 [string first ":" $con]
            set run [string range $con $i [expr $i2-1]] 
            set t [string range $con [expr $i2+1] end] 
        }

        set run [string trim $run]
        set t [string trim $title]
        if {$fMRIEngine($run,tr) == $tr                 &&
            [info exists fMRIEngine($run,$t,title)]     &&
            $fMRIEngine($run,$t,title) == $title        &&
            $fMRIEngine($run,$t,startVol) == $startVol  &&
            $fMRIEngine($run,$t,onsets) == $onsets      &&
            $fMRIEngine($run,$t,durations) == $durations} {
            DevErrorWindow "This condition already exists."
            return
        }

        fMRIEngineDeleteCondition
        fMRIEngineAddCondition
    }
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineAddCondition
# Adds a condition 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineAddCondition {} {
    global fMRIEngine

    set title [string trim $fMRIEngine(entry,title)]
    set tr [string trim $fMRIEngine(entry,tr)]
    set startVol [string trim $fMRIEngine(entry,startVol)]
    set onsets [string trim $fMRIEngine(entry,onsets)]
    set durations [string trim $fMRIEngine(entry,durations)]

    set currRun $fMRIEngine(curRunForConditionConfig)
    set found -1
    if {[info exists fMRIEngine($currRun,conditionList)]} {
        set found [lsearch -exact $fMRIEngine($currRun,conditionList) $title]
    }

    if {! $fMRIEngine(checkbuttonRunIdentical)} { 
        if {$found == -1} {
            lappend fMRIEngine($currRun,conditionList) $title
        } else {
            if {$fMRIEngine($currRun,tr) == $tr                     &&
                $fMRIEngine($currRun,$title,title) == $title        &&
                $fMRIEngine($currRun,$title,startVol) == $startVol  &&
                $fMRIEngine($currRun,$title,onsets) == $onsets      &&
                $fMRIEngine($currRun,$title,durations) == $durations} {
                DevErrorWindow "This condition already exists."
                return
            }
        }

        set fMRIEngine($currRun,designType) $fMRIEngine(paradigmDesignType)
        set fMRIEngine($currRun,tr) $tr

        set fMRIEngine($currRun,$title,title) $title
        set fMRIEngine($currRun,$title,startVol) $startVol
        set fMRIEngine($currRun,$title,onsets) $onsets
        set fMRIEngine($currRun,$title,durations) $durations
    } else {
        for {set r 1} {$r <= $fMRIEngine(noOfRuns)} {incr r} {
            if {$found == -1} {
                lappend fMRIEngine($r,conditionList) $title
            } else {
                if {$fMRIEngine($r,tr) == $tr                     &&
                    $fMRIEngine($r,$title,title) == $title        &&
                    $fMRIEngine($r,$title,startVol) == $startVol  &&
                    $fMRIEngine($r,$title,onsets) == $onsets      &&
                    $fMRIEngine($r,$title,durations) == $durations} {
                    DevErrorWindow "This condition already exists."
                    return
                }
            }

            set fMRIEngine($r,designType) $fMRIEngine(paradigmDesignType)
            set fMRIEngine($r,tr) $tr

            set fMRIEngine($r,$title,title) $title
            set fMRIEngine($r,$title,startVol) $startVol
            set fMRIEngine($r,$title,onsets) $onsets
            set fMRIEngine($r,$title,durations) $durations
        }
    }
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineAddOrEditCondition
# Adds or edit a condition 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineAddOrEditCondition {} {
    global fMRIEngine

    # Error checking all input

    set title [string trim $fMRIEngine(entry,title)]
    if {$title == ""} {
        DevErrorWindow "Input a unique name for this condition."
        return
    }

    set tr [string trim $fMRIEngine(entry,tr)]
    set b [string is integer -strict $tr]
    if {$b == 0 || $tr < 1} {
        DevErrorWindow "Input the TR in seconds."
        return
    }

    set startVol [string trim $fMRIEngine(entry,startVol)]
    set b [string is integer -strict $startVol]
    if {$b == 0 || $startVol < 0} {
        DevErrorWindow "Input the start volume index"
        return
    }

    set errorMsg "Input the onsets vector in multiples of TR."
    set onsets [string trim $fMRIEngine(entry,onsets)]
    if {$onsets == ""} {
        DevErrorWindow $errorMsg 
        return
    }
    # replace multiple spaces in the middle of the string by one space  
    regsub -all {( )+} $onsets " " onsets 
    set onsetsList [split $onsets " "]     
    set len1 [llength $onsetsList]
    foreach i $onsetsList { 
        set v [string trim $i]
        set b [string is integer -strict $v]
        if {$b == 0 || $v < 0} {
            DevErrorWindow $errorMsg 
            return
        }
    }

    if {$fMRIEngine(paradigmDesignType) != "event-related"} {
        set errorMsg "Input the durations vector in multiples of TR."
        set durations [string trim $fMRIEngine(entry,durations)]
        if {$durations == ""} {
            DevErrorWindow $errorMsg 
            return
        }
        # replace multiple spaces in the middle of the string by one space  
        regsub -all {( )+} $durations " " durations 
        set durationsList [split $durations " "]     
        set len2 [llength $durationsList]

        # onsets vector must have the same length as the durations vector
        if {$len1 != $len2} {
            DevErrorWindow "Onsets and durations vectors must have the same length." 
            return
        }

        foreach i $durationsList { 
            set v [string trim $i]
            set b [string is integer -strict $v]
            if {$b == 0 || $v < 1} {
                DevErrorWindow $errorMsg 
                return
            }
        }
    }

    set curs [$fMRIEngine(condsListBox) curselection]
    if {$curs != ""} {
        # assume to edit a condition
        fMRIEngineEditCondition
    } else {
        # add a new condition
        fMRIEngineAddCondition
    }

    fMRIEngineShowConditions 
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineShowConditions
# Displays conditions 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineShowConditions {} {
    global fMRIEngine 

    set start 1
    set end [$fMRIEngine(gui,runListMenuForConditionShow) index end] 
    set currRun $fMRIEngine(curRunForConditionShow)
    $fMRIEngine(condsListBox) delete 0 end

    if {$currRun != "All"} {
        set start $currRun
        set end $currRun
    } 

    set i $start
    while {$i <= $end} {
        if {[info exists fMRIEngine($i,conditionList)]} {  
            set len [llength $fMRIEngine($i,conditionList)]
            set count 0
            while {$count < $len} {
                set title [lindex $fMRIEngine($i,conditionList) $count]
                $fMRIEngine(condsListBox) insert end "r$i:$title"
                incr count
            }
        }

        incr i 
    }
}


