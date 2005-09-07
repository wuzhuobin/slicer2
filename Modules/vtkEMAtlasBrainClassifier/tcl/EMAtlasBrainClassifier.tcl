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
# FILE:        EMAtlasBrainClassifier.tcl
# PROCEDURES:  
#   EMAtlasBrainClassifierInit
#   EMAtlasBrainClassifierBuildGUI
#   EMAtlasBrainClassifierBuildVTK
#   EMAtlasBrainClassifierEnter
#   EMAtlasBrainClassifierExit
#   EMAtlasBrainClassifierUpdateMRML
#   EMAtlasBrainClassifierDefineWorkingDirectory
#   EMAtlasBrainClassifierDefineAtlasDir
#   EMAtlasBrainClassifierDefineXMLTemplate
#   EMAtlasBrainClassifier_Normalize VolIDInput VolIDOutput Mode
#   EMAtlasBrainClassifierVolumeWriter VolID
#   EMAtlasBrainClassifierReadXMLFile FileName
#   EMAtlasBrainClassifierGrepLine input search_string
#   EMAtlasBrainClassifierReadNextKey input
#   EMAtlasBrainClassifierLoadAtlasVolume GeneralDir AtlasDir AtlasName
#   EMAtlasBrainClassifierResetEMSegment
#   EMAtlasBrainClassifierDeleteAllVolumeNodesButSPGRAndT2W
#   EMAtlasBrainClassifierStartSegmentation
#   EMAtlasBrainClassifierRegistration inTarget inSource
#   EMAtlasBrainClassifierResample inTarget inSource outResampled
#==========================================================================auto=
#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifierInit
#  The "Init" procedure is called automatically by the slicer.  
#  It puts information about the module into a global array called Module, 
#  and it also initializes module-level variables.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifierInit {} {
    global EMAtlasBrainClassifier Module Volume env Mrml tcl_platform

    set m EMAtlasBrainClassifier

    set Module($m,overview) "Easy to use segmentation tool for brain MRIs"
    set Module($m,author)   "Kilian, Pohl, MIT, pohl@csail.mit.edu"
    set Module($m,category) "Segmentation"

    set Module($m,row1List) "Help Segmentation Advanced"
    set Module($m,row1Name) "{Help} {Segmentation} {Advanced}"
    set Module($m,row1,tab) Segmentation

    #   procStorePresets  = Called when the user holds down one of the Presets
    #               buttons.
    #               
    #   Note: if you use presets, make sure to give a preset defaults
    #   string in your init function, of the form: 
    #   set Module($m,presets) "key1='val1' key2='val2' ..."
    #   
    set Module($m,procGUI)   EMAtlasBrainClassifierBuildGUI
    set Module($m,procVTK)   EMAtlasBrainClassifierBuildVTK
    set Module($m,procEnter) EMAtlasBrainClassifierEnter
    set Module($m,procExit)  EMAtlasBrainClassifierExit
    set Module($m,procMRML)  EMAtlasBrainClassifierUpdateMRML

    # Define Dependencies
    #------------------------------------
    # Description:
    #   Record any other modules that this one depends on.  This is used 
    #   to check that all necessary modules are loaded when Slicer runs.
    #   
    # Kilian: I  currently deactivated it so I wont get nestay error messages 
    set Module($m,depend) ""

    lappend Module(versions) [ParseCVSInfo $m \
        {$Revision: 1.12 $} {$Date: 2005/09/07 05:09:21 $}]


    set EMAtlasBrainClassifier(Volume,SPGR) $Volume(idNone)
    set EMAtlasBrainClassifier(Volume,T2W)  $Volume(idNone)
    set EMAtlasBrainClassifier(Save,SPGR)    0
    set EMAtlasBrainClassifier(Save,T2W)     0
    set EMAtlasBrainClassifier(Save,Atlas)   1
    set EMAtlasBrainClassifier(Save,Segmentation) 1
    set EMAtlasBrainClassifier(Save,XMLFile) 1

    # Debug 
    set EMAtlasBrainClassifier(WorkingDirectory) "$Mrml(dir)/EMSeg"    
    # set EMAtlasBrainClassifier(WorkingDirectory) "/data/projects/EMAtlasClassifierValidationV2"
    set EMAtlasBrainClassifier(DefaultAtlasDir)  "$env(SLICER_HOME)/Modules/vtkEMAtlasBrainClassifier/atlas"   
    set EMAtlasBrainClassifier(AtlasDir)         $EMAtlasBrainClassifier(DefaultAtlasDir)  
    set EMAtlasBrainClassifier(XMLTemplate)      "$env(SLICER_HOME)/Modules/vtkEMAtlasBrainClassifier/template5_c2.xml"     

    set EMAtlasBrainClassifier(Normalize,SPGR) "90"
    set EMAtlasBrainClassifier(Normalize,T2W)  "310"

    if {[info exists EMAtlasBrainClassifier(Batch)] ==0} {
       set EMAtlasBrainClassifier(Batch) 0 
    } else {
       if {$EMAtlasBrainClassifier(Batch)} {
         puts "Run in Batch mode"  
       }
    }

    if {$tcl_platform(byteOrder) == "littleEndian"} {
        set EMAtlasBrainClassifier(LittleEndian) 1
    } else {
    set EMAtlasBrainClassifier(LittleEndian) 0 
    }

    set EMAtlasBrainClassifier(eventManager) {}

}

#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifierBuildGUI
# Build Gui
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifierBuildGUI {} {
    global Gui EMAtlasBrainClassifier Module Volume 
    
    set help "The EMAtlasBrainClassifier module is an easy to use segmentation tool for Brain MRIs. Just define the Brain SPGR and T2W input images 
              and the tool will automatically segment the image into white matter , gray matter, and cortical spinal fluid. 
              Be warned, this process might take longer because we first have to non-rigidly register the atlas to the patient." 

    regsub -all "\n" $help {} help
    MainHelpApplyTags EMAtlasBrainClassifier $help
    MainHelpBuildGUI EMAtlasBrainClassifier

    #-------------------------------------------
    # Segementation frame
    #-------------------------------------------
    set fSeg $Module(EMAtlasBrainClassifier,fSegmentation)
    set f $fSeg
    
    foreach frame "Step1 Step2" {
      frame $f.f$frame -bg $Gui(activeWorkspace)
      pack $f.f$frame -side top -padx 0 -pady $Gui(pad) -fill x
    }
    
    #-------------------------------------------
    # 1. Step 
    #-------------------------------------------
    set f $fSeg.fStep1

    DevAddLabel $f.lTitle "1. Define Input Channels: "
    pack $f.lTitle -side top -padx $Gui(pad) -pady 1 -anchor w

    foreach frame "Left Right" {
      frame $f.f$frame -bg $Gui(activeWorkspace)
      pack $f.f$frame -side left -padx 0 -pady $Gui(pad)
    }

    foreach Input "SPGR T2W" {
      DevAddLabel $f.fLeft.l$Input "  ${Input}:"
      pack $f.fLeft.l$Input -side top -padx $Gui(pad) -pady 1 -anchor w
      
      set menubutton   $f.fRight.m${Input}Select 
      set menu        $f.fRight.m${Input}Select.m
      
      eval {menubutton $menubutton -text [Volume($EMAtlasBrainClassifier(Volume,${Input}),node) GetName] -relief raised -bd 2 -width 9 -menu $menu} $Gui(WMBA)
      eval {menu $menu} $Gui(WMA)
      TooltipAdd $menubutton "Select Volume defining ${Input}" 
      set EMAtlasBrainClassifier(mbSeg-${Input}Select) $menubutton
      set EMAtlasBrainClassifier(mSeg-${Input}Select) $menu
          # Have to update at UpdateMRML too 
      DevUpdateNodeSelectButton Volume EMAtlasBrainClassifier Seg-${Input}Select Volume,$Input
      
      pack $menubutton -side top  -padx $Gui(pad) -pady 1 -anchor w
   }

    #-------------------------------------------
    # 2. Step 
    #-------------------------------------------
    set f $fSeg.fStep2

    DevAddLabel $f.lTitle "2. Save Results: "
    pack $f.lTitle -side top -padx $Gui(pad) -pady 0 -anchor w

    foreach frame "Left Right" {
      frame $f.f$frame -bg $Gui(activeWorkspace)
      pack $f.f$frame -side left -padx 0 -pady $Gui(pad)
    }

    DevAddLabel $f.fLeft.lOutput "  Save Segmentation:" 
    pack $f.fLeft.lOutput -side top -padx $Gui(pad) -pady 2  -anchor w

    frame $f.fRight.fOutput -bg $Gui(activeWorkspace)
    TooltipAdd  $f.fRight.fOutput "Automatically save the segmentation results to the working directory" 

    pack $f.fRight.fOutput -side top -padx 0 -pady 2  -anchor w

    foreach value "1 0" text "On Off" width "4 4" {
    eval {radiobutton $f.fRight.fOutput.r$value -width $width -indicatoron 0\
          -text "$text" -value "$value" -variable EMAtlasBrainClassifier(Save,Segmentation) } $Gui(WCA)
    pack $f.fRight.fOutput.r$value -side left -padx 0 -pady 0 
    }

    # Now define working directory
    DevAddLabel $f.fLeft.lWorking "  Working Directory:" 
    pack $f.fLeft.lWorking -side top -padx $Gui(pad) -pady 2  -anchor w

    frame $f.fRight.fWorking -bg $Gui(activeWorkspace)
    TooltipAdd  $f.fRight.fWorking "Working directory in which any results of the segmentations should be saved in" 
    pack $f.fRight.fWorking -side top -padx 0 -pady 2 -anchor w

    eval {entry  $f.fRight.fWorking.eDir   -width 15 -textvariable EMAtlasBrainClassifier(WorkingDirectory) } $Gui(WEA)
    eval {button $f.fRight.fWorking.bSelect -text "..." -width 2 -command "EMAtlasBrainClassifierDefineWorkingDirectory"} $Gui(WBA)     
    pack $f.fRight.fWorking.eDir  $f.fRight.fWorking.bSelect -side left -padx 0 -pady 0  

    #-------------------------------------------
    # Run Algorithm
    #------------------------------------------
    eval {button $fSeg.bRun -text "Segment" -width 10 -command "EMAtlasBrainClassifierStartSegmentation"} $Gui(WBA)     
    pack $fSeg.bRun -side top -padx 2 -pady 2  

    #-------------------------------------------
    # Segementation frame
    #-------------------------------------------
    set fSeg $Module(EMAtlasBrainClassifier,fAdvanced)
    set f $fSeg

    foreach frame "Save Misc" {
      frame $f.f$frame -bg $Gui(activeWorkspace) -relief sunken -bd 2
      pack $f.f$frame -side top -padx 0 -pady $Gui(pad) -fill x
    }

    DevAddLabel $f.fSave.lTitle "Save"  
    pack $f.fSave.lTitle -side top -padx $Gui(pad) -pady 2 
    foreach Att "SPGR T2W Atlas XMLFile"  Text "{Normalized SPGR} {Normalized T2W} {Aligned Atlas} {XML-File}" {
    eval {checkbutton  $f.fSave.c$Att -text "$Text" -variable EMAtlasBrainClassifier(Save,$Att) -indicatoron 1} $Gui(WCA)
    pack $f.fSave.c$Att  -side top -padx $Gui(pad) -pady 0 -anchor w 
    }

    DevAddLabel $f.fMisc.lTitle "Miscellaneous"  
    pack  $f.fMisc.lTitle -side top -padx $Gui(pad) -pady 2 

    
    foreach frame "Left Right" {
      frame $f.fMisc.f$frame -bg $Gui(activeWorkspace)
      pack $f.fMisc.f$frame -side left -padx 0 -pady $Gui(pad)
    }

    foreach Att "XMLTemplate AtlasDir" Text "{XML-Template File} {Atlas Directory}" Help "{XML Template file to be used for the segmentation} {Location of the atlases which define spatial distribtution}" {
    DevAddLabel $f.fMisc.fLeft.l$Att "${Text}:"  
    pack $f.fMisc.fLeft.l$Att -side top -padx 2 -pady 2  -anchor w 

    frame $f.fMisc.fRight.f$Att  -bg $Gui(activeWorkspace)
    pack $f.fMisc.fRight.f$Att -side top -padx 2 -pady 2  

    eval {entry  $f.fMisc.fRight.f$Att.eFile   -width 15 -textvariable EMAtlasBrainClassifier($Att) } $Gui(WEA)
    eval {button $f.fMisc.fRight.f$Att.bSelect -text "..." -width 2 -command "EMAtlasBrainClassifierDefine$Att"} $Gui(WBA)     
    pack $f.fMisc.fRight.f$Att.eFile  $f.fMisc.fRight.f$Att.bSelect -side left -padx 0 -pady 0 
    TooltipAdd  $f.fMisc.fRight.f$Att  "$Help" 
    }
}
#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifierBuildVTK
# Build any vtk objects you wish here
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifierBuildVTK {} {

}

#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifierEnter
# Called when this module is entered by the user.  Pushes the event manager
# for this module. 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifierEnter {} {
    global EMAtlasBrainClassifier

    # Push event manager
    #------------------------------------
    # Description:
    #   So that this module's event bindings don't conflict with other 
    #   modules, use our bindings only when the user is in this module.
    #   The pushEventManager routine saves the previous bindings on 
    #   a stack and binds our new ones.
    #   (See slicer/program/tcl-shared/Events.tcl for more details.)
    pushEventManager $EMAtlasBrainClassifier(eventManager)
    set WarningMsg ""
    if {[catch "package require vtkAG"]} {
      set WarningMsg "${WarningMsg}- vtkAG" 
    }

    if {$WarningMsg != ""} {DevWarningWindow "Please install the following modules before working with this module: \n$WarningMsg"}
}


#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifierExit
# Called when this module is exited by the user.  Pops the event manager
# for this module.  
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifierExit {} {

    # Pop event manager
    #------------------------------------
    # Description:
    #   Use this with pushEventManager.  popEventManager removes our 
    #   bindings when the user exits the module, and replaces the 
    #   previous ones.
    #
    popEventManager
}

#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifierUpdateMRML
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifierUpdateMRML { } { 
    global EMAtlasBrainClassifier
    DevUpdateNodeSelectButton Volume EMAtlasBrainClassifier Seg-SPGRSelect Volume,SPGR
    DevUpdateNodeSelectButton Volume EMAtlasBrainClassifier Seg-T2WSelect  Volume,T2W
}

#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifierDefineWorkingDirectory
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifierDefineWorkingDirectory {} {
    global EMAtlasBrainClassifier
    set dir [tk_chooseDirectory -initialdir $EMAtlasBrainClassifier(WorkingDirectory)]
    if { $dir == "" } {
    return
    }
    set EMAtlasBrainClassifier(WorkingDirectory) "$dir"    
}

#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifierDefineAtlasDir
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifierDefineAtlasDir {} {
    global EMAtlasBrainClassifier
    set dir [tk_chooseDirectory -initialdir $EMAtlasBrainClassifier(AtlasDir) -title "Atlas Directory"]
    if { $dir == "" } {
    return
    }
    set EMAtlasBrainClassifier(AtlasDir) "$dir"    
}

#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifierDefineXMLTemplate
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifierDefineXMLTemplate {} {
    global EMAtlasBrainClassifier
    set file [tk_getOpenFile -title "XML Template File" -filetypes {{XML {.xml} }} -defaultextension .xml -initialdir [file dirname $EMAtlasBrainClassifier(XMLTemplate)]]
    if { $file == "" } {
    return
    }
    set EMAtlasBrainClassifier(XMLTemplate) "$file"    
}

#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifier_Normalize
# 
# .ARGS
# int VolIDInput input volume id
# int VolIDOutput output volume id
# string Mode
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifier_Normalize { VolIDInput VolIDOutput Mode } {
    global Volume Matrix EMAtlasBrainClassifier
    set Vol [Volume($VolIDInput,vol) GetOutput]
    puts [$Vol GetNumberOfScalarComponents] 
    vtkImageData hist
    # Generate Histogram with 1000 bins 
    vtkImageAccumulate ia
    ia SetInput $Vol
    ia SetComponentSpacing 1 1 1
    ia SetComponentOrigin 0 0 0
    ia SetComponentExtent 0 1000 0 0 0 0
    ia Update
    hist DeepCopy [ia GetOutput]
  
    # Get maximum image value 
    set max [lindex [ia GetMax] 0]
    puts $max
    set count 0
    set i 0

    # Find out the intensity value which is an uppwer bound for 99% of the voxels 
    # => Cut of the tail of the the histogram
    set Extent [[Volume($VolIDInput,vol) GetOutput] GetExtent]
    set Boundary [expr ([lindex $Extent 1] - [lindex $Extent 0] +1) * ([lindex $Extent 3] - [lindex $Extent 2] +1) * ([lindex $Extent 5] - [lindex $Extent 4] +1) * 0.99]
    while {$i < $max && $count < $Boundary} {    
      set val [hist GetScalarComponentAsFloat $i 0 0 0]
      set count [expr $count + $val]
      incr i
    }

    # max is now the upper bound intensity value for 99% of the voxels  
    set max $i 
    set min 0
    puts "Max: $max"
    puts "Min: $min"
    set width [expr $max / 5]
    puts "Width: $width"
    set fwidth [expr 1.0 / $width ]
    
    # Smooth histogram by applying a window of width with 20% of the intensity value 
    set sHistMax  [expr ($max - $min) - $width]
    for {set x 0} {$x <= $sHistMax } {incr x} { 
      set sHist($x) 0
      for {set k 0} {$k <= $width} {incr k} {
        set sHist($x) [expr [hist GetScalarComponentAsFloat [expr $x + $k] 0 0 0] + $sHist($x)]
      }
      set sHist($x) [expr $sHist($x) * $fwidth]
    }
   
    # Define the lower intensity value for calculating the mean of the historgram
    # - When noise is set to 0 then we reached the first peak in the smoothed out histogram
    #   We considere this area noise (or background) and therefore exclude it for the definition of the normalization factor  
    # - When through is set we reached the first minimum after the first peak which defines the lower bound of the intensity 
    #   value considered for calculating the Expected value of the histogram 
    set x [expr $min + 1]
    set trough [expr $min - 1]
    set noise 1
    incr  sHistMax -2 
    while {$x < $sHistMax && $trough < $min} {
       if {$noise == 1 && $sHist($x) > $sHist([expr $x + 1]) && $x > $min} {
          set noise 0
       } elseif { $sHist($x) < $sHist([expr $x + 1]) && $sHist([expr $x + 1]) < $sHist([expr $x + 2]) && $sHist([expr $x +2]) < $sHist([expr $x + 3]) } {
          set trough $x
       }
       incr x
    }

    puts "Threshold: $trough"

    # Calculate the mean intensity value of the voxels with range [trough, max]  
    vtkImageAccumulate ia2
    ia2 SetInput $Vol
    ia2 SetComponentSpacing 1 1 1
    ia2 SetComponentOrigin $trough 0 0
    ia2 SetComponentExtent 0 [expr $max - $trough] 0 0 0 0
    ia2 Update
    hist DeepCopy [ia2 GetOutput]
    set i $trough
    set total 0
    set num 0
    while {$i < [expr $width * 5]} {    
      set val [hist GetScalarComponentAsFloat [expr $i - $trough] 0 0 0]
      set total [expr $total + ($i * $val)]
      set num [expr $num + $val]
      incr i
    }
    # Normalize image by factor M which is the expect value in this range 
    set M [expr $total * 1.0 / $num]

    puts "M: $M"

    vtkImageMathematics im
    im SetInput1 $Vol
    im SetConstantK [expr ($EMAtlasBrainClassifier(Normalize,$Mode) / $M)]
    puts "Mode: $Mode"
 
    im SetOperationToMultiplyByK
    Volume($VolIDOutput,vol) SetImageData [im GetOutput]
    ia Delete
    im Delete
    ia2 Delete
    hist Delete
    puts "Done"
} 
 

#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifierVolumeWriter
# 
# .ARGS
# int VolID volume id specifying what to write out
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifierVolumeWriter {VolID} {
    global Volume Editor
    set prefix [MainFileGetRelativePrefix [Volume($VolID,node) GetFilePrefix]]
    set Editor(fileformat) Standard
 
    MainVolumesWrite $VolID $prefix 
    # RM unnecssary xml file 
    catch {file delete -force [file join [file dirname [Volume($VolID,node) GetFullPrefix]] [Volume($VolID,node) GetFilePrefix]].xml }
}

#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifierReadXMLFile
# 
# .ARGS
# path FileName
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifierReadXMLFile { FileName } {
    global EMAtlasBrainClassifier
    if {[catch {set fid [open $FileName r]} errmsg] == 1} {
      puts $errmsg
      return ""
    }

    set file [read $fid]

    if {[catch {close $fid} errorMessage]} {
    puts "Could not close file : ${errorMessage}"
        return ""
    }
    return $file 
}

#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifierGrepLine
# 
# .ARGS
# string input
# string search_string
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifierGrepLine {input search_string} {
    set foundIndex [string first $search_string  $input]
    if {$foundIndex < 0} {
        return "-1 -1"
    }

    set start [expr [string last "\n" [string range $input 0 [expr $foundIndex -1]]] +1]
    set last  [string first "\n" [string range  $input $start end]]

    if  {$last < 0} { set last  [expr [string length $input] -1] 
    } else { incr last $start}
    return "$start $last"
}

#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifierReadNextKey
# 
# .ARGS
# string input
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifierReadNextKey {input} {
    if {([regexp "^(\[^=\]*)\[\n\t \]*=\[\n\t \]*\['\"\](\[^'\"\]*)\['\"\](.*)$" \
             $input match key value input] != 0) && ([string equal -length 1 $input "/"] == 0)} {
    return "$key $value "
    }
    return "" 
}

#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifierLoadAtlasVolume
# In the future should probably be more independent but should work for right now 
# .ARGS
# path GeneralDir
# path AtlasDir
# string AtlasName
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifierLoadAtlasVolume {GeneralDir AtlasDir AtlasName XMLAtlasKey} {
    global Volume EMAtlasBrainClassifier

    # Create Node 
    MainMrmlBuildTreesVersion2.0 "$XMLAtlasKey"
    set VolID [expr $Volume(nextID) -1]

    # Replace key values
    Volume($VolID,node) SetFilePrefix "$GeneralDir/$AtlasDir/I"
    Volume($VolID,node) SetFullPrefix "$GeneralDir/$AtlasDir/I"
    Volume($VolID,node) SetName       $AtlasName

    # Read in Volume
    MainVolumesUpdateMRML
    MainUpdateMRML

    return $VolID 
}

#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifierResetEMSegment
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifierResetEMSegment { } {
    global EMSegment 
    eval {global} $EMSegment(MrmlNode,TypeList) 

    EMSegmentChangeClass 0
    set EMSegment(NumClassesNew) 0
    EMSegmentCreateDeleteClasses 1 1 0
    # now delete Nodes of Superclass 0
    if {$EMSegment(Cattrib,0,Node) != ""} {    
    MainMrmlDeleteNode SegmenterSuperClass [$EMSegment(Cattrib,0,Node) GetID]
    set EMSegment(Cattrib,0,Node) ""
    }

    foreach dir $EMSegment(CIMList) {
    if {$EMSegment(Cattrib,0,CIMMatrix,$dir,Node) != ""}  {
        MainMrmlDeleteNode SegmenterCIM [$EMSegment(Cattrib,0,CIMMatrix,$dir,Node) GetID]
        set EMSegment(Cattrib,0,CIMMatrix,$dir,Node) ""
    }
    } 

    if {$EMSegment(Cattrib,0,EndNode) != ""} {
    lappend  MrmlNodeDeleteList "EndSegmenterSuperClass [$EMSegment(Cattrib,0,EndNode) GetID]" 
    set EMSegment(Cattrib,0,EndNode) ""
    }

    # Delete All Remaining Segmenter Nodes that we might have forgotten 
    # Should only be node Segmenter and InputImages 
    set EMSegment(SegmenterNode) ""

    foreach node $EMSegment(MrmlNode,TypeList) {
    upvar #0 $node Array    
    foreach id $Array(idList) {
        # Add to the deleteList
        lappend Array(idListDelete) $id

        # Remove from the idList
        set i [lsearch $Array(idList) $id]
        set Array(idList) [lreplace $Array(idList) $i $i]

        # Remove node from tree, and delete it
        Mrml(dataTree) RemoveItem ${node}($id,node)
        ${node}($id,node) Delete
    }
    }
    MainUpdateMRML
    foreach node $EMSegment(MrmlNode,TypeList) {set ${node}(idListDelete) "" }
    MainMrmlUpdateIdLists "$EMSegment(MrmlNode,TypeList)"

}

#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifierDeleteAllVolumeNodesButSPGRAndT2W
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifierDeleteAllVolumeNodesButSPGRAndT2W { } {
   global  EMAtlasBrainClassifier Volume Mrml 

   foreach id $Volume(idList) {
        if {($id != $Volume(idNone)) && ($id != $EMAtlasBrainClassifier(Volume,SPGR)) && ($id != $EMAtlasBrainClassifier(Volume,T2W)) } {
            # Add to the deleteList
            lappend Volume(idListDelete) $id

            # Remove from the idList
            set i [lsearch $Volume(idList) $id]
            set Volume(idList) [lreplace $Volume(idList) $i $i]

            # Remove node from tree, and delete it
            Mrml(dataTree) RemoveItem Volume($id,node)
            Volume($id,node) Delete
        }
    }
    MainUpdateMRML
}

#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifierStartSegmentation
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifierStartSegmentation { } {
    global EMAtlasBrainClassifier Volume EMSegment Mrml tcl_platform 

    # ---------------------------------------------------------------
    # Check if input is set
    if {($EMAtlasBrainClassifier(Volume,SPGR) == $Volume(idNone)) || ($EMAtlasBrainClassifier(Volume,T2W) == $Volume(idNone))} {
    DevErrorWindow "Please define both SPGR and T2W before starting the segmentation" 
    return 
    } 

    if {([Volume($EMAtlasBrainClassifier(Volume,SPGR),node) GetName] == "NormedSPGR") || ([Volume($EMAtlasBrainClassifier(Volume,T2W),node) GetName] == "NormedT2W") } {
      DevErrorWindow "Please rename the SPGR and T2W Volume. They cannot be named NormedSPGR or NormedT2W" 
      return 
    }


    set Mrml(dir) $EMAtlasBrainClassifier(WorkingDirectory)/EMSegmentation

    EMAtlasBrainClassifierDeleteAllVolumeNodesButSPGRAndT2W
    EMAtlasBrainClassifierResetEMSegment 
   
    # ---------------------------------------------------------------
    # 1. Step: Normalize images
    if (1) {
     foreach input "SPGR T2W" {
      # Create a New Volume
      puts "=========== Normalize $input ============ "
      set VolIDInput $EMAtlasBrainClassifier(Volume,${input})
      set VolIDOutput [DevCreateNewCopiedVolume $VolIDInput "" "Normed$input"]
      set Prefix "$EMAtlasBrainClassifier(WorkingDirectory)/[string tolower $input]/[file tail [Volume($EMAtlasBrainClassifier(Volume,${input}),node) GetFilePrefix]]norm"
      Volume($VolIDOutput,node) SetFilePrefix "$Prefix"
      Volume($VolIDOutput,node) SetFullPrefix "$Prefix" 
      Volume($VolIDOutput,node) SetFilePattern "%s.%03d"
      Volume($VolIDOutput,node) SetLittleEndian $EMAtlasBrainClassifier(LittleEndian)

      set EMAtlasBrainClassifier(Volume,Normalized${input}) $VolIDOutput

      # Normalize intentensities
      EMAtlasBrainClassifier_Normalize  $VolIDInput $VolIDOutput $input 

      # Clean Up 
      MainUpdateMRML
      RenderAll
      if {$EMAtlasBrainClassifier(Save,$input)} {
        EMAtlasBrainClassifierVolumeWriter $VolIDOutput  
      }
     }
    }
    # ---------------------------------------------------------------
    # 2. Step: Align atlas - wait for script from Sylvain
    # Read Template File to figure out which atlases to use for registration 
    # ---------------------------------------------------------------

    set RegisterAtlasDirList "" 
    set RegisterAtlasNameList "" 
    
    # ---------------------------------------------------------------
    # 2.a. Define which atlases to register 
    set XMLTemplateText [EMAtlasBrainClassifierReadXMLFile $EMAtlasBrainClassifier(XMLTemplate)]
    if {$XMLTemplateText == "" } {
      DevErrorWindow "Could not read template file $EMAtlasBrainClassifier(XMLTemplate) or it was empty!" 
      return
    }

    set NextLineIndex [EMAtlasBrainClassifierGrepLine "$XMLTemplateText" "<SegmenterClass"] 
    set NumCases 0
    while {$NextLineIndex != "-1 -1"} {
    set Line [string range "$XMLTemplateText" [lindex $NextLineIndex 0] [lindex $NextLineIndex 1]]
    set PriorPrefixIndex [string first "LocalPriorPrefix"  "$Line"]
    set PriorNameIndex   [string first "LocalPriorName"  "$Line"]

    if {($PriorPrefixIndex > -1) && ($PriorNameIndex > -1)} {
        set ResultPrefix [lindex [EMAtlasBrainClassifierReadNextKey  "[string range \"$Line\" $PriorPrefixIndex end]"] 1]
        set AtlasDir [file tail [file dirname $ResultPrefix]]
        set AtlasName   [lindex [EMAtlasBrainClassifierReadNextKey  "[string range \"$Line\" $PriorNameIndex end]"] 1]

        if {($ResultPrefix != "") && ($AtlasName != "") && ([lsearch $RegisterAtlasNameList "$AtlasName"] < 0) && ($AtlasDir != "") } {
        lappend  RegisterAtlasDirList "$AtlasDir"
        lappend  RegisterAtlasNameList "$AtlasName"
        }

    }
    set XMLTemplateText  [string range "$XMLTemplateText" [expr [lindex $NextLineIndex 1] +1] end]
    set NextLineIndex [EMAtlasBrainClassifierGrepLine "$XMLTemplateText" "<SegmenterClass"] 
    } 
  
    # ---------------------------------------------------------------
    # 2.b. Register Atlases 
    if {$RegisterAtlasDirList != "" } {

       # ---------------------------------------------------------------
       # 2.b.1. Check if we load the module for the first time 
       if {$EMAtlasBrainClassifier(AtlasDir) == $EMAtlasBrainClassifier(DefaultAtlasDir)} {
       set UploadNeeded 0 
       foreach atlas "spgr $RegisterAtlasDirList" {
           if {[file exists [file join $EMAtlasBrainClassifier(AtlasDir) $atlas I.001]] == 0} {
           set UploadNeeded 1
           break
           }
       }
           if {$UploadNeeded && ([EMAtlasBrainClassifierDownloadAtlas] == 0)} { return }
       } 

       # ---------------------------------------------------------------
       # 2.b.2. Check if we need to run registration

       puts "=========== Register atlas spgr with patient ============ "
       set RunRegistrationFlag 0 
       foreach Dir "$RegisterAtlasDirList" {
          if {[file exists $EMAtlasBrainClassifier(WorkingDirectory)/atlas/$Dir/I.001] == 0  } {
             set RunRegistrationFlag 1 
             break 
          }
       }

       if {$RunRegistrationFlag == 0 } {
         if {[DevYesNo "We found already an atlas in $EMAtlasBrainClassifier(WorkingDirectory)/atlas. Do you still want to register ? " ] == "yes" } {
           set RunRegistrationFlag 1
         }
       } 

       if {$RunRegistrationFlag} { 
          # ---------------------------------------------------------------
          # 2.b.3. Register atlas

          # 2.b.3.1 Read Default Parameters for All Atlas Files
          set XMLAtlasTemplateFile $EMAtlasBrainClassifier(AtlasDir)/template_atlas.xml
          if {[EMAtlasBrainClassifierReadXMLFile $XMLAtlasTemplateFile] == "" } {
                DevErrorWindow "Could not read template file $XMLAtlasTemplateFile or it was empty!" 
                return
          }
         
          set XMLAtlasKey [MainMrmlReadVersion2.x $XMLAtlasTemplateFile]
          if {$XMLAtlasKey == 0 } {return}
         
          if {[lindex [lindex $XMLAtlasKey 0] 0] != "Volume"} {
                DevErrorWindow "Template file $XMLAtlasTemplateFile is not of the correct format!" 
                return
          }


      # 2.b.3.2 Load Atlas SPGR 
          set TemplateIDInput $EMAtlasBrainClassifier(Volume,NormalizedSPGR)
          set VolIDSource      [EMAtlasBrainClassifierLoadAtlasVolume $EMAtlasBrainClassifier(AtlasDir) spgr  AtlasSPGR "$XMLAtlasKey"]
          if {$VolIDSource == "" } {return}
          set EMAtlasBrainClassifier(Volume,AtlasSPGR) $VolIDSource
       
          # Target file is the normalized SPGR
          set VolIDTarget $EMAtlasBrainClassifier(Volume,NormalizedSPGR)
          if {$VolIDTarget == "" } {return}

          # 2.b.3.3 Register Atlas SPGR to Normalized SPGR 
          puts "============= Start registeration"  
    
          EMAtlasBrainClassifierRegistration $VolIDTarget $VolIDSource
          # Define Registration output volume 
          set VolIDOutput [DevCreateNewCopiedVolume $TemplateIDInput "" "RegisteredSPGR"]
          # Resample the Atlas SPGR
          EMAtlasBrainClassifierResample  $VolIDTarget $VolIDSource $VolIDOutput
      
          # Clean up 
          if {$EMAtlasBrainClassifier(Save,Atlas)} {
             set Prefix "$EMAtlasBrainClassifier(WorkingDirectory)/atlas/spgr/I"
             Volume($VolIDOutput,node) SetFilePrefix "$Prefix"
             Volume($VolIDOutput,node) SetFullPrefix "$Prefix" 
         Volume($VolIDOutput,node) SetLittleEndian $EMAtlasBrainClassifier(LittleEndian)

             EMAtlasBrainClassifierVolumeWriter $VolIDOutput
          }
          MainMrmlDeleteNode Volume $VolIDSource 
          MainUpdateMRML
          RenderAll

          # 2.b.3.4 Resample other atlas files
          foreach Dir "$RegisterAtlasDirList" Name "$RegisterAtlasNameList" {
             puts "=========== Resample Atlas $Name  ============ "
             # Load In the New Atlases
             set VolIDInput [EMAtlasBrainClassifierLoadAtlasVolume $EMAtlasBrainClassifier(AtlasDir) $Dir Atlas_$Name "$XMLAtlasKey"]
             # Define Registration output volumes
             set VolIDOutput [DevCreateNewCopiedVolume $TemplateIDInput "" "$Name"]
             set Prefix "$EMAtlasBrainClassifier(WorkingDirectory)/atlas/$Dir/I"
             Volume($VolIDOutput,node) SetFilePrefix "$Prefix"
             Volume($VolIDOutput,node) SetFullPrefix "$Prefix" 
             Volume($VolIDOutput,node) SetLittleEndian $EMAtlasBrainClassifier(LittleEndian)

             # Resample the Atlas
             EMAtlasBrainClassifierResample  $VolIDTarget $VolIDInput $VolIDOutput  

             # Clean up 
             if {$EMAtlasBrainClassifier(Save,Atlas)} {EMAtlasBrainClassifierVolumeWriter $VolIDOutput}
             MainMrmlDeleteNode Volume $VolIDInput 
             MainUpdateMRML
             RenderAll
         }
       } else {
       # ---------------------------------------------------------------
       # 2.b.4. Load Atlas if it is already registered 
           puts "============= Skip registration - For Debugging - Only works if little endian of machine is the same as when the atlas was resampled" 
           set VolIDInput $EMAtlasBrainClassifier(Volume,SPGR)
           foreach Dir "$RegisterAtlasDirList" Name "$RegisterAtlasNameList" {
             puts "=========== Load Atlas $Name  ============ "
             # Load In the New Atlases
             set VolIDOutput [DevCreateNewCopiedVolume $VolIDInput "" "$Name"]
             Volume($VolIDOutput,node) SetFilePrefix "$EMAtlasBrainClassifier(WorkingDirectory)/atlas/$Dir/I"
             Volume($VolIDOutput,node) SetFullPrefix "$EMAtlasBrainClassifier(WorkingDirectory)/atlas/$Dir/I" 
             Volume($VolIDOutput,node) SetLittleEndian $EMAtlasBrainClassifier(LittleEndian)
             MainVolumesRead $VolIDOutput
             RenderAll
           }       
       }
    }

    # ---------------------------------------------------------------------- 
    # 3. Segment Image 

    # Read XML File  
    catch {exec mkdir $EMAtlasBrainClassifier(WorkingDirectory)/EMSegmentation} 
    set tags [MainMrmlReadVersion2.x $EMAtlasBrainClassifier(XMLTemplate)]
    set tags [MainMrmlAddColors $tags]
    MainMrmlBuildTreesVersion2.0 $tags
    MainUpdateMRML

    # Set Segmentation Boundary  so that if you have images of other dimension it will segment them correctly
    set VolID $EMAtlasBrainClassifier(Volume,SPGR)
    set EMSegment(SegmentationBoundaryMax,0) [lindex [Volume($VolID,node) GetDimensions] 0]
    set EMSegment(SegmentationBoundaryMax,1) [lindex [Volume($VolID,node) GetDimensions] 1]
    set Range [Volume($VolID,node) GetImageRange]
    set EMSegment(SegmentationBoundaryMax,2) [expr [lindex $Range 1] - [lindex $Range 0] + 1] 
    puts "=========== Segment Image ============ "
    # return
    # Start algorithm 
    EMAtlasBrainClassifier_StartEM


    if {$EMSegment(LatestLabelMap) == $Volume(idNone)} { 
        DevErrorWindow "Error: Could not segment subject"
    } else {
      set Prefix "$EMAtlasBrainClassifier(WorkingDirectory)/EMSegmentation/EMResult"
      set VolIDOutput $EMSegment(LatestLabelMap)
      Volume($VolIDOutput,node) SetFilePrefix "$Prefix"
      Volume($VolIDOutput,node) SetFullPrefix "$Prefix" 
      EMAtlasBrainClassifierVolumeWriter $VolIDOutput
    }
    # Change xml directory
    if {$EMAtlasBrainClassifier(Save,XMLFile)}      {MainMrmlWrite  $EMAtlasBrainClassifier(WorkingDirectory)/EMSegmentation/segmentation.xml}
    puts "=========== Finished  ============ "
}

#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifierDownloadAtlas
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifierDownloadAtlas { } {
    global EMAtlasBrainClassifier tcl_platform
    set text "The first time this module is used the Atlas data has to be dowloaded"
    set text "$text\nThis might take a while, so if you do not want to continue at "
    set text "$text\nthis point just press 'cancel'. \n"
    set text "$text\nIf you want to continue and you have PROBLEMS downloading the data please do the following:"
    set text "$text\nDowload the data from http://na-mic.org/Wiki/index.php/Slicer:Data_EMAtlas"
    set text "$text\nto [file dirname $EMAtlasBrainClassifier(AtlasDir)]"
    set text "$text\nand uncompress the file."       
         
    if {[DevOKCancel "$text" ] != "ok"} { return 0}
    DownloadInit
    if {$tcl_platform(os) == "Linux"} { 
    set urlAddress "http://na-mic.org/Wiki/images/8/8d/VtkEMAtlasBrainClassifier_AtlasDefault.tar.gz" 
    set outputFile "[file dirname $EMAtlasBrainClassifier(AtlasDir)]/atlas.tar.gz"
    } else {
    set urlAddress "http://na-mic.org/Wiki/images/5/57/VtkEMAtlasBrainClassifier_AtlasDefault.zip"
    set outputFile "[file dirname $EMAtlasBrainClassifier(AtlasDir)]/atlas.zip"
    }

    catch {exec rm -f $outputFile}
    catch {exec rm -rf $EMAtlasBrainClassifier(AtlasDir)}

    if {[DownloadFile "$urlAddress" "$outputFile"] == 0} {
    return 0
    }

    puts "Start extracting $outputFile ...." 
    if {$tcl_platform(os) == "Linux"} { 
    catch {exec rm -f [file rootname $outputFile]}
    puts "exec gunzip $outputFile"
    set OKFlag [catch {exec gunzip -f $outputFile} errormsg]
    if {$OKFlag == 0} {
        catch {exec rm -f atlas}
        puts "exec tar xf [file rootname $outputFile]]"
        set OKFlag [catch {exec tar xf [file rootname $outputFile]} errormsg]
        if {$OKFlag == 0} {
        puts "exec mv atlas ${EMAtlasBrainClassifier(AtlasDir)}/"
        set OKFlag [catch {exec mv atlas ${EMAtlasBrainClassifier(AtlasDir)}/}  errormsg]
        }
    }
    set RMFile [file rootname $outputFile]
    } else {
    set OKFlag [catch {exec unzip -o -qq $outputFile}  errormsg] 
    set RMFile $outputFile
    } 
    puts "... finished extracting"
    if {$OKFlag == 1} {
    DevErrorWindow "Could not uncompress $outputFile because of the following error message:\n$errormsg\nPlease manually uncompress the file."
    return 0
    } 
    DevInfoWindow "Atlas installation completed!" 
    catch {exec rm -f $RMFile} 
    return 1
}


#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifierRegistration
# 
# .ARGS
# int inTarget input target volume id
# int inSource
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifierRegistration {inTarget inSource} {
    global EMAtlasBrainClassifier Volume AG 
   
    
    catch "Target Delete"
    catch "Source Delete"
    vtkImageData Target
    vtkImageData Source

    puts "Initialize Source and Target"
    #If source and target have two channels, combine them into one vtkImageData object 
    Target DeepCopy  [ Volume($inTarget,vol) GetOutput]
    Source DeepCopy  [ Volume($inSource,vol) GetOutput]
    
    # Initial transform stuff
    catch "TransformEMAtlasBrainClassifier Delete"
    vtkGeneralTransform TransformEMAtlasBrainClassifier
    puts "No initial transform"
    TransformEMAtlasBrainClassifier PostMultiply 

    ## to be changed to EMAtlaspreprocess
    AGPreprocess Source Target $inSource $inTarget

    if { [info commands __dummy_transform] == ""} {
            vtkTransform __dummy_transform
    }

    puts "Start the linear registration"
    ###### Linear Tfm ######
    catch "GCR Delete"
    vtkImageGCR GCR
    GCR SetVerbose 1

    # Set i/o
    GCR SetTarget Target
    GCR SetSource Source
    GCR PostMultiply 
 
    # Set parameters
    GCR SetInput  __dummy_transform  
    [GCR GetGeneralTransform] SetInput TransformEMAtlasBrainClassifier
    ## Metric: 1=GCR-L1,2=GCR-L2,3=Correlation,4=MI
    GCR SetCriterion       4 
    ## Tfm type: -1=translation, 0=rigid, 1=similarity, 2=affine
    GCR SetTransformDomain 2 
    ## 2D registration only?
    GCR SetTwoD 0
  
    # Do it!
    GCR Update     
    TransformEMAtlasBrainClassifier Concatenate [[GCR GetGeneralTransform] GetConcatenatedTransform 1]

    # puts "For debigging only linear registration"     
    if {1} {
      ###### Warp #######
      catch "warp Delete"
      vtkImageWarp warp
      
      # Set i/o
      warp SetSource Source
      warp SetTarget Target 
      
      # Set the parameters
      warp SetVerbose 2
      [warp GetGeneralTransform] SetInput TransformEMAtlasBrainClassifier
      ## do tensor registration?
      warp SetResliceTensors 0 
      ## 1=demon, 2=optical flow 
      warp SetForceType 1          
      warp SetMinimumIterations  0 
      warp SetMaximumIterations  50
      ## What does it mean?
      warp SetMinimumLevel -1  
      warp SetMaximumLevel -1  
      ## Use SSD? 1 or 0 
      warp SetUseSSD 1
      warp SetSSDEpsilon  1e-3    
      warp SetMinimumStandardDeviation 0.85 
      warp SetMaximumStandardDeviation 1.25     

      # Do it!
      warp Update
      TransformEMAtlasBrainClassifier Concatenate warp
    }
  # save the transform
  set EMAtlasBrainClassifier(Transform) TransformEMAtlasBrainClassifier
}


#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifierResample
# 
# .ARGS
# int inTarget input target volume id
# int inSource volume id
# vtkImageData outResampled
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifierResample {inTarget inSource outResampled} {
    global EMAtlasBrainClassifier Volume Gui
    
    catch "Source Delete"
    vtkImageData Source  
    Source DeepCopy  [ Volume($inSource,vol) GetOutput]
    catch "Target Delete"
    vtkImageData Target
    Target DeepCopy  [ Volume($inTarget,vol) GetOutput]
    AGPreprocess Source Target $inSource $inTarget
  
    catch "Cast Delete"
    vtkImageCast Cast
    Cast SetInput Source
    Cast SetOutputScalarType [Target GetScalarType] 

    catch "ITrans Delete"
    vtkImageTransformIntensity ITrans
    ITrans SetInput [Cast GetOutput]

    catch "Reslicer Delete"
    vtkImageReslice Reslicer
    Reslicer SetInput [ITrans GetOutput]
    Reslicer SetInterpolationMode 1
    
    # We have to invers the transform before we reslice the grid.     
    Reslicer SetResliceTransform [$EMAtlasBrainClassifier(Transform)  GetInverse]
    
    # Reslicer SetInformationInput Target
    Reslicer SetInformationInput Target
    # Do it!
    Reslicer Update

    catch "Resampled Delete"
    vtkImageData Resampled
    Resampled DeepCopy [Reslicer GetOutput]

    Volume($outResampled,vol) SetImageData  Resampled
    Resampled SetOrigin 0 0 0
    Source Delete
    Target Delete
    Cast Delete
    ITrans Delete
    Reslicer Delete
}

#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifier_StartEM 
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------

proc EMAtlasBrainClassifier_StartEM { } {
   global EMSegment Volume Mrml env tcl_platform
   # ----------------------------------------------
   # 1. Update Values
   # ----------------------------------------------
   # -should not be necessary bc xml file is loaded
   # EMSegmentCalculateClassMeanCovariance
   # EMSegmentCalcProb
   # ----------------------------------------------
   # 2. Check Values and Update MRML Tree
   # ----------------------------------------------
   if {$EMSegment(NumInputChannel)  == 0} {
       DevErrorWindow "Please load a volume before starting the segmentation algorithm!"
       return
   }
   
   if {$EMSegment(Cattrib,0,StopEMMaxIter) <= 0} {
       DevErrorWindow "Please select a positive number of iterations (Step 2)"
       return
   }

   if {($EMSegment(SegmentationBoundaryMin,0) < 1) ||  ($EMSegment(SegmentationBoundaryMin,1) < 1) || ($EMSegment(SegmentationBoundaryMin,2) < 1)} {
       DevErrorWindow "Boundary box must be greater than 0 !" 
       return
   }
   set boundaryMax [EMSegmentSegmentationBoundaryMax 0]
   if  { ([lindex $boundaryMax 0] <  $EMSegment(SegmentationBoundaryMax,0)) || ([lindex $boundaryMax 1] <  $EMSegment(SegmentationBoundaryMax,1)) ||  ([lindex $boundaryMax 2] <  $EMSegment(SegmentationBoundaryMax,2))} {
       DevErrorWindow "Boundary Box exceed image limits !" 
       return
   }
   # ----------------------------------------------
   # 3. Call Algorithm
   # ----------------------------------------------
   set ErrorFlag 0
   set WarningFlag 0
   set VolIndex [lindex $EMSegment(SelVolList,VolumeList) 0]

   set EMSegment(VolumeNameList) ""
   foreach v $Volume(idList) {lappend EMSegment(VolumeNameList)  [Volume($v,node) GetName]}
   set NumInputImagesSet [EMAtlasBrainClassifier_AlgorithmStart] 


   EMSegment(vtkEMSegment) Update
   if {[EMSegment(vtkEMSegment) GetErrorFlag]} {
       set ErrorFlag 1
       DevErrorWindow "Error Report: \n[EMSegment(vtkEMSegment) GetErrorMessages]Fix errors before resegmenting !"
       RenderAll
   }
   if {[EMSegment(vtkEMSegment) GetWarningFlag]} {
       set WarningFlag 1
       puts "================================================"
       puts "Warning Report:"
       puts "[EMSegment(vtkEMSegment) GetWarningMessages]"
       puts "================================================"
   }
   
   # ----------------------------------------------
   # 4. Write Back Results - or print our error messages
   # ----------------------------------------------
   if {$ErrorFlag} {
       $EMSegment(MA-lRun) configure -text "Error occured during Segmentation"
   } else {
       if {$WarningFlag} {
          $EMSegment(MA-lRun) configure -text "Segmentation compledted sucessfull\n with warnings! Please read report!"
       } else {
          $EMSegment(MA-lRun) configure -text "Segmentation completed sucessfull"
       }
       incr EMSegment(SegmentIndex)

       set result [DevCreateNewCopiedVolume $VolIndex "" "EMSegResult$EMSegment(SegmentIndex)" ]
       set node [Volume($result,vol) GetMrmlNode]
       $node SetLabelMap 1
       Mrml(dataTree) RemoveItem $node 
       set nodeBefore [Volume($VolIndex,vol) GetMrmlNode]
       Mrml(dataTree) InsertAfterItem $nodeBefore $node

       # Display Result in label mode 
       Volume($result,vol) UseLabelIndirectLUTOn
       Volume($result,vol) Update
       Volume($result,node) SetLUTName -1
       Volume($result,node) SetInterpolate 0
       #  Write Solution to new Volume  -> Here the thread is called
       Volume($result,vol) SetImageData [EMSegment(vtkEMSegment) GetOutput]
       EMSegment(vtkEMSegment) Update
       # ----------------------------------------------
       # 5. Recover Values 
       # ----------------------------------------------
       # Update MRML Tree 
       # kilian - I think it is not necessary
       # if { $save_mode == "save" } {
       #    EMSegmentSaveSetting 0
       # }
       # Update MRML 
       MainUpdateMRML
   
       # This is necessary so that the data is updated correctly.
       # If the programmers forgets to call it, it looks like nothing
       # happened
       MainVolumesUpdate $result

       # Display segmentation in window . can also be set to Back 
       MainSlicesSetVolumeAll Fore $result
       MainVolumesRender
   }
   # ----------------------------------------------
   # 6. Clean up mess 
   # ----------------------------------------------
   # This is done so the vtk instance won't be called again when saving the model
   # if it does not work also do the same to the input of all the subclasses - should be fine 
   while {$NumInputImagesSet > 0} {
         incr NumInputImagesSet -1
         EMSegment(vtkEMSegment) SetImageInput $NumInputImagesSet "" 
   }
   
   if {[EMSegment(vtkEMSegment) GetErrorFlag] == 0} { 
       Volume($result,vol) SetImageData [EMSegment(vtkEMSegment) GetOutput]
   }
   EMSegment(vtkEMSegment) SetOutput ""
   
   EMAtlasBrainClassifier_DeleteVtkEMSegment
   MainUpdateMRML
   RenderAll
   
   # ----------------------------------------------
   # 7. Run Dice measure if necessary 
   # ----------------------------------------------
   if {$ErrorFlag == 0} { set EMSegment(LatestLabelMap) $result }
}


#-------------------------------------------------------------------------------
# .PROC  EMAtlasBrainClassifier_SetVtkGenericClassSetting
# Settings defined by vtkImageEMGenericClass, i.e. variables that have to be set for both CLASS and SUPERCLASS 
# Only loaded for private version 
# .ARGS
# string vtkGenericClass
# string Sclass
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifier_SetVtkGenericClassSetting {vtkGenericClass Sclass} {
  global EMSegment Volume
  $vtkGenericClass SetNumInputImages $EMSegment(NumInputChannel) 
  eval $vtkGenericClass SetSegmentationBoundaryMin $EMSegment(SegmentationBoundaryMin,0) $EMSegment(SegmentationBoundaryMin,1) $EMSegment(SegmentationBoundaryMin,2)
  eval $vtkGenericClass SetSegmentationBoundaryMax $EMSegment(SegmentationBoundaryMax,0) $EMSegment(SegmentationBoundaryMax,1) $EMSegment(SegmentationBoundaryMax,2)

  $vtkGenericClass SetProbDataWeight $EMSegment(Cattrib,$Sclass,LocalPriorWeight)

  $vtkGenericClass SetTissueProbability $EMSegment(Cattrib,$Sclass,Prob)
  $vtkGenericClass SetPrintWeights $EMSegment(Cattrib,$Sclass,PrintWeights)

  for {set y 0} {$y < $EMSegment(NumInputChannel)} {incr y} {
      if {[info exists EMSegment(Cattrib,$Sclass,InputChannelWeights,$y)]} {$vtkGenericClass SetInputChannelWeights $EMSegment(Cattrib,$Sclass,InputChannelWeights,$y) $y}
  }
}


#-------------------------------------------------------------------------------
# .PROC  EMAtlasBrainClassifier_SetVtkAtlasSuperClassSetting
# Setting up everything for the super classes  
# Only loaded for private version 
# .ARGS
# string SuperClass
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifier_SetVtkAtlasSuperClassSetting {SuperClass} {
  global EMSegment Volume

  catch { EMSegment(Cattrib,$SuperClass,vtkImageEMSuperClass) Delete}
  vtkImageEMAtlasSuperClass EMSegment(Cattrib,$SuperClass,vtkImageEMSuperClass)      

  # Define SuperClass specific parameters
  EMAtlasBrainClassifier_SetVtkGenericClassSetting EMSegment(Cattrib,$SuperClass,vtkImageEMSuperClass) $SuperClass

  EMSegment(Cattrib,$SuperClass,vtkImageEMSuperClass) SetPrintFrequency $EMSegment(Cattrib,$SuperClass,PrintFrequency)
  EMSegment(Cattrib,$SuperClass,vtkImageEMSuperClass) SetPrintBias      $EMSegment(Cattrib,$SuperClass,PrintBias)
  EMSegment(Cattrib,$SuperClass,vtkImageEMSuperClass) SetPrintLabelMap  $EMSegment(Cattrib,$SuperClass,PrintLabelMap)
  EMSegment(Cattrib,$SuperClass,vtkImageEMSuperClass) SetProbDataWeight $EMSegment(Cattrib,$SuperClass,LocalPriorWeight)
  
  set ClassIndex 0
  foreach i $EMSegment(Cattrib,$SuperClass,ClassList) {
    if {$EMSegment(Cattrib,$i,IsSuperClass)} {
        if {[EMAtlasBrainClassifier_SetVtkAtlasSuperClassSetting $i]} {return [EMSegment(Cattrib,$i,vtkImageEMSuperClass) GetErrorFlag]}
          EMSegment(Cattrib,$SuperClass,vtkImageEMSuperClass) AddSubClass EMSegment(Cattrib,$i,vtkImageEMSuperClass) $ClassIndex
    } else {
      catch {EMSegment(Cattrib,$i,vtkImageEMClass) destroy}
      vtkImageEMAtlasClass EMSegment(Cattrib,$i,vtkImageEMClass)      
      EMAtlasBrainClassifier_SetVtkGenericClassSetting EMSegment(Cattrib,$i,vtkImageEMClass) $i

      EMSegment(Cattrib,$i,vtkImageEMClass) SetLabel             $EMSegment(Cattrib,$i,Label) 

      if {$EMSegment(Cattrib,$i,ProbabilityData) != $Volume(idNone)} {
          # Pipeline does not automatically update volumes bc of fake first input  
          Volume($EMSegment(Cattrib,$i,ProbabilityData),vol) Update
          EMSegment(Cattrib,$i,vtkImageEMClass) SetProbDataPtr [Volume($EMSegment(Cattrib,$i,ProbabilityData),vol) GetOutput]
      
      } else {
         set EMSegment(Cattrib,$i,LocalPriorWeight) 0.0
      }
      EMSegment(Cattrib,$i,vtkImageEMClass) SetProbDataWeight $EMSegment(Cattrib,$i,LocalPriorWeight)

      for {set y 0} {$y < $EMSegment(NumInputChannel)} {incr y} {
          EMSegment(Cattrib,$i,vtkImageEMClass) SetLogMu $EMSegment(Cattrib,$i,LogMean,$y) $y
          for {set x 0} {$x < $EMSegment(NumInputChannel)} {incr x} {
            EMSegment(Cattrib,$i,vtkImageEMClass) SetLogCovariance $EMSegment(Cattrib,$i,LogCovariance,$y,$x) $y $x
          }
      }
      if {$EMSegment(IntensityAvgClass) == $EMSegment(Cattrib,$i,Label)} {
          # Transfere Intensity correction filter stuff
          set index 0
          EMSegment(vtkEMSegment) EMSetIntensityAvgClass  EMSegment(Cattrib,$i,vtkImageEMClass)
          foreach v $EMSegment(SelVolList,VolumeList) {       
             EMSegment(vtkEMSegment) SetIntensityAvgValuePreDef $EMSegment(IntensityAvgValue,$v) $index
             incr index
          } 
      }
      # Setup Quality Related information
      if {($EMSegment(Cattrib,$i,ReferenceStandardData) !=  $Volume(idNone)) && $EMSegment(Cattrib,$i,PrintQuality) } {
        EMSegment(Cattrib,$i,vtkImageEMClass) SetReferenceStandard [Volume($EMSegment(Cattrib,$i,ReferenceStandardData),vol) GetOutput]
      } 

      EMSegment(Cattrib,$i,vtkImageEMClass) SetPrintQuality $EMSegment(Cattrib,$i,PrintQuality)
      # After everything is defined add CLASS to its SUPERCLASS
      EMSegment(Cattrib,$SuperClass,vtkImageEMSuperClass) AddSubClass EMSegment(Cattrib,$i,vtkImageEMClass) $ClassIndex
    }
    incr ClassIndex
  }

  # After attaching all the classes we can defineMRF parameters
  set x 0  

  foreach i $EMSegment(Cattrib,$SuperClass,ClassList) {
      set y 0

      foreach j $EMSegment(Cattrib,$SuperClass,ClassList) {
        for {set k 0} { $k < 6} {incr k} {
           EMSegment(Cattrib,$SuperClass,vtkImageEMSuperClass) SetMarkovMatrix $EMSegment(Cattrib,$SuperClass,CIMMatrix,$i,$j,[lindex $EMSegment(CIMList) $k]) $k $y $x
        }
        incr y
      }
      incr x
  }
  # Automatically all the subclass are updated too and checked if values are set correctly 
  EMSegment(Cattrib,$SuperClass,vtkImageEMSuperClass) Update
  return [EMSegment(Cattrib,$SuperClass,vtkImageEMSuperClass) GetErrorFlag] 
}


#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifier_AlgorithmStart
# Sets up the segmentation algorithm
# Returns 0 if an Error Occured and 1 if it was successfull 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifier_AlgorithmStart { } {
   global EMSegment Volume 
   puts "Start EMAtlasBrainClassifier_AlgorithmStart"

   set NumInputImagesSet 0
   vtkImageEMAtlasSegmenter EMSegment(vtkEMSegment)
   
   # How many input images do you have
   EMSegment(vtkEMSegment) SetNumInputImages $EMSegment(NumInputChannel) 
   EMSegment(vtkEMSegment) SetNumberOfTrainingSamples $EMSegment(NumberOfTrainingSamples)

   if {[EMAtlasBrainClassifier_SetVtkAtlasSuperClassSetting 0]} { return 0 }

   # Transfer image information
   set NumInputImagesSet 0
   foreach v $EMSegment(SelVolList,VolumeList) {       
     EMSegment(vtkEMSegment) SetImageInput $NumInputImagesSet [Volume($v,vol) GetOutput]
     incr NumInputImagesSet
   }
   # Transfer Bias Print out Information
   EMSegment(vtkEMSegment) SetPrintDir $EMSegment(PrintDir)
   EMSegment(vtkEMSegment) SetHeadClass          EMSegment(Cattrib,0,vtkImageEMSuperClass)

   #----------------------------------------------------------------------------
   # Transfering General Information
   #----------------------------------------------------------------------------
   EMSegment(vtkEMSegment) SetAlpha           $EMSegment(Alpha) 

   EMSegment(vtkEMSegment) SetSmoothingWidth  $EMSegment(SmWidth)    
   EMSegment(vtkEMSegment) SetSmoothingSigma  $EMSegment(SmSigma)      

   EMSegment(vtkEMSegment) SetNumIter         $EMSegment(Cattrib,0,StopEMMaxIter) 
   EMSegment(vtkEMSegment) SetNumRegIter      $EMSegment(Cattrib,0,StopMFAMaxIter) 

   return  $EMSegment(NumInputChannel) 
}

#-------------------------------------------------------------------------------
# .PROC  EMAtlasBrainClassifier_SuperClassChildren 
# Finds out the all children, grandchildren and ... of a super class
# .ARGS
# string SuperClass
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifier_SuperClassChildren {SuperClass} {
    global EMSegment
    if {$EMSegment(Cattrib,$SuperClass,IsSuperClass) == 0} {
      return     $EMSegment(Cattrib,$SuperClass,Label)
    }
    set result ""
    foreach i $EMSegment(Cattrib,$SuperClass,ClassList) {
       if {$EMSegment(Cattrib,$i,IsSuperClass)} {
           # it is defined as SetType<TYPE> <ID>  
           set result "$result [EMSegmentSuperClassChildren $i]" 
       } else {
           lappend result $EMSegment(Cattrib,$i,Label)  
       }
     } 
     return $result
}

#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifier_DeleteVtkEMSuperClass
# Delete vtkImageEMSuperClass and children attached to it 
# .ARGS
# string Superclass
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifier_DeleteVtkEMSuperClass { SuperClass } {
   global EMSegment
   EMSegment(Cattrib,$SuperClass,vtkImageEMSuperClass) Delete
   foreach i $EMSegment(Cattrib,$SuperClass,ClassList) {
         if {$EMSegment(Cattrib,$i,IsSuperClass)} {
            EMAtlasBrainClassifier_DeleteVtkEMSuperClass  $i
         } else {
            EMSegment(Cattrib,$i,vtkImageEMClass) Delete
         }
   }  
}
#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifier_DeleteVtkEMSegment
# Delete vtkEMSegment related parameters 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifier_DeleteVtkEMSegment { } {
     global EMSegment
     EMSegment(vtkEMSegment) Delete
     EMAtlasBrainClassifier_DeleteVtkEMSuperClass 0
}
