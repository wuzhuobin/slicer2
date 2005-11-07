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
# FILE:        fMRIEngineModel.tcl
# PROCEDURES:  
#   fMRIEngineBuildUIForSetupTab parent
#   fMRIEngineLoadModel
#   fMRIEngineSaveModel
#   fMRIEngineClearModel
#   fMRIEngineViewModel
#   fMRIEngineBuildUIForTasks parent
#   fMRIEngineSetModelTask task
#   fMRIEngineUpdateSetupTab
#==========================================================================auto=

#-------------------------------------------------------------------------------
# .PROC fMRIEngineBuildUIForSetupTab
# Creates UI for model tab 
# .ARGS
# windowpath parent the parent frame 
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineBuildUIForSetupTab {parent} {
    global fMRIEngine Gui

    frame $parent.fHelp    -bg $Gui(activeWorkspace)
    frame $parent.fMethods -bg $Gui(backdrop)
    frame $parent.fModel   -bg $Gui(activeWorkspace)
    frame $parent.fTasks   -bg $Gui(activeWorkspace) \
        -relief groove -bd 3

    pack $parent.fHelp $parent.fMethods \
        -side top -fill x -pady 2 -padx 5 
    pack $parent.fModel $parent.fTasks \
        -side top -fill x -pady 3 -padx 5 

    #-------------------------------------------
    # Help frame 
    #-------------------------------------------
#    set f $parent.fHelp
#    DevAddButton $f.bHelp "?" "fMRIEngineShowHelp" 2 
#    pack $f.bHelp -side left -padx 1 -pady 1 

    #-------------------------------------------
    # Methods frame 
    #-------------------------------------------
    set f $parent.fMethods
    DevAddButton $f.bHelp "?" "fMRIEngineHelpSetupChooseDetector" 2 
    pack $f.bHelp -side left -padx 1 -pady 1 

    # Build pulldown menu image format 
    eval {label $f.l -text "Choose method:"} $Gui(BLA)
    pack $f.l -side left -padx $Gui(pad) -fill x -anchor w

    # GLM is default format 
    set detectorList [list {Linear Modeling}]
    set df [lindex $detectorList 0] 
    eval {menubutton $f.mbType -text $df \
          -relief raised -bd 2 -width 16 \
          -indicatoron 1 \
          -menu $f.mbType.m} $Gui(WMBA)
    eval {menu $f.mbType.m} $Gui(WMA)
    pack  $f.mbType -side left -pady 1 -padx $Gui(pad)

    # Add menu items
    foreach m $detectorList  {
        $f.mbType.m add command -label $m \
            -command ""
    }

    # Save menubutton for config
    set fMRIEngine(gui,mbActDetector) $f.mbType

    #-------------------------------------------
    # Model frame 
    #-------------------------------------------
    set f $parent.fModel
    DevAddButton $f.bLoad "Load Model" "fMRIEngineLoadModel"   13 
    $f.bLoad configure -state disabled
    DevAddButton $f.bSave "Save Model" "fMRIEngineSaveModel"   13 
    $f.bSave configure -state disabled
    DevAddButton $f.bView "View Model" "fMRIEngineViewModel"   13 
    DevAddButton $f.bClear "Clear Model" "fMRIEngineClearModel" 13 
    grid $f.bLoad $f.bSave -padx 1 -pady 1 -sticky e
    grid $f.bView $f.bClear -padx 1 -pady 1 -sticky e

    #-------------------------------------------
    # Tabs frame 
    #-------------------------------------------
    fMRIEngineBuildUIForTasks $parent.fTasks
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineLoadModel
# Loads a saved model 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineLoadModel {} {
    global fMRIEngine Gui
    
    puts "load model"
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineSaveModel
# Saves the current model 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineSaveModel {} {
    global fMRIEngine Gui
    
    puts "save model"
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineClearModel
# Clears the current model 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineClearModel {} {
    global fMRIEngine

    set fMRIEngine(baselineEVsAdded)  0
 
    # clear paradigm design panel
    set fMRIEngine(paradigmDesignType) blocked
    set fMRIEngine(checkbuttonRunIdentical) 0
    
    fMRIEngineSelectRunForConditionConfig 1

    set fMRIEngine(entry,title) ""
    set fMRIEngine(entry,tr) ""
    set fMRIEngine(entry,startVol) ""
    set fMRIEngine(entry,onsets) ""
    set fMRIEngine(entry,durations) ""

    fMRIEngineSelectRunForConditionShow 1

    $fMRIEngine(condsListBox) delete 0 end 

    for {set r 1} {$r <= $fMRIEngine(noOfSpecifiedRuns)} {incr r} {
        if {[info exists fMRIEngine($r,conditionList)]} {
            foreach title $fMRIEngine($r,conditionList) {
                unset -nocomplain fMRIEngine($r,$title,title)
                unset -nocomplain fMRIEngine($r,$title,startVol)
                unset -nocomplain fMRIEngine($r,$title,onsets)
                unset -nocomplain fMRIEngine($r,$title,durations)
            }
            unset -nocomplain fMRIEngine($r,tr)
            unset -nocomplain fMRIEngine($r,conditionList)
        }
    }

    # clear signal modeling panel
    fMRIEngineUpdateConditionsForSignalModeling 
    fMRIEngineSelectWaveFormForSignalModeling {Box Car} 
    fMRIEngineSelectConvolutionForSignalModeling {none} 
    fMRIEngineSelectHighpassForSignalModeling {none} 
    fMRIEngineInitDefaultHighpassTemporalCutoff 
    #fMRIEngineSelectLowpassForSignalModeling {none}
    #--- wjp 09/01/05
    set fMRIEngine(numDerivatives) 0
    #set fMRIEngine(checkbuttonTempDerivative) 0
    set fMRIEngine(checkbuttonGlobalEffects)  0

    set size [$fMRIEngine(evsListBox) size]
    set i 0
    while {$i < $size} {  
        set ev [$fMRIEngine(evsListBox) get $i] 
        if {$ev != ""} {
            unset -nocomplain fMRIEngine($ev,ev)            
            unset -nocomplain fMRIEngine($ev,run)
            unset -nocomplain fMRIEngine($ev,title,ev) 
            unset -nocomplain fMRIEngine($ev,condition,ev) 
            unset -nocomplain fMRIEngine($ev,waveform,ev)   
            unset -nocomplain fMRIEngine($ev,convolution,ev)
            unset -nocomplain fMRIEngine($ev,derivative,ev)
            unset -nocomplain fMRIEngine($ev,highpass,ev) 
            #unset -nocomplain fMRIEngine($ev,lowpass,ev) 
            unset -nocomplain fMRIEngine($ev,globaleffects,ev)
        }
        incr i
    }
    $fMRIEngine(evsListBox) delete 0 end 
    for {set r 1} {$r <= $fMRIEngine(noOfSpecifiedRuns)} {incr r} {
        set str "r$r:baseline"
        $fMRIEngine(evsListBox) insert end $str 
    }

    # clear contrasts panel
    set fMRIEngine(contrastOption) t 
    set fMRIEngine(entry,contrastName) ""
    set fMRIEngine(entry,contrastVolName) ""
    set fMRIEngine(entry,contrastVector) ""

    set size [$fMRIEngine(contrastsListBox) size]
    for {set i 0} {$i < $size} {incr i} {
        set name [$fMRIEngine(contrastsListBox) get $i] 
        if {$name != ""} {
            unset -nocomplain fMRIEngine($name,contrastName) 
            unset -nocomplain fMRIEngine($name,contrastVolName) 
            unset -nocomplain fMRIEngine($name,contrastVector)
        }
    } 
    $fMRIEngine(contrastsListBox) delete 0 end 

    # clear model view
    fMRIModelViewCloseAndCleanAndExit
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineViewModel
# Views the current model 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineViewModel {} {
    global fMRIEngine

    #--- wjp 10/27/05 -- need to count evs before viewing model...
    if {$fMRIEngine(noOfSpecifiedRuns) == 0} {
        DevErrorWindow "No run has been specified."
        return
    }

    if { ! [ fMRIEngineCountEVs] } {
        return
    }

    #--- are EVs defined for each specified run?
    #--- If not, don't view
    for {set r 1} {$r <= $fMRIEngine(noOfSpecifiedRuns)} {incr r} { 
        if {! [info exists fMRIEngine($r,noOfEVs)]} {
            DevErrorWindow "Complete signal modeling first for run$r."
            return
        }
    }

    #--- brittle test to see if all evs are defined yet for each run.
    #--- If not, don't view
    set count 0
    set size [$::fMRIEngine(evsListBox) size]
    for {set r 1} {$r <= $fMRIEngine(noOfSpecifiedRuns)} {incr r} { 
        #--- count number of conditions in each run.
        set conds [ llength $::fMRIEngine($r,conditionList)  ]
        set count [ expr $count + $conds ]
    }
    #--- add in baseline per run
    set count2 [ expr $count + $::fMRIEngine(noOfSpecifiedRuns) ]
    #--- are all conditions modeled?
    if { ($size != $count) && ($size != $count2) } {
        DevErrorWindow "Please model all conditions first"
        return
    }

    #--- looks reasonable. Count evs and launch view.
    if { [ fMRIEngineCountEVs ] } {
        fMRIModelViewLaunchModelView
    }
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineBuildUIForTasks
# Creates UI for tasks in model 
# .ARGS
# windowpath parent the parent frame 
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineBuildUIForTasks {parent} {
    global fMRIEngine Gui

    frame $parent.fTop  -bg $Gui(backdrop)
    frame $parent.fHelp -bg $Gui(activeWorkspace)
    frame $parent.fBot  -bg $Gui(activeWorkspace) -height 510
    pack $parent.fTop $parent.fHelp $parent.fBot \
        -side top -fill x -pady 2 -padx 5 

    #-------------------------------------------
    # Top frame 
    #-------------------------------------------
    set f $parent.fTop
    DevAddButton $f.bHelp "?" "fMRIEngineHelpSetup" 2 
    pack $f.bHelp -side left -padx 1 -pady 1 
 
    # Build pulldown task menu 
    eval {label $f.l -text "Specify:"} $Gui(BLA)
    pack $f.l -side left -padx $Gui(pad) -fill x -anchor w

    # Paradigm design is default task 
    set taskList [list {Paradigm} {Modeling} {Estimation} {Contrasts}]
    set df [lindex $taskList 0] 
    eval {menubutton $f.mbTask -text $df \
          -relief raised -bd 2 -width 33 \
          -indicatoron 1 \
          -menu $f.mbTask.m} $Gui(WMBA)
    eval {menu $f.mbTask.m} $Gui(WMA)
    pack  $f.mbTask -side left -pady 1 -padx $Gui(pad)

    # Save menubutton for config
    set fMRIEngine(gui,currentModelTask) $f.mbTask

    # Add menu items
    set count 1
    foreach m $taskList {
        $f.mbTask.m add command -label $m \
            -command "fMRIEngineSetModelTask {$m}"
    }

    #-------------------------------------------
    # Help frame 
    #-------------------------------------------
#    set f $parent.fHelp
#    DevAddButton $f.bHelp "?" "fMRIEngineShowHelp" 2 
#    pack $f.bHelp -side left -padx 5 -pady 1 

    #-------------------------------------------
    # Bottom frame 
    #-------------------------------------------
    set f $parent.fBot

    # Add menu items
    set count 1
    foreach m $taskList {
        # Makes a frame for each reader submodule
        frame $f.f$count -bg $Gui(activeWorkspace) 
        place $f.f$count -relwidth 1.0 -relx 0.0 -relheight 1.0 -rely 0.0 
        switch $m {
            "Paradigm" {
                fMRIEngineBuildUIForParadigmDesign $f.f$count
            }
            "Modeling" {
                fMRIEngineBuildUIForSignalModeling $f.f$count
            }
            "Estimation" {
                fMRIEngineBuildUIForModelEstimation $f.f$count
            }
            "Contrasts" {
                fMRIEngineBuildUIForContrasts $f.f$count
            }
        }
        set fMRIEngine(f$count) $f.f$count
        incr count
    }

    # raise the default one 
    raise $fMRIEngine(f1)

}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineSetModelTask
# Switches model task 
# .ARGS
# string task the model task 
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineSetModelTask {task} {
    global fMRIEngine
    
    set fMRIEngine(currentModelTask) $task

    # configure menubutton
    $fMRIEngine(gui,currentModelTask) config -text $task

    set count -1 
    switch $task {
        "Paradigm" {
            set count 1
        }
        "Modeling" {
            set count 2
            fMRIEngineUpdateConditionsForSignalModeling
       }
        "Estimation" {
            set count 3
        }
        "Contrasts" {
            set count 4
        }
    }

    set f  $fMRIEngine(f$count)
    raise $f
    focus $f
}


#-------------------------------------------------------------------------------
# .PROC fMRIEngineUpdateSetupTab
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc fMRIEngineUpdateSetupTab {} {
    global fMRIEngine

    set fMRIEngine(currentTab) "Set up"
}
