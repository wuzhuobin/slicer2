#=auto==========================================================================
# (c) Copyright 2002 Massachusetts Institute of Technology
#
# Permission is hereby granted, without payment, to copy, modify, display 
# and distribute this software and its documentation, if any, for any purpose, 
# provided that the above copyright notice and the following three paragraphs 
# appear on all copies of this software.  Use of this software constitutes 
# acceptance of these terms and conditions.
#
# IN NO EVENT SHALL MIT BE LIABLE TO ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, 
# INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE 
# AND ITS DOCUMENTATION, EVEN IF MIT HAS BEEN ADVISED OF THE POSSIBILITY OF 
# SUCH DAMAGE.
#
# MIT SPECIFICALLY DISCLAIMS ANY EXPRESS OR IMPLIED WARRANTIES INCLUDING, 
# BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR 
# A PARTICULAR PURPOSE, AND NON-INFRINGEMENT.
#
# THE SOFTWARE IS PROVIDED "AS IS."  MIT HAS NO OBLIGATION TO PROVIDE 
# MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS. 
#
#===============================================================================
# FILE:        VolTensor.tcl
# PROCEDURES:  
#   VolTensorInit
#   VolTensorBuildGui
#==========================================================================auto=


#-------------------------------------------------------------------------------
# .PROC VolTensorInit
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc VolTensorInit {} {
    global Volume

    # Define Procedures for communicating with Volumes.tcl
    #---------------------------------------------
    set m VolTensor
    
    # procedure for building GUI in this module's frame
    set Volume(readerModules,$m,procGUI)  ${m}BuildGUI

    # Define Module Description to be used by Volumes.tcl
    #---------------------------------------------

    # name for menu button
    set Volume(readerModules,$m,name)  Tensor

    # tooltip for help
    set Volume(readerModules,$m,tooltip)  \
            "This tab displays information\n
    for the currently selected diffusion tensor volume."

    # Global variables used inside this module
    #---------------------------------------------
    set Volume(tensors,pfSwap) 0
    set Volume(tensors,DTIdata) 0  
    set Volume(VolTensor,FileType) Scalar6
    set Volume(VolTensor,FileTypeList) {Tensor9 Scalar6}
    set Volume(VolTensor,FileTypeList,tooltips) {"File contains TENSORS field with 9 components" "File contains SCALARS field with 6 components"}
    set Volume(VolTensor,YAxis) vtk
    set Volume(VolTensor,YAxisList) {vtk non-vtk}
    set Volume(VolTensor,YAxisList,tooltips) {"VTK coordinate system used to create tensors (-y axis) " "Non-VTK coordinate system (+y axis)"}


}

#-------------------------------------------------------------------------------
# .PROC VolTensorBuildGui
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc VolTensorBuildGUI {parentFrame} {
    global Gui Volume

    #-------------------------------------------
    # f
    #-------------------------------------------
    set f $parentFrame

    frame $f.fVolume  -bg $Gui(activeWorkspace) -relief groove -bd 3
    frame $f.fFileType   -bg $Gui(activeWorkspace)
    frame $f.fYAxis   -bg $Gui(activeWorkspace)
    frame $f.fApply   -bg $Gui(activeWorkspace)
    pack $f.fVolume $f.fFileType $f.fYAxis $f.fApply \
        -side top -fill x -pady $Gui(pad)

    #-------------------------------------------
    # f->Volume
    #-------------------------------------------
    set f $parentFrame.fVolume
    DevAddFileBrowse $f Volume "VolTensor,FileName" "Structured Points File (.vtk)" "VolTensorSetFileName" "vtk" "\$Volume(DefaultDir)" "Open" "Browse for a Volume" 
    #-------------------------------------------
    # f->FileType
    #-------------------------------------------
    set f $parentFrame.fFileType

    DevAddLabel $f.l "File Type: "
    pack $f.l -side left -padx $Gui(pad) -pady 0
    #set gridList $f.l

    foreach type $Volume(VolTensor,FileTypeList) tip $Volume(VolTensor,FileTypeList,tooltips) {
        eval {radiobutton $f.rMode$type \
                  -text "$type" -value "$type" \
                -variable Volume(VolTensor,FileType) \
                -indicatoron 0} $Gui(WCA) 
        pack $f.rMode$type -side left -padx $Gui(pad) -pady 0
        #lappend gridList $f.rMode$type 
        TooltipAdd  $f.rMode$type $tip
    }   
    
    #eval {grid} $gridList {-padx} $Gui(pad)

    #-------------------------------------------
    # f->YAxis
    #-------------------------------------------
    set f $parentFrame.fYAxis

    DevAddLabel $f.l "Y axis: "
    pack $f.l -side left -padx $Gui(pad) -pady 0
    #set gridList $f.l

    foreach type $Volume(VolTensor,YAxisList) tip $Volume(VolTensor,YAxisList,tooltips) {
        eval {radiobutton $f.rMode$type \
                  -text "$type" -value "$type" \
                -variable Volume(VolTensor,YAxis) \
                -indicatoron 0} $Gui(WCA) 
        pack $f.rMode$type -side left -padx $Gui(pad) -pady 0
        #lappend gridList $f.rMode$type 
        TooltipAdd  $f.rMode$type $tip
    }   

    #eval {grid} $gridList {-padx} $Gui(pad)

    #-------------------------------------------
    # f->Apply
    #-------------------------------------------
    
    set f $parentFrame.fApply
    
    # just go back to header page when done here
    #DevAddButton $f.bApply "Header" "VolumesSetPropertyType VolHeader" 8
    DevAddButton $f.bApply "Apply" "VolTensorApply" 
    DevAddButton $f.bCancel "Cancel" "VolumesPropsCancel" 8
    grid $f.bApply $f.bCancel -padx $Gui(pad)

}


proc VolTensorSetFileName {} {
    global Volume

    puts $Volume(VolTensor,FileName)

}

proc VolTensorApply {} {
    global Volume
    
    
    set m $Volume(activeID)
    if {$m == ""} {return}
    
    
    # if the volume is NEW we may read it in...
    if {$m == "NEW"} {
        
        # add a MRML node for this volume (so that in UpdateMRML
        # we can read it in according to the path, etc. in the node)
        set n [MainMrmlAddNode Volume]
        set i [$n GetID]

        ############# NOTE this should be fixed !!!!!!!! ##############
        # NOTE:
        # this normally happens in MainVolumes.tcl
        # this is needed here to set up structured points reading
        # this should be fixed (the node should handle this somehow
        # so that MRML can be read in with just a node and this will
        # work)
        MainVolumesCreate $i

        # set up structured points reading using sub-node 
        # NOTE: we should do it by setting this up 
        #vtkMrmlDataVolumeReadWriteStructuredPointsNode 
        # but for now we do:
        vtkMrmlDataVolumeReadWriteStructuredPoints Volume($i,vol,rw)
        Volume($i,vol)  SetReadWrite Volume($i,vol,rw)
        puts "set read write"
        Volume($i,vol,rw) SetFileName $Volume(VolTensor,FileName)
        Volume($i,vol) Read
        puts "read test.vtk"
        ################### END of should be fixed ###################

        # slicer assumes the origin is at 0 0 0
        # when creating ras to ijk matrices, etc.  this is 
        # necessary to have tensors in the expected location in 3D
        # for hyperstreamlines to work
        #puts "setting origin to 0 0 0"
        [Volume($i,vol) GetOutput] SetOrigin 0 0 0

        ### this stuff is from the no-header GUI, but use it here too
        ### NOTE: should let users know this happens somehow
        $n SetName $Volume(name)
        $n SetDescription $Volume(desc)
        $n SetLabelMap $Volume(labelMap)
        # get the pixel size, etc. from the data and set it in the node
        

        MainUpdateMRML
        # If failed, then it's no longer in the idList
        if {[lsearch $Volume(idList) $i] == -1} {
            return
        }
        # allow use of other module GUIs
        set Volume(freeze) 0


        puts "[Volume($i,vol) GetOutput] Print"
        # use this as a structured points file (normal volume)
        # set active volume on all menus
        MainVolumesSetActive $i
        

        #######

        # if we are successful set the FOV for correct display of this volume
        set dim     [lindex [Volume($i,node) GetDimensions] 0]
        set spacing [lindex [Volume($i,node) GetSpacing] 0]
        set fov     [expr $dim*$spacing]
        set View(fov) $fov
        MainViewSetFov
        
        # display the new volume in the background of all slices
        # don't do this in case there are no scalars
        #MainSlicesSetVolumeAll Back $i

        # turn the volume into a tensor volume now
        VolTensorCreateTensors $i
    }
}

proc VolTensorCreateTensors {v} {
    global Volume

    switch $Volume(VolTensor,FileType) {
        "Scalar6" {
            VolTensorMake6ComponentScalarVolIntoTensors $v
        }
        "Tensor9" {
            VolTensorMake9ComponentTensorVolIntoTensors $v
        }
    }

}

proc VolTensorMake9ComponentTensorVolIntoTensors {v} {
    global Volume Tensor

    # all we need to do here is put it on the tensor
    # id list and do MRML things

    # put output into a tensor volume
    # Create the node (vtkMrmlVolumeNode class)
    set newvol [MainMrmlAddNode Volume Tensor]
    $newvol Copy Volume($v,node)
    $newvol SetDescription "tensor volume"
    $newvol SetName [Volume($v,node) GetName]
    set n [$newvol GetID]
    MainDataCreate Tensor $n Volume

    # put the image data into the object for slicer use
    Tensor($n,data) SetImageData [Volume($v,vol) GetOutput]

    # test by printing to terminal
    puts [[Tensor($n,data) GetOutput] Print]

    # This updates all the buttons to say that the
    # Tensor ID List has changed.
    MainUpdateMRML
    # If failed, then it's no longer in the idList
    if {[lsearch $Tensor(idList) $n] == -1} {
        puts "node doesn't exist, should unfreeze and fix volumes.tcl too"
    } else {
        # Activate the new data object
        MainDataSetActive Tensor $n
    }

    # DAN if the volume read in does not have scalars, only
    # tensors, it should be removed from the slicer
    # (Volume(id,vol) and Volume(id,node) should go away
    # however they are deleted like in Data.tcl )

}


proc VolTensorMake6ComponentScalarVolIntoTensors {v} {
    global Volume Tensor

    # put output into a tensor volume
    # Create the node (vtkMrmlVolumeNode class)
    set newvol [MainMrmlAddNode Volume Tensor]
    $newvol Copy Volume($v,node)
    $newvol SetDescription "tensor volume"
    $newvol SetName [Volume($v,node) GetName]
    set n [$newvol GetID]
    MainDataCreate Tensor $n Volume

    # actually put the correct data inside the thing
    # need to go from 6-component data to 9-component
    # and then set these as the tensors
    # input scalars are in the order of [Txx Txy Txz Tyy Tyz Tzz]

    # this will be the last filter in the pipeline
    vtkAssignAttribute aa

    # if we do not need to flip the y axis
    if {$Volume(VolTensor,YAxis) == "vtk"} {
        vtkImageAppendComponents ap1
        vtkImageAppendComponents ap2
        # [Txx Txy Txz Txy Tyy Tyz Txz Tyz Tzz]
        # [0   1   2   1   3   4   2   4   5] (indices into input scalars)
        for {set i 0} {$i < 3} {incr i} {
            vtkImageExtractComponents ex$i
            ex$i SetInput [Volume($v,vol) GetOutput]
        }
        ex0 SetComponents 0 1 2
        ex1 SetComponents 1 3 4
        ex2 SetComponents 2 4 5
        ap1 SetInput1 [ex0 GetOutput]
        ap1 SetInput2 [ex1 GetOutput]
        ap2 SetInput1 [ap1 GetOutput]
        ap2 SetInput2 [ex2 GetOutput]
        ap2 Update
    
        # set input to aa to be the output of the last filter above
        aa SetInput [ap2 GetOutput]

        # Delete all temporary vtk objects
        for {set i 0} {$i < 3} {incr i} {
            ex$i Delete
        }
        ap1 Delete
        ap2 Delete

    } else {
        # DAN, this part is not yet implemented

        # we do need to flip the y axis
        # so grab the y components separately and multiply by -1
        # [Txx Txy Txz Txy Tyy Tyz Txz Tyz Tzz]
        # [0   1   2   1   3   4   2   4   5] (indices into input scalars)
        set ind {0   1   2   1   3   4   2   4   5}
        for {set i 0} {$i < 9} {incr i} {
            # grab ith component
            vtkImageExtractComponents ex$i
            ex$i SetInput [Volume($v,vol) GetOutput]
            ex$i SetComponents [lindex $i $ind]
            cout " [lindex $i $ind]"        
        }
        
        # try multiplying the T*y and Ty* by -1
        # you can use vtkImageMathematics filters


        # then using many append components filters, 
        # put together the 9 tensor components
        puts "THIS IS NOT IMPLEMENTED YET"
        return

        # set input to aa to be the output of the last filter above
        # for use in the rest of the code
        # aa SetInput [ap2 GetOutput]

        # Delete all temporary vtk objects      

        # DAN, end of this part 
    }
    
    # aa contains output of chosen pipeline above
    # make the active scalars also the active tensors
    aa Assign SCALARS TENSORS POINT_DATA
    aa Update

    # put the image data (now with tensors and scalars) 
    # into the object for slicer use
    Tensor($n,data) SetImageData [aa GetOutput]

    # test by printing to terminal
    puts [[Tensor($n,data) GetOutput] Print]

    # This updates all the buttons to say that the
    # Tensor ID List has changed.
    MainUpdateMRML
    # If failed, then it's no longer in the idList
    if {[lsearch $Tensor(idList) $n] == -1} {
        puts "node doesn't exist, should unfreeze and fix volumes.tcl too"
    } else {
        # Activate the new data object
        MainDataSetActive Tensor $n
    }

    # Delete all temporary vtk objects
    aa Delete
}
