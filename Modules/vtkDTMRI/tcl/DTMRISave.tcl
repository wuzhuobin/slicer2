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
# FILE:        DTMRISave.tcl
# PROCEDURES:  
#   DTMRISaveInit
#   DTMRISaveBuildGUI
#==========================================================================auto=


#-------------------------------------------------------------------------------
# .PROC DTMRISaveInit
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRISaveInit {} {

    global DTMRI

    # Version info for files within DTMRI module
    #------------------------------------
    set m "Save"
    lappend DTMRI(versions) [ParseCVSInfo $m \
                                 {$Revision: 1.9 $} {$Date: 2005/09/23 02:32:15 $}]

    set DTMRI(Save,type) visualization
}



#-------------------------------------------------------------------------------
# .PROC DTMRISaveBuildGUI
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRISaveBuildGUI {} {

    global DTMRI Tensor Module Gui Volume

    #-------------------------------------------
    # Frame Hierarchy:
    #-------------------------------------------
    # Save
    #-------------------------------------------

    #-------------------------------------------
    # Save frame
    #-------------------------------------------
    set fSave $Module(DTMRI,fSave)
    set f $fSave
    
    frame $f.fActive    -bg $Gui(backdrop) -relief sunken -bd 2
    pack $f.fActive -side top -padx $Gui(pad) -pady $Gui(pad) -fill x
    
    foreach frame "Top Bottom" {
        frame $f.f$frame -bg $Gui(activeWorkspace)
        pack $f.f$frame -side top -padx 0 -pady $Gui(pad) -fill x
    }
    $f.fTop configure  -relief groove -bd 3 
    $f.fBottom configure  -relief groove -bd 3 

    #-------------------------------------------
    # Save->Active frame
    #-------------------------------------------
    set f $fSave.fActive

    # menu to select active DTMRI
    DevAddSelectButton  DTMRI $f Active "Active DTMRI:" Pack \
    "Active DTMRI" 20 BLA 
    
    # Append these menus and buttons to lists 
    # that get refreshed during UpdateMRML
    lappend Tensor(mbActiveList) $f.mbActive
    lappend Tensor(mActiveList) $f.mbActive.m


    #-------------------------------------------
    # Save->Top frame
    #-------------------------------------------
    set f $fSave.fTop

    foreach frame "Type Apply" {
        frame $f.f$frame -bg $Gui(activeWorkspace)
        pack $f.f$frame -side top -padx $Gui(pad) -pady $Gui(pad) -fill both
    }

    #-------------------------------------------
    # Save->Top->Type frame
    #-------------------------------------------
    set f $fSave.fTop.fType

    DevAddLabel $f.l "Save tracts for:"
    pack $f.l -side top -padx $Gui(pad) -pady $Gui(pad)

    foreach text {visualization analysis} tip {"Save slicer models (tubes)." "Save tract paths (lines) and tensors."} {
        eval {radiobutton $f.rType$text -text $text -variable DTMRI(Save,type) \
                  -value $text } $Gui(WRA)
        TooltipAdd $f.rType$text $tip
        pack $f.rType$text -side top -padx $Gui(pad) -pady $Gui(pad)
    }

    #-------------------------------------------
    # Save->Top->Apply frame
    #-------------------------------------------
    set f $fSave.fTop.fApply
    DevAddButton $f.bApply "Save Tracts" \
        {puts "Saving streamlines"; DTMRISaveStreamlinesAsModel}
    pack $f.bApply -side top -padx $Gui(pad) -pady $Gui(pad)
    TooltipAdd  $f.bApply "Save tracts to vtk file(s).\nEach color of tract will become a separate model.\n Choose the initial part of the filename, and models\nwill be saved as filename_0.vtk, filename_1.vtk, etc."


    #-------------------------------------------
    # Save->Bottom frame
    #-------------------------------------------
    set f $fSave.fBottom

    DevAddButton $f.bSave "Save Tensors" {DTMRIWriteStructuredPoints $DTMRI(devel,fileName)}
    pack $f.bSave -side top -padx $Gui(pad) -pady $Gui(pad)
    TooltipAdd $f.bSave "Save tensor data (Active DTMRI) to vtk structured points file format."


}


#-------------------------------------------------------------------------------
# .PROC DTMRISaveStreamlinesAsModel
# Save all streamlines as a vtk model(s).
# Each color is written as a separate model.
# .ARGS
# int verbose default is 1
# .END
#-------------------------------------------------------------------------------
proc DTMRISaveStreamlinesAsModel {{verbose "1"}} {
    global DTMRI Tensor

    # check we have streamlines
    if {[DTMRI(vtk,streamlineControl) GetNumberOfStreamlines] < 1} {
        set msg "There are no tracts to save. Please create tracts first."
        tk_messageBox -message $msg
        return
    }

    # set base filename for all stored files
    set filename [tk_getSaveFile  -title "Save Tracts: Choose Initial Filename"]
    if { $filename == "" } {
        return
    }

    # set name for models in slicer interface
    set modelname [file root [file tail $filename]]

    # get the object that performs saving
    set saveTracts [DTMRI(vtk,streamlineControl) GetSaveTracts]

    # Set whether to save polylines and tensors or just tubes
    if {$DTMRI(Save,type) == "analysis"} {
        $saveTracts SaveForAnalysisOn
    } else {
        $saveTracts SaveForAnalysisOff
    }

    # save the models as well as a MRML file with their colors
    $saveTracts SaveStreamlinesAsPolyData $filename $modelname Mrml(colorTree)

    # let user know something happened
    if {$verbose == "1"} {
        set msg "Finished writing tracts and scene file. The filename is: $filename.xml"
        tk_messageBox -message $msg
    }

}

#-------------------------------------------------------------------------------
# .PROC DTMRIWriteStructuredPoints
# Dump DTMRIs to structured points file.  this ignores
# world to RAS, DTMRIs are just written in scaled ijk coordinate system.
# .ARGS
# path filename
# .END
#-------------------------------------------------------------------------------
proc DTMRIWriteStructuredPoints {filename} {
    global DTMRI Tensor

    set t $Tensor(activeID)

    # check we have tensors
    if {$t =="" } {
        set msg "There are no tensors to save."
        tk_messageBox -message $msg
        return
    }

    set filename [tk_getSaveFile -defaultextension ".vtk" -title "Save tensor as vtkStructuredPoints"]
    if { $filename == "" } {
        return
    }

    vtkStructuredPointsWriter writer
    writer SetInput [Tensor($t,data) GetOutput]
    writer SetFileName $filename
    writer SetFileTypeToBinary
    puts "Writing $filename..."
    writer Write
    writer Delete
    puts "Wrote DTMRI data, id $t, as $filename"
}

