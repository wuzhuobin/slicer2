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
# FILE:        VTKObjectInspection.tcl
# PROCEDURES:  
#   VTKOIMakeVTKObject globalArrayName class objectName
#   VTKOIAddObjectProperty globalArrayName objectName parameterName value dataType desc
#   VTKOIDeleteVTKObject globalArrayName objectName
#   VTKOIApplySettingsToVTKObjects globalArrayName
#   VTKOIBuildGUI globalArrayName tkFrame
#==========================================================================auto=


#-------------------------------------------------------------------------------
# .PROC VTKOIMakeVTKObject
#  Wrapper for vtk object creation.
#  Should be used in conjunction with VTKOIAddObjectProperty for user access
#  to properties of the object.
# .ARGS
# string globalArrayName  Name of the global array in which to store object.
# string class VTK object type to create.
# string objectName Name of the object (will be stored as globalArrayName(vtk,objectName))
# .END
#-------------------------------------------------------------------------------
proc VTKOIMakeVTKObject {globalArrayName class objectName} {

    upvar 1 $globalArrayName Array

    # make the object
    #------------------------------------
    $class ${globalArrayName}(vtk,$objectName)

    # save on list for updating of its variables by user
    #------------------------------------
    lappend Array(vtkObjectList) $objectName

    # initialize list of its variables
    #------------------------------------
    set Array(vtkPropertyList,$objectName) ""
}

#-------------------------------------------------------------------------------
# .PROC VTKOIAddObjectProperty
#  Initialize vtk object access.  Will allow user to change this property
#  through the automatically-created GUI.
#  <p>
#  For example, this function call:
#  <br>
#  VTKOIAddObjectProperty Array tubeAxes NumberOfSides 6 int "number of sides"
#  <br>
#  internally creates tcl variables of this form:
#  <br>
#  set Array(vtk,tubeAxes,numberOfSides) 6 
#  <br>
#  set Array(vtk,tubeAxes,numberOfSides,dataType) int
#  <br>
#  set Array(vtk,tubeAxes,numberOfSides,description) "number of sides"
#  <br>
#  lappend Array(vtkPropertyList,tubeAxes) numberOfSides 
#
# .ARGS
# string globalArrayName Name of the global array in which to store object info.
# string objectName Name of the object this property corresponds to.
# string parameterName The actual property (parameter) of the object.
# string value Initial value to assign to the parameter.
# string dataType Data type of the parameter (int, float, bool are supported)
# string desc Description of the property (becomes a tooltip for the user).
# .END
#-------------------------------------------------------------------------------
proc VTKOIAddObjectProperty {globalArrayName objectName parameterName value dataType desc} {

    upvar 1 $globalArrayName Array

    # make tcl variable and save its attributes (dataType, desc)
    #------------------------------------
    set param [Uncap $parameterName]
    set Array(vtk,$objectName,$param) $value
    set Array(vtk,$objectName,$param,type) $dataType
    set Array(vtk,$objectName,$param,description) $desc

    # save on list for updating variable by user
    #------------------------------------
    lappend Array(vtkPropertyList,$objectName) $param
    
}

#-------------------------------------------------------------------------------
# .PROC VTKOIDeleteVTKObject
# Delete an object previously created with 
# <br>
# "VTKOIMakeVTKObject globalArrayName objectName"
# .ARGS
# string globalArrayName  Name of the global array in which the object was stored.
# string objectName Name of the object (format is globalArrayName(vtk,objectName))
# .END
#-------------------------------------------------------------------------------
proc VTKOIDeleteVTKObject {globalArrayName objectName} {

    upvar 1 $globalArrayName Array

    # delete the object
    #------------------------------------
    ${globalArrayName}(vtk,$objectName) Delete

    # rm from list for updating of its variables by user
    #------------------------------------
    set i [lsearch $Array(vtkObjectList) $objectName]
    set Array(vtkObjectList) [lreplace $Array(vtkObjectList) $i $i]

    # kill list of its variables
    #------------------------------------
    unset Array(vtkPropertyList,$objectName) 
}


#-------------------------------------------------------------------------------
# .PROC VTKOIApplySettingsToVTKObjects
#  For user interaction with pipeline (called by Apply button created in VTKOIBuildGUI).
#  Apply all GUI parameters into the vtk objects.
# .ARGS
# string globalArrayName Name of the global array used in calls to create objects.
# .END
#-------------------------------------------------------------------------------
proc VTKOIApplySettingsToVTKObjects {globalArrayName} {

    upvar 1 $globalArrayName Array

    # this code actually makes a bunch of calls like the following:
    # Array(vtk,axes) SetScaleFactor $Array(vtk,axes,scaleFactor)
    # Array(vtk,tubeAxes) SetRadius $Array(vtk,tubeAxes,radius)
    # Array(vtk,glyphs) SetClampScaling 1
    # we can't do calls like MyObject MyVariableOn now

    # our naming convention is:
    # Array(vtk,object)  is the name of the object
    # paramName is the name of the parameter
    # $Array(vtk,object,paramName) is the value 

    # loop through all vtk objects
    #------------------------------------
    foreach o $Array(vtkObjectList) {

        # loop through all parameters of the object
        #------------------------------------
        foreach p $Array(vtkPropertyList,$o) {

            # value of the parameter is $Array(vtk,$o,$p)
            #------------------------------------
            set value $Array(vtk,$o,$p)
            
            # Actually set the value appropriately in the vtk object
            #------------------------------------    

            # first capitalize the parameter name
            set param [Cap $p]
            
            # MyObject SetMyParameter $value    
            # handle the case in which value is a list with an eval 
            # this puts it into the correct format for feeding to vtk
            eval {${globalArrayName}(vtk,$o) Set$param} $value
        }
    }

}


#-------------------------------------------------------------------------------
# .PROC VTKOIBuildGUI
# Automatically generate a GUI where user can change VTK object settings.
# First create all objects with calls to VTKOIMakeVTKObject and VTKOIAddObjectProperty.
# .ARGS
# string globalArrayName Name of the global array used in calls to create objects.
# string tkFrame A new frame to fill with entry boxes for all properties of each object.
# .END
#-------------------------------------------------------------------------------
proc VTKOIBuildGUI {globalArrayName tkFrame} {

    global Gui $globalArrayName

    upvar 1 $globalArrayName Array
    
    # Initialize all objects to requested values
    #VTKOIApplySettingsToVTKObjects ${globalArrayName}
    VTKOIApplySettingsToVTKObjects $globalArrayName

    #-------------------------------------------
    # VTK frame
    #-------------------------------------------
    set fVTK $tkFrame
    set f $fVTK
    
    foreach frame "Top Middle Bottom" {
        frame $f.f$frame -bg $Gui(activeWorkspace)
        pack $f.f$frame -side top -padx 0 -pady $Gui(pad) -fill x
    }

    #-------------------------------------------
    # VTK->Top frame
    #-------------------------------------------
    set f $fVTK.fTop
    DevAddLabel $f.l "VTK objects in the pipeline"
    pack $f.l -side top -padx $Gui(pad) -pady $Gui(pad)

    #-------------------------------------------
    # VTK->Middle frame
    #-------------------------------------------
    set f $fVTK.fMiddle
    set fCurrent $f

    # loop through all the vtk objects and build GUIs
    #------------------------------------              
    foreach o $Array(vtkObjectList) {

        set f $fCurrent

        # if the object has properties
        #-------------------------------------------
        if {$Array(vtkPropertyList,$o) != ""} {
            
            # make a new frame for this vtk object
            #-------------------------------------------
            frame $f.f$o -bg $Gui(activeWorkspace)
            $f.f$o configure  -relief groove -bd 3 
            pack $f.f$o -side top -padx $Gui(pad) -pady 2 -fill x
            
            # object name becomes the label for the frame
            #-------------------------------------------
            DevAddLabel $f.f$o.l$o [Cap $o]
            pack $f.f$o.l$o -side top \
                -padx 0 -pady 0
        }

        # loop through all the parameters for this object
        # and build appropriate user entry stuff for each
        #------------------------------------
        foreach p $Array(vtkPropertyList,$o) {

            set f $fCurrent.f$o

            # name of entire tcl variable
            set variableName ${globalArrayName}(vtk,$o,$p)
            # its value is:
            set value $Array(vtk,$o,$p)
            # description of the parameter
            set desc $Array(vtk,$o,$p,description)
            # datatype of the parameter
            set type $Array(vtk,$o,$p,type)

            # make a new frame for this parameter
            frame $f.f$p -bg $Gui(activeWorkspace)
            pack $f.f$p -side top -padx 0 -pady 1 -fill x
            set f $f.f$p

            # see if value is a list (not used now)
            #------------------------------------        
            set length [llength $value]
            set isList [expr $length > "1"]

            # Build GUI entry boxes, etc
            #------------------------------------        
            switch $type {
                "int" {
                    eval {entry $f.e$p \
                  -width 5 \
                  -textvariable $variableName\
                          } $Gui(WEA)
                    DevAddLabel $f.l$p $desc:
                    pack $f.l$p $f.e$p -side left \
                        -padx $Gui(pad) -pady 2
                }
                "float" {
                    eval {entry $f.e$p \
                          -width 5 \
                          -textvariable $variableName\
                          } $Gui(WEA)
                    DevAddLabel $f.l$p $desc:
                    pack $f.l$p $f.e$p -side left \
                        -padx $Gui(pad) -pady 2
                }
                "bool" {
                    # puts "bool: $variableName, $desc"
                    eval {checkbutton $f.r$p  \
                          -text $desc -variable $variableName \
                          } $Gui(WCA)
                    pack  $f.r$p -side left \
                        -padx $Gui(pad) -pady 2
                }
            }
            
        }
    }
    # end foreach vtk object in Array's object list

    # Allow the user to apply changes to object parameters
    DevAddButton $fVTK.fMiddle.bApply Apply \
        "VTKOIApplySettingsToVTKObjects ${globalArrayName}; Render3D"
    pack $fVTK.fMiddle.bApply -side top -padx $Gui(pad) -pady $Gui(pad)


}



