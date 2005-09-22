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

##################
# Gui - Slicer 
##################

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
        {$Revision: 1.19 $} {$Date: 2005/09/22 01:32:36 $}]


    set EMAtlasBrainClassifier(Volume,SPGR) $Volume(idNone)
    set EMAtlasBrainClassifier(Volume,T2W)  $Volume(idNone)
    set EMAtlasBrainClassifier(Save,SPGR)    0
    set EMAtlasBrainClassifier(Save,T2W)     0
    set EMAtlasBrainClassifier(Save,Atlas)   1
    set EMAtlasBrainClassifier(Save,Segmentation) 1
    set EMAtlasBrainClassifier(Save,XMLFile) 1
    set EMAtlasBrainClassifier(SegmentIndex) 0
    set EMAtlasBrainClassifier(MaxInputChannelDef) 0
    set EMAtlasBrainClassifier(CIMList) {West North Up East South Down}

    # Debug 
    set EMAtlasBrainClassifier(WorkingDirectory) "$Mrml(dir)/EMSeg"    
    set EMAtlasBrainClassifier(DefaultAtlasDir)  "$env(SLICER_HOME)/Modules/vtkEMAtlasBrainClassifier/atlas"   
    set EMAtlasBrainClassifier(AtlasDir)         $EMAtlasBrainClassifier(DefaultAtlasDir)  
    set EMAtlasBrainClassifier(XMLTemplate)      "$env(SLICER_HOME)/Modules/vtkEMAtlasBrainClassifier/data/template5_c2.xml"     

    set EMAtlasBrainClassifier(Normalize,SPGR) "90"
    set EMAtlasBrainClassifier(Normalize,T2W)  "310"

    if {$tcl_platform(byteOrder) == "littleEndian"} {
        set EMAtlasBrainClassifier(LittleEndian) 1
    } else {
    set EMAtlasBrainClassifier(LittleEndian) 0 
    }

    # Initialize values 
    set EMAtlasBrainClassifier(MrmlNode,TypeList) "Segmenter SegmenterInput SegmenterSuperClass SegmenterClass SegmenterCIM"

    foreach NodeType "$EMAtlasBrainClassifier(MrmlNode,TypeList) SegmenterGenericClass" {
        set blubList [EMAtlasBrainClassifierDefineNodeAttributeList $NodeType]
        set EMAtlasBrainClassifier(MrmlNode,$NodeType,SetList)       [lindex $blubList 0]
        set EMAtlasBrainClassifier(MrmlNode,$NodeType,SetListLower)  [lindex $blubList 1]
        set EMAtlasBrainClassifier(MrmlNode,$NodeType,AttributeList) [lindex $blubList 2]
        set EMAtlasBrainClassifier(MrmlNode,$NodeType,InitValueList) [lindex $blubList 3]
    }

    set EMAtlasBrainClassifier(MrmlNode,JointSegmenterSuperClassAndClass,AttributeList) "$EMAtlasBrainClassifier(MrmlNode,SegmenterGenericClass,AttributeList) $EMAtlasBrainClassifier(MrmlNode,SegmenterSuperClass,AttributeList) $EMAtlasBrainClassifier(MrmlNode,SegmenterClass,AttributeList)"
    set EMAtlasBrainClassifier(MrmlNode,JointSegmenterSuperClassAndClass,InitValueList) "$EMAtlasBrainClassifier(MrmlNode,SegmenterGenericClass,InitValueList) $EMAtlasBrainClassifier(MrmlNode,SegmenterSuperClass,InitValueList) $EMAtlasBrainClassifier(MrmlNode,SegmenterClass,InitValueList)"

    foreach ListType "SetList SetListLower AttributeList InitValueList" {
        set EMAtlasBrainClassifier(MrmlNode,SegmenterSuperClass,$ListType) "$EMAtlasBrainClassifier(MrmlNode,SegmenterGenericClass,$ListType) $EMAtlasBrainClassifier(MrmlNode,SegmenterSuperClass,$ListType)"
        set EMAtlasBrainClassifier(MrmlNode,SegmenterClass,$ListType) "$EMAtlasBrainClassifier(MrmlNode,SegmenterGenericClass,$ListType) $EMAtlasBrainClassifier(MrmlNode,SegmenterClass,$ListType)"
    }



    # The second time around it is not deleted              
    set EMAtlasBrainClassifier(Cattrib,-1,ClassList) ""
    set EMAtlasBrainClassifier(SuperClass) -1
    set EMAtlasBrainClassifier(ClassIndex) 0
    set EMAtlasBrainClassifier(SelVolList,VolumeList) ""        
    EMAtlasBrainClassifierCreateClasses -1 1 

    set EMAtlasBrainClassifier(SuperClass) 0 
    set EMAtlasBrainClassifier(Cattrib,0,IsSuperClass) 1
    set EMAtlasBrainClassifier(Cattrib,0,Name) "Head"
    set EMAtlasBrainClassifier(Cattrib,0,Label) $EMAtlasBrainClassifier(Cattrib,0,Name)
    set EMAtlasBrainClassifier(BatchMode) 0
    set EMAtlasBrainClassifier(SegmentationMode) EMAtlasBrainClassifier

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
# .PROC EMAtlasBrainClassifierDefineNodeAttributeList
# Filters out all the SetCommands of a node 
# .ARGS
# string MrmlNodeType
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifierDefineNodeAttributeList {MrmlNodeType} {
    set SetList ""          
    set SetListLower ""
    set AttributeList ""
    set InitList ""

    vtkMrml${MrmlNodeType}Node blub
    set nMethods [blub ListMethods]

    set MrmlAtlasNodeType vtkMrmlSegmenterAtlas[string range $MrmlNodeType 9 end]Node:
    if {([lsearch $nMethods $MrmlAtlasNodeType] > -1)} {
    set StartSearch $MrmlAtlasNodeType
    } else {
        set StartSearch vtkMrml${MrmlNodeType}Node:
    }

    set nMethods "[lrange $nMethods [expr [lsearch $nMethods $StartSearch]+ 1] end]"

    foreach index [lsearch -glob -all $nMethods  Set*] {
        set SetCommand  [lindex $nMethods $index]
        if {[lsearch -exact $SetList $SetCommand] < 0} {
          lappend SetList $SetCommand
          lappend SetListLower [string tolower $SetCommand] 
          set Attribute [string range $SetCommand 3 end] 
          lappend AttributeList $Attribute
          lappend InitList "[blub Get$Attribute]" 
        }
    }
    blub Delete

    return "{$SetList} {$SetListLower} {$AttributeList} {$InitList}" 
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



##################
# Miscelaneous 
##################

#-------------------------------------------------------------------------------
# .PROC  EMAtlasBrainClassifierCreateClasses  
# Create classes
# .ARGS
# SuperClass class to start with 
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifierCreateClasses {SuperClass Number} {
    global EMAtlasBrainClassifier Volume

    set Cstart $EMAtlasBrainClassifier(ClassIndex)
    incr EMAtlasBrainClassifier(ClassIndex) $Number 
    for {set i $Cstart} {$i < $EMAtlasBrainClassifier(ClassIndex) } {incr i 1} {
      lappend EMAtlasBrainClassifier(Cattrib,$SuperClass,ClassList) $i 
      foreach NodeAttribute "$EMAtlasBrainClassifier(MrmlNode,JointSegmenterSuperClassAndClass,AttributeList)" InitValue "$EMAtlasBrainClassifier(MrmlNode,JointSegmenterSuperClassAndClass,InitValueList)" {
        set EMAtlasBrainClassifier(Cattrib,$i,$NodeAttribute) "$InitValue"  
      }
      set EMAtlasBrainClassifier(Cattrib,$i,Prob) 0.0 
      set EMAtlasBrainClassifier(Cattrib,$i,ClassList) ""
      set EMAtlasBrainClassifier(Cattrib,$i,IsSuperClass) 0

      for {set y 0} {$y <  $EMAtlasBrainClassifier(MaxInputChannelDef)} {incr y} {
          set  EMAtlasBrainClassifier(Cattrib,$i,LogMean,$y) -1
          for {set x 0} {$x <  $EMAtlasBrainClassifier(MaxInputChannelDef)} {incr x} { 
             set EMAtlasBrainClassifier(Cattrib,$i,LogCovariance,$y,$x) 0.0
          }
      }
      set EMAtlasBrainClassifier(Cattrib,$i,ProbabilityData) $Volume(idNone)
      set EMAtlasBrainClassifier(Cattrib,$i,ReferenceStandardData) $Volume(idNone)
      for {set j $Cstart} {$j < $EMAtlasBrainClassifier(ClassIndex) } {incr j 1} {
      foreach k $EMAtlasBrainClassifier(CIMList) {
          if {$i == $j} {set EMAtlasBrainClassifier(Cattrib,$SuperClass,CIMMatrix,$i,$j,$k) 1
              } else {set EMAtlasBrainClassifier(Cattrib,$SuperClass,CIMMatrix,$i,$j,$k) 0}
      }
      }
    }
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
 
    # Note : I changed vtkMrmlDataVolume.cxx so that MainVolumeWrite also works for 
    #        for volumes that do not start at slice 1. If it does not get checked into 
    #        the general version just do the following to overcome the problem after
    #        executing MainVolumesWrite:
    #        - Check if largest slice m is present 
    #        - if not => slices start at 1 .. n => move everything to m -n + 1 ,..., m 
    
    MainVolumesWrite $VolID $prefix 
    # RM unnecssary xml file 
    catch {file delete -force [file join [file dirname [Volume($VolID,node) GetFullPrefix]] [Volume($VolID,node) GetFilePrefix]].xml }
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
# .PROC EMAtlasBrainClassifier_InitilizePipeline 
# Checks parameters and sets up Mrml Tree
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifier_InitilizePipeline { } {
    global EMAtlasBrainClassifier Volume Mrml 

    if {($EMAtlasBrainClassifier(Volume,SPGR) == $Volume(idNone)) || ($EMAtlasBrainClassifier(Volume,T2W) == $Volume(idNone))} {
      DevErrorWindow "Please define both SPGR and T2W before starting the segmentation" 
      return 0
    } 

    if {([Volume($EMAtlasBrainClassifier(Volume,SPGR),node) GetName] == "NormedSPGR") || ([Volume($EMAtlasBrainClassifier(Volume,T2W),node) GetName] == "NormedT2W") } {
      DevErrorWindow "Please rename the SPGR and T2W Volume. They cannot be named NormedSPGR or NormedT2W" 
      return 0
    }

    if {[EMAtlasBrainClassifierReadXMLFile $EMAtlasBrainClassifier(XMLTemplate)] == "" } {
      DevErrorWindow "Could not read template file $EMAtlasBrainClassifier(XMLTemplate) or it was empty!" 
      return 0
    }

    set EMAtlasBrainClassifier(WorkingDirectory) [file normalize $EMAtlasBrainClassifier(WorkingDirectory)]
    set Mrml(dir) $EMAtlasBrainClassifier(WorkingDirectory)/EMSegmentation

    EMAtlasBrainClassifierDeleteAllVolumeNodesButSPGRAndT2W
    EMAtlasBrainClassifierResetEMSegment 

    return 1
}

##################
# XML 
##################

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

##################
# Normalize
##################

#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifier_Normalize
# 
# .ARGS
# int VolIDInput input volume id
# int VolIDOutput output volume id
# string Mode
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifier_Normalize { Mode } {
    global Volume EMAtlasBrainClassifier

    puts "=========== Normalize $Mode ============ "

    # Normalize Data
    vtkImageData outData 
    set VolIDInput $EMAtlasBrainClassifier(Volume,${Mode}) 
    EMAtlasBrainClassifier_NormalizeVolume [Volume($VolIDInput,vol) GetOutput] outData $Mode

    # Put Normilzed Data into Mrml Structure
    set VolIDOutput [DevCreateNewCopiedVolume $VolIDInput "" "Normed$Mode"]
    Volume($VolIDOutput,vol) SetImageData outData 
    outData Delete

    set Prefix "$EMAtlasBrainClassifier(WorkingDirectory)/[string tolower $Mode]/[file tail [Volume($EMAtlasBrainClassifier(Volume,${Mode}),node) GetFilePrefix]]norm"
    puts "--- $EMAtlasBrainClassifier(WorkingDirectory) $Prefix"
    Volume($VolIDOutput,node) SetFilePrefix "$Prefix"
    Volume($VolIDOutput,node) SetFullPrefix "$Prefix" 
    Volume($VolIDOutput,node) SetFilePattern "%s.%03d"
    Volume($VolIDOutput,node) SetLittleEndian $EMAtlasBrainClassifier(LittleEndian)

    set EMAtlasBrainClassifier(Volume,Normalized${Mode}) $VolIDOutput

    # Clean Up 
    MainUpdateMRML
    RenderAll

    if {$EMAtlasBrainClassifier(Save,$Mode)} {
    EMAtlasBrainClassifierVolumeWriter $VolIDOutput  
    }
}

#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifier_NormalizeVolume
# 
# .ARGS
# vtkImageData vol 
# vtkImageData out
# string Mode
# .END
#-------------------------------------------------------------------------------
# Kilian: I need this so I can also run it without MRML structure 
proc EMAtlasBrainClassifier_NormalizeVolume { Vol OutVol Mode } {
    global Volume Matrix EMAtlasBrainClassifier
    puts "Number Of Scalar: [$Vol GetNumberOfScalarComponents]" 
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
    puts "Absolute Max: $max"
    set count 0
    set i 0

    # Find out the intensity value which is an uppwer bound for 99% of the voxels 
    # => Cut of the tail of the the histogram
    set Extent [$Vol GetExtent]
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
    im Update 
    $OutVol DeepCopy [im GetOutput]

    ia Delete
    im Delete
    ia2 Delete
    hist Delete
    puts "Done"
} 
 

##################
# Registration
##################

#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifier_AtlasList 
# Defines list of atlases to be registered 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifier_AtlasList { } {
    global  EMAtlasBrainClassifier   
    set XMLTemplateText [EMAtlasBrainClassifierReadXMLFile $EMAtlasBrainClassifier(XMLTemplate)]

    set RegisterAtlasDirList "" 
    set RegisterAtlasNameList "" 
    
    set NextLineIndex [EMAtlasBrainClassifierGrepLine "$XMLTemplateText" "<SegmenterClass"] 

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
    return "{$RegisterAtlasDirList} {$RegisterAtlasNameList}" 
}


#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifier_RegistrationInitialize 
# Checks if atlas has to be dowloaded and if registration is necessary. Return values 
# -1 Atlas does not exist and could not be downloaded
#  0 Registered Atlas exists 
#  1 Atlas exists but has to be registered 
# .ARGS
# string RegisterAtlasDirList List of Atlases to be loaded
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifier_RegistrationInitialize {RegisterAtlasDirList} {
    global EMAtlasBrainClassifier

    # ---------------------------------------------------------------
    # Check if we load the module for the first time 
    if {$EMAtlasBrainClassifier(AtlasDir) == $EMAtlasBrainClassifier(DefaultAtlasDir)} {
    set UploadNeeded 0 
    foreach atlas "spgr $RegisterAtlasDirList" {
        if {[file exists [file join $EMAtlasBrainClassifier(AtlasDir) $atlas I.001]] == 0} {
        set UploadNeeded 1
            break
            }
        }
        if {$UploadNeeded && ([EMAtlasBrainClassifierDownloadAtlas] == 0)} { return -1}
    }

    # ---------------------------------------------------------------
    # Check if we need to run registration
    puts "=========== Initilize Registration of Atlas to Case  ============ "

    set RunRegistrationFlag 0 
    set StartSlice [format "%03d" [lindex [Volume($EMAtlasBrainClassifier(Volume,NormalizedSPGR),node) GetImageRange] 0]]
    foreach Dir "$RegisterAtlasDirList" {
       if {[file exists $EMAtlasBrainClassifier(WorkingDirectory)/atlas/$Dir/I.$StartSlice] == 0  } {
          set RunRegistrationFlag 1 
          break 
       }
    }
    
    if {$RunRegistrationFlag == 0 && ($EMAtlasBrainClassifier(BatchMode) == 0)} {
      if {[DevYesNo "We found already an atlas in $EMAtlasBrainClassifier(WorkingDirectory)/atlas. Do you still want to register ? " ] == "yes" } {
        set RunRegistrationFlag 1
      }
    } 
    # ---------------------------------------------------------------
    # Check if proper template file exist
    if {$RunRegistrationFlag == 1} {
    set XMLAtlasTemplateFile $EMAtlasBrainClassifier(AtlasDir)/template_atlas.xml
    if {[EMAtlasBrainClassifierReadXMLFile $XMLAtlasTemplateFile] == "" } {
        DevErrorWindow "Could not read template file $XMLAtlasTemplateFile or it was empty!" 
        return -1
    }
         
        set XMLAtlasKey [MainMrmlReadVersion2.x $XMLAtlasTemplateFile]
        if {$XMLAtlasKey == 0 } {return -1}
        
        if {[lindex [lindex $XMLAtlasKey 0] 0] != "Volume"} {
              DevErrorWindow "Template file $XMLAtlasTemplateFile is not of the correct format!" 
              return -1
        }
    }

    return $RunRegistrationFlag
}

#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifier_AtlasRegistration 
# Registers MRI of atlas and resamles atlas volume 
# .ARGS
# string  RegisterAtlasDirList  List of atlas directories to be loaded
# string  RegisterAtlasNameList List of atlas names to be loaded
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifier_AtlasRegistration {RegisterAtlasDirList RegisterAtlasNameList } {
   global EMAtlasBrainClassifier Volume  

   # ---------------------------------------------------------------
   # Set up Registration 

   # Read Atlas Parameters from XML file (how to load volumes)
   set XMLAtlasKey [MainMrmlReadVersion2.x $EMAtlasBrainClassifier(AtlasDir)/template_atlas.xml] 
  
   # Load Atlas SPGR 
   set TemplateIDInput $EMAtlasBrainClassifier(Volume,NormalizedSPGR)
   set VolIDSource      [EMAtlasBrainClassifierLoadAtlasVolume $EMAtlasBrainClassifier(AtlasDir) spgr  AtlasSPGR "$XMLAtlasKey"]
   if {$VolIDSource == "" } {return}
   set EMAtlasBrainClassifier(Volume,AtlasSPGR) $VolIDSource
  
   # Target file is the normalized SPGR
   set VolIDTarget $EMAtlasBrainClassifier(Volume,NormalizedSPGR)
   if {$VolIDTarget == "" } {return}
  
   # ---------------------------------------------------------------
   # Register Atlas SPGR to Normalized SPGR 
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
  
   # ---------------------------------------------------------------
   # Resample atlas files
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
}


#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifier_LoadAtlas
# Load the alredy registered atlas 
# .ARGS
# string  RegisterAtlasDirList  List of atlas directories to be loaded
# string  RegisterAtlasNameList List of atlas names to be loaded
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifier_LoadAtlas {RegisterAtlasDirList RegisterAtlasNameList } {
  global EMAtlasBrainClassifier Volume  
  set VolIDInput $EMAtlasBrainClassifier(Volume,SPGR)
  foreach Dir "$RegisterAtlasDirList" Name "$RegisterAtlasNameList" {
    puts "=========== Load Atlas $Name  ============ "
    set VolIDOutput [DevCreateNewCopiedVolume $VolIDInput "" "$Name"]
    Volume($VolIDOutput,node) SetFilePrefix "$EMAtlasBrainClassifier(WorkingDirectory)/atlas/$Dir/I"
    Volume($VolIDOutput,node) SetFullPrefix "$EMAtlasBrainClassifier(WorkingDirectory)/atlas/$Dir/I" 
    Volume($VolIDOutput,node) SetLittleEndian $EMAtlasBrainClassifier(LittleEndian)
    MainVolumesRead $VolIDOutput
    RenderAll
  }      
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
         
    if {$EMAtlasBrainClassifier(BatchMode)} {
    puts "$text"
    } else {
    if {[DevOKCancel "$text" ] != "ok"} { return 0}
    }

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

    if {$EMAtlasBrainClassifier(BatchMode)} {
    puts "Atlas installation completed!" 
    } else {
    DevInfoWindow "Atlas installation completed!" 
    }

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


##################
# EM Segmeneter 
##################

#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifier_InitilizeSegmentation
# Initilizes parameters for Segmentation with EMAtlasClassifier 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifier_InitilizeSegmentation {ValueFlag} {
    global EMAtlasBrainClassifier Volume EMSegment

    # Read XML File  
    catch {exec mkdir $EMAtlasBrainClassifier(WorkingDirectory)/EMSegmentation} 
    set tags [MainMrmlReadVersion2.x $EMAtlasBrainClassifier(XMLTemplate)]
    set tags [MainMrmlAddColors $tags]
    MainMrmlBuildTreesVersion2.0 $tags
    MainUpdateMRML

    if {$ValueFlag } {EMAtlasBrainClassifierInitializeValues }

    # Set Segmentation Boundary  so that if you have images of other dimension it will segment them correctly
    set VolID $EMAtlasBrainClassifier(Volume,SPGR)
    set Range [Volume($VolID,node) GetImageRange]

    set EMSegment(SegmentationBoundaryMax,0) [lindex [Volume($VolID,node) GetDimensions] 0]
    set EMSegment(SegmentationBoundaryMax,1) [lindex [Volume($VolID,node) GetDimensions] 1]
    set EMSegment(SegmentationBoundaryMax,2) [expr [lindex $Range 1] - [lindex $Range 0] + 1] 

    set EMAtlasBrainClassifier(SegmentationBoundaryMax,0) $EMSegment(SegmentationBoundaryMax,0) 
    set EMAtlasBrainClassifier(SegmentationBoundaryMax,1) $EMSegment(SegmentationBoundaryMax,1) 
    set EMAtlasBrainClassifier(SegmentationBoundaryMax,2) $EMSegment(SegmentationBoundaryMax,2) 

    if {$ValueFlag } { 
      set pid $EMAtlasBrainClassifier(vtkMrmlSegmenterNode)
      eval Segmenter($pid,node) SetSegmentationBoundaryMin "1 1 1"
      eval Segmenter($pid,node) SetSegmentationBoundaryMax "$EMAtlasBrainClassifier(SegmentationBoundaryMax,0) $EMAtlasBrainClassifier(SegmentationBoundaryMax,1) $EMAtlasBrainClassifier(SegmentationBoundaryMax,2)"
    }
}



#-------------------------------------------------------------------------------
# .PROC  EMAtlasBrainClassifierDeleteClasses  
# Deletes all classes
# .ARGS
# SuperClass class to start with 
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifierDeleteClasses {SuperClass} {
    global EMAtlasBrainClassifier
    # Initialize 

    set NumClasses [llength $EMAtlasBrainClassifier(Cattrib,$SuperClass,ClassList)] 
    if {$NumClasses == 0} { return }
    foreach i $EMAtlasBrainClassifier(Cattrib,$SuperClass,ClassList) {
    # It is a super class => destroy also all sub classes
    if {$EMAtlasBrainClassifier(Cattrib,$i,IsSuperClass)} {
        # -----------------------------
        # Delete all Subclasses
            EMAtlasBrainClassifierDeleteClasses $i
    }
        array unset EMAtlasBrainClassifier Cattrib,$SuperClass,CIMMatrix,$i,*
        array unset EMAtlasBrainClassifier Cattrib,$i,* 
    }
    set EMAtlasBrainClassifier(Cattrib,$SuperClass,ClassList) ""
    if {$SuperClass == 0} {set EMAtlasBrainClassifier(ClassIndex) 1}
}


#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifierInitializeValues 
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifierInitializeValues { } { 
    global EMAtlasBrainClassifier Mrml Volume Gui env
    # Current Desing of Node structure : (order is important !) 
    # Segmenter
    # -> SegmenterInput
    # -> SegmenterClass 
    # -> SegmenterCIM 
    # -> SegmenterSuperClass
    #    -> SegmenterClass 
    #    -> SegmenterCIM 

    set EMAtlasBrainClassifier(MaxInputChannelDef) 0
    # Current Number of Input Channels
    set EMAtlasBrainClassifier(NumInputChannel) 0

    set EMAtlasBrainClassifier(EMShapeIter)    1
    set EMAtlasBrainClassifier(Alpha)          0.7 
    set EMAtlasBrainClassifier(SmWidth)        11
    set EMAtlasBrainClassifier(SmSigma)        5 

    set EMAtlasBrainClassifier(SegmentationBoundaryMin,0) 1
    set EMAtlasBrainClassifier(SegmentationBoundaryMin,1) 1
    set EMAtlasBrainClassifier(SegmentationBoundaryMin,2) 1

    set EMAtlasBrainClassifier(SegmentationBoundaryMax,0) 256
    set EMAtlasBrainClassifier(SegmentationBoundaryMax,1) 256
    set EMAtlasBrainClassifier(SegmentationBoundaryMax,2) -1

    # How did I come up with the number 82 ? It is a long story ....
    set EMAtlasBrainClassifier(NumberOfTrainingSamples) 82

    EMAtlasBrainClassifierDeleteClasses 0
    set EMAtlasBrainClassifier(SelVolList,VolumeList) { }

    set SclassMemory ""

    Mrml(dataTree) ComputeTransforms
    Mrml(dataTree) InitTraversal
    set item [Mrml(dataTree) GetNextItem]
    while { $item != "" } {
       set ClassName [$item GetClassName]

       if { $ClassName == "vtkMrmlSegmenterNode" } {
          # --------------------------------------------------
          # 2.) Check if we already work on this Segmenter
          #     => if yes , do not do anything
          # -------------------------------------------------
          set pid [$item GetID]
          set EMAtlasBrainClassifier(vtkMrmlSegmenterNode) $pid
          set VolumeNameList ""
          foreach VolID $Volume(idList) {
            lappend VolumeNameList "[Volume($VolID,node) GetName]"
          }
          
          # --------------------------------------------------
          # 3.) Update variables 
          # -------------------------------------------------
          set EMAtlasBrainClassifier(MaxInputChannelDef)         [Segmenter($pid,node) GetMaxInputChannelDef]
          set BoundaryMin                                        [Segmenter($pid,node) GetSegmentationBoundaryMin]
          set BoundaryMax                                        [Segmenter($pid,node) GetSegmentationBoundaryMax]

          for {set i 0} {$i < 3} {incr i} { 
            set EMAtlasBrainClassifier(SegmentationBoundaryMin,$i) [lindex $BoundaryMin $i]
            set EMAtlasBrainClassifier(SegmentationBoundaryMax,$i) [lindex $BoundaryMax $i]
          }      
      
          # If the path is not the same, define all Segmenter variables
          # Delete old values Kilian: Could do it but would cost to much time 
          # This is more efficient - but theoretically could also start from stretch bc I 
          # only get this far when a new XML file is read ! If you get in problems just do the 
          # following (deletes everything) 
          set  NumClasses [Segmenter($pid,node) GetNumClasses]
          if {$NumClasses} { 
            EMAtlasBrainClassifierCreateClasses 0 $NumClasses
            set CurrentClassList $EMAtlasBrainClassifier(Cattrib,0,ClassList)       
          } else {
            set CurrentClassList 0
          }
      
          # Define all parameters without special consideration
          set EMiteration 0 
          set MFAiteration 0 
          
          foreach NodeAttribute $EMAtlasBrainClassifier(MrmlNode,Segmenter,AttributeList) { 
            switch $NodeAttribute {
              EMiteration { set EMiteration [Segmenter($pid,node) GetEMiteration] }
              MFAiteration { set MFAiteration [Segmenter($pid,node) GetMFAiteration]}
              default { set EMAtlasBrainClassifier($NodeAttribute)     [Segmenter($pid,node) Get${NodeAttribute}]}
            }
          }
          # Legacy purposes 
          if {$NumClasses} { 
             set EMAtlasBrainClassifier(Cattrib,0,StopEMMaxIter) $EMiteration
             set EMAtlasBrainClassifier(Cattrib,0,StopMFAMaxIter) $MFAiteration
          } 
        } elseif {$ClassName == "vtkMrmlSegmenterInputNode" } {
            # --------------------------------------------------
            # 5.) Update selected Input List 
            # -------------------------------------------------
            # find out the Volume correspnding to the following description
            set pid [$item GetID]        
            set FileName [SegmenterInput($pid,node) GetFileName]
            set VolIndex [lsearch $VolumeNameList $FileName]
            if {($VolIndex > -1) && ($FileName != "") } {  
                lappend EMAtlasBrainClassifier(SelVolList,VolumeList) [lindex $Volume(idList) $VolIndex] 
        incr EMAtlasBrainClassifier(NumInputChannel)
            }
       } elseif {$ClassName == "vtkMrmlSegmenterSuperClassNode" } {
         # puts "Start vtkMrmlSegmenterSuperClassNode"
          # --------------------------------------------------
          # 6.) Update variables for SuperClass 
          # -------------------------------------------------
          set pid [$item GetID]
          # If you get an error mesaage in the follwoing lines then CurrentClassList to short
          set NumClass [lindex $CurrentClassList 0]
          if {$NumClass == ""} { DevErrorWindow "Error in XML File : Super class $EMAtlasBrainClassifier(SuperClass)  has not enough sub-classes defined" }

          # Check If we initialize the head class 
          if {$NumClass == 0} {set InitiHeadClassFlag 1
          } else {set InitiHeadClassFlag 0}

          set EMAtlasBrainClassifier(Class) $NumClass 

          # Save status when returning to parent of this class 
          if {$InitiHeadClassFlag} {
             set SclassMemory ""
             set EMAtlasBrainClassifier(SuperClass) $NumClass
          } else  { 
             lappend SclassMemory [list "$EMAtlasBrainClassifier(SuperClass)" "[lrange $CurrentClassList 1 end]"] 
             # Transfer from Class to SuperClass
         set EMAtlasBrainClassifier(Cattrib,$NumClass,IsSuperClass) 1
             set EMAtlasBrainClassifier(SuperClass) $NumClass
          }
          set VolumeName  [SegmenterSuperClass($pid,node) GetLocalPriorName]
          set VolumeIndex [lsearch $VolumeNameList $VolumeName]
      if {($VolumeName != "") && ($VolumeIndex > -1) } { set EMAtlasBrainClassifier(Cattrib,$NumClass,ProbabilityData) [lindex $Volume(idList) $VolumeIndex]
      } else { set EMAtlasBrainClassifier(Cattrib,$NumClass,ProbabilityData) $Volume(idNone) }

          set InputChannelWeights [SegmenterSuperClass($pid,node) GetInputChannelWeights]
          for {set y 0} {$y < $EMAtlasBrainClassifier(MaxInputChannelDef)} {incr y} {
             if {[lindex $InputChannelWeights $y] == ""} {set EMAtlasBrainClassifier(Cattrib,$NumClass,InputChannelWeights,$y) 1.0
             } else {
               set EMAtlasBrainClassifier(Cattrib,$NumClass,InputChannelWeights,$y) [lindex $InputChannelWeights $y]
             }
          }

          # Create Sub Classes
          EMAtlasBrainClassifierCreateClasses $NumClass [SegmenterSuperClass($pid,node) GetNumClasses]
          set CurrentClassList $EMAtlasBrainClassifier(Cattrib,$EMAtlasBrainClassifier(SuperClass),ClassList)

          # Define all parameters without special consideration
          foreach NodeAttribute $EMAtlasBrainClassifier(MrmlNode,SegmenterSuperClass,AttributeList) { 
             set EMAtlasBrainClassifier(Cattrib,$NumClass,$NodeAttribute)     [SegmenterSuperClass($pid,node) Get${NodeAttribute}]
          }
          # For legacy purposes 
          if {$EMAtlasBrainClassifier(Cattrib,$NumClass,StopEMMaxIter) == 0} {set EMAtlasBrainClassifier(Cattrib,$NumClass,StopEMMaxIter) $EMiteration}
          if {$EMAtlasBrainClassifier(Cattrib,$NumClass,StopMFAMaxIter) == 0} {set EMAtlasBrainClassifier(Cattrib,$NumClass,StopMFAMaxIter) $MFAiteration}

    } elseif {$ClassName == "vtkMrmlSegmenterClassNode" } {
        # --------------------------------------------------
        # 7.) Update selected Class List 
        # -------------------------------------------------
        # If you get an error mesaage in the follwoing lines then CurrentClassList to short       
        set NumClass [lindex $CurrentClassList 0]
        if {$NumClass == ""} { DevErrorWindow "Error in XML File : Super class $EMAtlasBrainClassifier(SuperClass)  has not enough sub-classes defined" }
        set CurrentClassList [lrange $CurrentClassList 1 end]

        set EMAtlasBrainClassifier(Class) $NumClass
        set pid [$item GetID]
    set EMAtlasBrainClassifier(Cattrib,$NumClass,Label) [SegmenterClass($pid,node) GetLabel] 
        # Define all parameters that do not be specially considered
        foreach NodeAttribute $EMAtlasBrainClassifier(MrmlNode,SegmenterClass,AttributeList) { 
           set EMAtlasBrainClassifier(Cattrib,$NumClass,$NodeAttribute)     [SegmenterClass($pid,node) Get${NodeAttribute}]
        }

        set VolumeName  [SegmenterClass($pid,node) GetLocalPriorName]
        set VolumeIndex [lsearch $VolumeNameList $VolumeName]
        if {($VolumeName != "") && ($VolumeIndex > -1) } { set EMAtlasBrainClassifier(Cattrib,$NumClass,ProbabilityData) [lindex $Volume(idList) $VolumeIndex]
        } else { set EMAtlasBrainClassifier(Cattrib,$NumClass,ProbabilityData) $Volume(idNone) }

        set VolumeName  [SegmenterClass($pid,node) GetReferenceStandardFileName]
        set VolumeIndex [lsearch $VolumeNameList $VolumeName]
        if {($VolumeName != "") && ($VolumeIndex > -1) } { set EMAtlasBrainClassifier(Cattrib,$NumClass,ReferenceStandardData) [lindex $Volume(idList) $VolumeIndex]
        } else { set EMAtlasBrainClassifier(Cattrib,$NumClass,ReferenceStandardData) $Volume(idNone) }

        set index 0
        set LogCovariance  [SegmenterClass($pid,node) GetLogCovariance]
        set LogMean [SegmenterClass($pid,node) GetLogMean]
        set InputChannelWeights [SegmenterClass($pid,node) GetInputChannelWeights]
        for {set y 0} {$y < $EMAtlasBrainClassifier(MaxInputChannelDef)} {incr y} {
           set EMAtlasBrainClassifier(Cattrib,$NumClass,LogMean,$y) [lindex $LogMean $y]
           if {[lindex $InputChannelWeights $y] == ""} {set EMAtlasBrainClassifier(Cattrib,$NumClass,InputChannelWeights,$y) 1.0
        } else {
             set EMAtlasBrainClassifier(Cattrib,$NumClass,InputChannelWeights,$y) [lindex $InputChannelWeights $y]
        }
        for {set x 0} {$x < $EMAtlasBrainClassifier(MaxInputChannelDef)} {incr x} {
              set EMAtlasBrainClassifier(Cattrib,$NumClass,LogCovariance,$y,$x)  [lindex $LogCovariance $index]
              incr index
        }
        # This is for the extra character at the end of the line (';')
        incr index
      }
    } elseif {$ClassName == "vtkMrmlSegmenterCIMNode" } {
        # --------------------------------------------------
        # 8.) Update selected CIM List 
        # -------------------------------------------------
        set pid [$item GetID]        
        set dir [SegmenterCIM($pid,node) GetName]
        if {[lsearch $EMAtlasBrainClassifier(CIMList) $dir] > -1} { 
          set i 0
          set CIMMatrix [SegmenterCIM($pid,node) GetCIMMatrix]
          set EMAtlasBrainClassifier(Cattrib,$EMAtlasBrainClassifier(SuperClass),CIMMatrix,$dir,Node) $item
          foreach y $EMAtlasBrainClassifier(Cattrib,$EMAtlasBrainClassifier(SuperClass),ClassList) {
             foreach x $EMAtlasBrainClassifier(Cattrib,$EMAtlasBrainClassifier(SuperClass),ClassList) {
               set EMAtlasBrainClassifier(Cattrib,$EMAtlasBrainClassifier(SuperClass),CIMMatrix,$x,$y,$dir) [lindex $CIMMatrix $i]
               incr i
             }
             incr i
          }
        }
    } elseif {$ClassName == "vtkMrmlEndSegmenterSuperClassNode" } {
        # --------------------------------------------------
        # 11.) End of super class 
        # -------------------------------------------------
        # Pop the last parent from the Stack
        set temp [lindex $SclassMemory end]
        set SclassMemory [lreplace $SclassMemory end end]
        set CurrentClassList [lindex $temp 1] 
        set EMAtlasBrainClassifier(SuperClass) [lindex $temp 0] 
    } elseif {$ClassName == "vtkMrmlEndSegmenterNode" } {
        # --------------------------------------------------
        # 12.) End of Segmenter
        # -------------------------------------------------
        # if there is no EndSegmenterNode yet and we are reading one, and set
        # the EMAtlasBrainClassifier(EndSegmenterNode) variable
    if {[llength $EMAtlasBrainClassifier(Cattrib,0,ClassList)]} { set EMAtlasBrainClassifier(Class) [lindex $EMAtlasBrainClassifier(Cattrib,0,ClassList) 0]
    } else { set EMAtlasBrainClassifier(Class) 0 }
    }    
    set item [Mrml(dataTree) GetNextItem]
  }
}

#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifier_StartEM 
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------

proc EMAtlasBrainClassifier_StartEM { } {
   global EMAtlasBrainClassifier Volume Mrml env tcl_platform EMSegment
   # ----------------------------------------------
   # 2. Check Values and Update MRML Tree
   # ----------------------------------------------
   if {$EMAtlasBrainClassifier(NumInputChannel)  == 0} {
       DevErrorWindow "Please load a volume before starting the segmentation algorithm!"
       return
   }
   
   if {$EMAtlasBrainClassifier(Cattrib,0,StopEMMaxIter) <= 0} {
       DevErrorWindow "Please select a positive number of iterations (Step 2)"
       return
   }

   if {($EMAtlasBrainClassifier(SegmentationBoundaryMin,0) < 1) ||  ($EMAtlasBrainClassifier(SegmentationBoundaryMin,1) < 1) || ($EMAtlasBrainClassifier(SegmentationBoundaryMin,2) < 1)} {
       DevErrorWindow "Boundary box must be greater than 0 !" 
       return
   }
   # ----------------------------------------------
   # 3. Call Algorithm
   # ----------------------------------------------
   set ErrorFlag 0
   set WarningFlag 0
   set VolIndex [lindex $EMAtlasBrainClassifier(SelVolList,VolumeList) 0]

   set EMAtlasBrainClassifier(VolumeNameList) ""
   foreach v $Volume(idList) {
       lappend EMAtlasBrainClassifier(VolumeNameList)  [Volume($v,node) GetName]
   }
   set NumInputImagesSet [EMAtlasBrainClassifier_AlgorithmStart] 

   EMAtlasBrainClassifier(vtkEMAtlasBrainClassifier) Update
   if {[EMAtlasBrainClassifier(vtkEMAtlasBrainClassifier) GetErrorFlag]} {
       set ErrorFlag 1
       DevErrorWindow "Error Report: \n[EMAtlasBrainClassifier(vtkEMAtlasBrainClassifier) GetErrorMessages]Fix errors before resegmenting !"
       RenderAll
   }
   if {[EMAtlasBrainClassifier(vtkEMAtlasBrainClassifier) GetWarningFlag]} {
       set WarningFlag 1
       puts "================================================"
       puts "Warning Report:"
       puts "[EMAtlasBrainClassifier(vtkEMAtlasBrainClassifier) GetWarningMessages]"
       puts "================================================"
   }
   
   # ----------------------------------------------
   # 4. Write Back Results - or print our error messages
   # ----------------------------------------------
   if {$ErrorFlag} {
       $EMSegment(MA-lRun) configure -text "Error occured during Segmentation"
   } else {
       if {$WarningFlag} {
       if {$EMAtlasBrainClassifier(BatchMode)} {
           puts "Segmentation compledted sucessfull with warnings! Please read report!"
       } else { 
           $EMSegment(MA-lRun) configure -text "Segmentation compledted sucessfull\n with warnings! Please read report!"
       }
       } else {
       if {$EMAtlasBrainClassifier(BatchMode)} {
           puts "Segmentation completed sucessfull"
       } else {
           $EMSegment(MA-lRun) configure -text "Segmentation completed sucessfull"
       }
       }
       incr EMAtlasBrainClassifier(SegmentIndex)

       set result [DevCreateNewCopiedVolume $VolIndex "" "EMAtlasSegResult$EMAtlasBrainClassifier(SegmentIndex)" ]
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
       Volume($result,vol) SetImageData [EMAtlasBrainClassifier(vtkEMAtlasBrainClassifier) GetOutput]
       EMAtlasBrainClassifier(vtkEMAtlasBrainClassifier) Update
       # ----------------------------------------------
       # 5. Recover Values 
       # ----------------------------------------------
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
         EMAtlasBrainClassifier(vtkEMAtlasBrainClassifier) SetImageInput $NumInputImagesSet "" 
   }
   
   if {[EMAtlasBrainClassifier(vtkEMAtlasBrainClassifier) GetErrorFlag] == 0} { 
       Volume($result,vol) SetImageData [EMAtlasBrainClassifier(vtkEMAtlasBrainClassifier) GetOutput]
   }
   EMAtlasBrainClassifier(vtkEMAtlasBrainClassifier) SetOutput ""
   
   EMAtlasBrainClassifier_DeleteVtkEMAtlasBrainClassifier
   MainUpdateMRML
   RenderAll
   
   # ----------------------------------------------
   # 7. Run Dice measure if necessary 
   # ----------------------------------------------
   if {$ErrorFlag == 0} { set EMAtlasBrainClassifier(LatestLabelMap) $result }
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
  global EMAtlasBrainClassifier Volume
  $vtkGenericClass SetNumInputImages $EMAtlasBrainClassifier(NumInputChannel) 
  eval $vtkGenericClass SetSegmentationBoundaryMin $EMAtlasBrainClassifier(SegmentationBoundaryMin,0) $EMAtlasBrainClassifier(SegmentationBoundaryMin,1) $EMAtlasBrainClassifier(SegmentationBoundaryMin,2)
  eval $vtkGenericClass SetSegmentationBoundaryMax $EMAtlasBrainClassifier(SegmentationBoundaryMax,0) $EMAtlasBrainClassifier(SegmentationBoundaryMax,1) $EMAtlasBrainClassifier(SegmentationBoundaryMax,2)

  $vtkGenericClass SetProbDataWeight $EMAtlasBrainClassifier(Cattrib,$Sclass,LocalPriorWeight)

  $vtkGenericClass SetTissueProbability $EMAtlasBrainClassifier(Cattrib,$Sclass,Prob)
  $vtkGenericClass SetPrintWeights $EMAtlasBrainClassifier(Cattrib,$Sclass,PrintWeights)

  for {set y 0} {$y < $EMAtlasBrainClassifier(NumInputChannel)} {incr y} {
      if {[info exists EMAtlasBrainClassifier(Cattrib,$Sclass,InputChannelWeights,$y)]} {$vtkGenericClass SetInputChannelWeights $EMAtlasBrainClassifier(Cattrib,$Sclass,InputChannelWeights,$y) $y}
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
  global EMAtlasBrainClassifier Volume

  catch { EMAtlasBrainClassifier(Cattrib,$SuperClass,vtkImageEMSuperClass) Delete}
  vtkImageEMAtlasSuperClass EMAtlasBrainClassifier(Cattrib,$SuperClass,vtkImageEMSuperClass)      

  # Define SuperClass specific parameters
  EMAtlasBrainClassifier_SetVtkGenericClassSetting EMAtlasBrainClassifier(Cattrib,$SuperClass,vtkImageEMSuperClass) $SuperClass

  EMAtlasBrainClassifier(Cattrib,$SuperClass,vtkImageEMSuperClass) SetPrintFrequency $EMAtlasBrainClassifier(Cattrib,$SuperClass,PrintFrequency)
  EMAtlasBrainClassifier(Cattrib,$SuperClass,vtkImageEMSuperClass) SetPrintBias      $EMAtlasBrainClassifier(Cattrib,$SuperClass,PrintBias)
  EMAtlasBrainClassifier(Cattrib,$SuperClass,vtkImageEMSuperClass) SetPrintLabelMap  $EMAtlasBrainClassifier(Cattrib,$SuperClass,PrintLabelMap)
  EMAtlasBrainClassifier(Cattrib,$SuperClass,vtkImageEMSuperClass) SetProbDataWeight $EMAtlasBrainClassifier(Cattrib,$SuperClass,LocalPriorWeight)
  
  set ClassIndex 0
  foreach i $EMAtlasBrainClassifier(Cattrib,$SuperClass,ClassList) {
    if {$EMAtlasBrainClassifier(Cattrib,$i,IsSuperClass)} {
        if {[EMAtlasBrainClassifier_SetVtkAtlasSuperClassSetting $i]} {return [EMAtlasBrainClassifier(Cattrib,$i,vtkImageEMSuperClass) GetErrorFlag]}
          EMAtlasBrainClassifier(Cattrib,$SuperClass,vtkImageEMSuperClass) AddSubClass EMAtlasBrainClassifier(Cattrib,$i,vtkImageEMSuperClass) $ClassIndex
    } else {
      catch {EMAtlasBrainClassifier(Cattrib,$i,vtkImageEMClass) destroy}
      vtkImageEMAtlasClass EMAtlasBrainClassifier(Cattrib,$i,vtkImageEMClass)      
      EMAtlasBrainClassifier_SetVtkGenericClassSetting EMAtlasBrainClassifier(Cattrib,$i,vtkImageEMClass) $i

      EMAtlasBrainClassifier(Cattrib,$i,vtkImageEMClass) SetLabel             $EMAtlasBrainClassifier(Cattrib,$i,Label) 

      if {$EMAtlasBrainClassifier(Cattrib,$i,ProbabilityData) != $Volume(idNone)} {
          # Pipeline does not automatically update volumes bc of fake first input  
          Volume($EMAtlasBrainClassifier(Cattrib,$i,ProbabilityData),vol) Update
          EMAtlasBrainClassifier(Cattrib,$i,vtkImageEMClass) SetProbDataPtr [Volume($EMAtlasBrainClassifier(Cattrib,$i,ProbabilityData),vol) GetOutput]
      
      } else {
         set EMAtlasBrainClassifier(Cattrib,$i,LocalPriorWeight) 0.0
      }
      EMAtlasBrainClassifier(Cattrib,$i,vtkImageEMClass) SetProbDataWeight $EMAtlasBrainClassifier(Cattrib,$i,LocalPriorWeight)

      for {set y 0} {$y < $EMAtlasBrainClassifier(NumInputChannel)} {incr y} {
          EMAtlasBrainClassifier(Cattrib,$i,vtkImageEMClass) SetLogMu $EMAtlasBrainClassifier(Cattrib,$i,LogMean,$y) $y
          for {set x 0} {$x < $EMAtlasBrainClassifier(NumInputChannel)} {incr x} {
            EMAtlasBrainClassifier(Cattrib,$i,vtkImageEMClass) SetLogCovariance $EMAtlasBrainClassifier(Cattrib,$i,LogCovariance,$y,$x) $y $x
          }
      }

      # Setup Quality Related information
      if {($EMAtlasBrainClassifier(Cattrib,$i,ReferenceStandardData) !=  $Volume(idNone)) && $EMAtlasBrainClassifier(Cattrib,$i,PrintQuality) } {
        EMAtlasBrainClassifier(Cattrib,$i,vtkImageEMClass) SetReferenceStandard [Volume($EMAtlasBrainClassifier(Cattrib,$i,ReferenceStandardData),vol) GetOutput]
      } 

      EMAtlasBrainClassifier(Cattrib,$i,vtkImageEMClass) SetPrintQuality $EMAtlasBrainClassifier(Cattrib,$i,PrintQuality)
      # After everything is defined add CLASS to its SUPERCLASS
      EMAtlasBrainClassifier(Cattrib,$SuperClass,vtkImageEMSuperClass) AddSubClass EMAtlasBrainClassifier(Cattrib,$i,vtkImageEMClass) $ClassIndex
    }
    incr ClassIndex
  }

  # After attaching all the classes we can defineMRF parameters
  set x 0  

  foreach i $EMAtlasBrainClassifier(Cattrib,$SuperClass,ClassList) {
      set y 0

      foreach j $EMAtlasBrainClassifier(Cattrib,$SuperClass,ClassList) {
        for {set k 0} { $k < 6} {incr k} {
           EMAtlasBrainClassifier(Cattrib,$SuperClass,vtkImageEMSuperClass) SetMarkovMatrix $EMAtlasBrainClassifier(Cattrib,$SuperClass,CIMMatrix,$i,$j,[lindex $EMAtlasBrainClassifier(CIMList) $k]) $k $y $x
        }
        incr y
      }
      incr x
  }
  # Automatically all the subclass are updated too and checked if values are set correctly 
  EMAtlasBrainClassifier(Cattrib,$SuperClass,vtkImageEMSuperClass) Update
  return [EMAtlasBrainClassifier(Cattrib,$SuperClass,vtkImageEMSuperClass) GetErrorFlag] 
}


#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifier_AlgorithmStart
# Sets up the segmentation algorithm
# Returns 0 if an Error Occured and 1 if it was successfull 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifier_AlgorithmStart { } {
   global EMAtlasBrainClassifier Volume 
   # puts "Start EMAtlasBrainClassifier_AlgorithmStart"

   set NumInputImagesSet 0
   vtkImageEMAtlasSegmenter EMAtlasBrainClassifier(vtkEMAtlasBrainClassifier)
   
   # How many input images do you have
   EMAtlasBrainClassifier(vtkEMAtlasBrainClassifier) SetNumInputImages $EMAtlasBrainClassifier(NumInputChannel) 
   EMAtlasBrainClassifier(vtkEMAtlasBrainClassifier) SetNumberOfTrainingSamples $EMAtlasBrainClassifier(NumberOfTrainingSamples)
   if {[EMAtlasBrainClassifier_SetVtkAtlasSuperClassSetting 0]} { return 0 }
   # Transfer image information
   set NumInputImagesSet 0
   foreach v $EMAtlasBrainClassifier(SelVolList,VolumeList) {       
     EMAtlasBrainClassifier(vtkEMAtlasBrainClassifier) SetImageInput $NumInputImagesSet [Volume($v,vol) GetOutput]
     incr NumInputImagesSet
   }
   # Transfer Bias Print out Information
   EMAtlasBrainClassifier(vtkEMAtlasBrainClassifier) SetPrintDir $EMAtlasBrainClassifier(PrintDir)
   EMAtlasBrainClassifier(vtkEMAtlasBrainClassifier) SetHeadClass          EMAtlasBrainClassifier(Cattrib,0,vtkImageEMSuperClass)

   #----------------------------------------------------------------------------
   # Transfering General Information
   #----------------------------------------------------------------------------
   EMAtlasBrainClassifier(vtkEMAtlasBrainClassifier) SetAlpha           $EMAtlasBrainClassifier(Alpha) 

   EMAtlasBrainClassifier(vtkEMAtlasBrainClassifier) SetSmoothingWidth  $EMAtlasBrainClassifier(SmWidth)    
   EMAtlasBrainClassifier(vtkEMAtlasBrainClassifier) SetSmoothingSigma  $EMAtlasBrainClassifier(SmSigma)      

   EMAtlasBrainClassifier(vtkEMAtlasBrainClassifier) SetNumIter         $EMAtlasBrainClassifier(Cattrib,0,StopEMMaxIter) 
   EMAtlasBrainClassifier(vtkEMAtlasBrainClassifier) SetNumRegIter      $EMAtlasBrainClassifier(Cattrib,0,StopMFAMaxIter) 

   return  $EMAtlasBrainClassifier(NumInputChannel) 
}

#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifier_DeleteVtkEMSuperClass
# Delete vtkImageEMSuperClass and children attached to it 
# .ARGS
# string Superclass
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifier_DeleteVtkEMSuperClass { SuperClass } {
   global EMAtlasBrainClassifier
   EMAtlasBrainClassifier(Cattrib,$SuperClass,vtkImageEMSuperClass) Delete
   foreach i $EMAtlasBrainClassifier(Cattrib,$SuperClass,ClassList) {
         if {$EMAtlasBrainClassifier(Cattrib,$i,IsSuperClass)} {
            EMAtlasBrainClassifier_DeleteVtkEMSuperClass  $i
         } else {
            EMAtlasBrainClassifier(Cattrib,$i,vtkImageEMClass) Delete
         }
   }  
}

#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifier_DeleteVtkEMAtlasBrainClassifier
# Delete vtkEMAtlasBrainClassifier related parameters 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifier_DeleteVtkEMAtlasBrainClassifier { } {
     global EMAtlasBrainClassifier
     EMAtlasBrainClassifier(vtkEMAtlasBrainClassifier) Delete
     EMAtlasBrainClassifier_DeleteVtkEMSuperClass 0
}

#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifier_SaveSegmentation
# Saves segmentation results 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifier_SaveSegmentation { } {
  global EMAtlasBrainClassifier Volume 
  if {$EMAtlasBrainClassifier(LatestLabelMap) == $Volume(idNone)} { 
    DevErrorWindow "Error: Could not segment subject"
  } else {
    set Prefix "$EMAtlasBrainClassifier(WorkingDirectory)/EMSegmentation/EMResult"
    puts ""
    puts "Write results to $Prefix"
    set VolIDOutput $EMAtlasBrainClassifier(LatestLabelMap)
    Volume($VolIDOutput,node) SetFilePrefix "$Prefix"
    Volume($VolIDOutput,node) SetFullPrefix "$Prefix" 
    EMAtlasBrainClassifierVolumeWriter $VolIDOutput
  }
  # Change xml directory
  if {$EMAtlasBrainClassifier(Save,XMLFile)}      {MainMrmlWrite  $EMAtlasBrainClassifier(WorkingDirectory)/EMSegmentation/segmentation.xml}
}


##################
# Core Functions 
##################

#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifierStartSegmentation
# This defines the segmentation pipeline
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifierStartSegmentation { } {
    global EMAtlasBrainClassifier EMSegment

    # ---------------------------------------------------------------
    # Setup Pipeline
    if {[EMAtlasBrainClassifier_InitilizePipeline] == 0} { return }  

    # ---------------------------------------------------------------
    # Normalize images
    foreach input "SPGR T2W" {
    EMAtlasBrainClassifier_Normalize $input
    }

    # ---------------------------------------------------------------
    # Determine list of atlas 
    # (to be registered and resampled from template file)
    set Result [EMAtlasBrainClassifier_AtlasList]
    set RegisterAtlasDirList [lindex $Result 0]
    set RegisterAtlasNameList [lindex $Result 1]
  
    # ---------------------------------------------------------------
    # Register Atlases 
    if {$RegisterAtlasDirList != "" } {
       set RunRegistrationFlag [EMAtlasBrainClassifier_RegistrationInitialize "$RegisterAtlasDirList"] 
       if {$RunRegistrationFlag < 0} {return} 
       if {$RunRegistrationFlag} { 
          EMAtlasBrainClassifier_AtlasRegistration "$RegisterAtlasDirList" "$RegisterAtlasNameList"
       } else {
          puts "============= Skip registration - For Debugging - Only works if little endian of machine is the same as when the atlas was resampled" 
          EMAtlasBrainClassifier_LoadAtlas "$RegisterAtlasDirList" "$RegisterAtlasNameList"
       }
    }


    # ---------------------------------------------------------------------- 
    # Segment Image 

    puts "=========== Segment Image ============ "
    # Start algorithm
    # If you want to run the segmentatition pipeline with other EM Segmentation versions just added it here 
    switch $EMAtlasBrainClassifier(SegmentationMode) {
        "EMLocalSegment"         {  EMAtlasBrainClassifier_InitilizeSegmentation  0
                                    EMSegmentStartEM 
                                    set EMAtlasBrainClassifier(LatestLabelMap) $EMSegment(LatestLabelMap) 
                                    EMAtlasBrainClassifier_SaveSegmentation  
                                 }
        "EMPrivateSegment"       {  EMAtlasBrainClassifier_InitilizeSegmentation  1
                                    set XMLFile $EMAtlasBrainClassifier(WorkingDirectory)/EMSegmentation/segmentation.xml
                                    MainMrmlWrite $XMLFile 
                                    MainMrmlDeleteAll 
                                    if {[info exists EMSegment(SegmentMode)] == 0} {
                                       DevErrorWindow "Please source EMSegmentBatch before starting running in this mode"
                                       return
                    }  
                                    Segmentation $XMLFile 
                                 }
        "EMAtlasBrainClassifier" {  EMAtlasBrainClassifier_InitilizeSegmentation  1
                                    EMAtlasBrainClassifier_StartEM 
                                    EMAtlasBrainClassifier_SaveSegmentation  
                                 }
         default   {DevErrorWindow "Error: Segmentation mode $EMAtlasBrainClassifier(SegmentationMode) is unknown"; return }
    }
    puts "=========== Finished  ============ "
}

#-------------------------------------------------------------------------------
# .PROC EMAtlasBrainClassifier_BatchMode 
# Run it from batch mode 
# The function automatically segments MR images into background, skin, CSF, white matter, and gray matter"
# Execute: slicer2-... <XML-File> --exec "EMAtlasBrainClassifier_BatchMode <SegmentationMode>"
# <XML-File> = The first volume defines the spgr image and the second volume defines the aligned t2w images"
#             The directory of the XML-File defines the working directory" 
# <SegmmentationMode> = Optional - you can run a variaty of different versions, such as EMLocalSegment
#                       which is the version defined in vtkEMLocalSegment
# .ARGS
# 
# .END
#-------------------------------------------------------------------------------
proc EMAtlasBrainClassifier_BatchMode {{SegmentationMode EMAtlasBrainClassifier} } {
    global Mrml EMAtlasBrainClassifier Volume
 
    set EMAtlasBrainClassifier(WorkingDirectory) $Mrml(dir)
    set EMAtlasBrainClassifier(Volume,SPGR) [Volume(1,node) GetID]
    set EMAtlasBrainClassifier(Volume,T2W)  [Volume(2,node) GetID]

    # If you set EMAtlasBrainClassifier(BatchMode) to 1 also 
    # set EMAtlasBrainClassifier(Save,*) otherwise when saving xml file 
    # warning window comes up 
    set EMAtlasBrainClassifier(Save,SPGR) 1
    set EMAtlasBrainClassifier(Save,T2W)  1
    set EMAtlasBrainClassifier(BatchMode) 1

    set EMAtlasBrainClassifier(SegmentationMode) $SegmentationMode

    EMAtlasBrainClassifierStartSegmentation
    MainExitProgram
}

