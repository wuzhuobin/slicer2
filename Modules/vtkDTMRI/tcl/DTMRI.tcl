#=auto==========================================================================
# (c) Copyright 2004 Massachusetts Institute of Technology (MIT) All Rights Reserved.
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
# FILE:        tmp.tcl
# PROCEDURES:  
#   DTMRIInit
#   DTMRIUpdateMRML
#   DTMRIEnter
#   DTMRIExit
#   DTMRIBuildGUI
#   DTMRIRaiseMoreOptionsFrame mode
#   DTMRIBuildScrolledGUI f
#   DTMRICheckScrollLimits
#   DTMRISizeScrolledGUI f
#   DTMRISetPropertyType
#   RunLSDIrecon               -------->    Convert Volume Data from Scanner to a DTMRImodule readable format (from I.## to D.##)  
#   ShowPatternFrame
#   DTMRIDisplayScrollBar
#   ShowPatternFrame           -------->    Show and hide Create-Pattern frame
#   DTMRIDisplayScrollBar      -------->    Show Scrollbar when resizing a frame
#   DTMRICreatePatternSlice    -------->    Create a new tensor convertion pattern for slice interleaved data. This procedure writes the information of the new patterns in $env(HOME). To declare a permanent pattern so that Slicer is able to load it, you have to write in the file"patterns.txt" located in vtkDTMRI subdirectory.
#   DTMRICreatePatternVolume   -------->    Create a new tensor convertion pattern for volume interleaved data. This procedure writes the information of the new patterns in $env(HOME). To declare a permanent pattern so that Slicer is able to load it, you have to write in the file "patterns.txt" located in vtkDTMRI subdirectory.
#   DTMRILoadPattern           -------->    Looks for files with pattern information and adds them to the menubutton in the Create Pattern Frame.
#   DTMRIUpdateTipsPattern
#   DTMRIViewProps             -------->    Show properties of the selected pattern
#   DTMRIDisplayNewData         -------->    Once converted de New Data, load it and display it automatically
#   DTMRIPropsApply
#   DTMRIPropsCancel
#   DTMRIAdvancedApply
#   DTMRISetFileName
#   DTMRICreateBindings
#   DTMRIRoundFloatingPoint
#   DTMRIRemoveAllActors
#   DTMRIAddAllActors
#   DTMRIUpdateReformatType
#   DTMRIUpdateScalarBar
#   DTMRIShowScalarBar
#   DTMRIHideScalarBar
#   DTMRIUpdateThreshold
#   DTMRIUpdateMaskLabel
#   DTMRISpecificVisualizationSettings
#   DTMRIResetDefaultVisualizationSettings
#   DTMRIApplyVisualizationSettings mode
#   DTMRIUpdateGlyphEigenvector
#   DTMRIUpdateGlyphColor
#   DTMRIUpdateGlyphScalarRange
#   DTMRISelectRemoveHyperStreamline
#   DTMRISelectStartHyperStreamline x y z
#   DTMRIUpdateStreamlineSettings
#   DTMRIUpdateStreamlines
#   DTMRIUpdateTractingMethod
#   DTMRIUpdateBSplineOrder
#   DTMRIUpdateTractColorToSolid
#   DTMRIUpdateTractColorToMulti
#   DTMRIUpdateTractColor
#   DTMRIRemoveAllStreamlines
#   DTMRIAddAllStreamlines
#   DTMRIDeleteAllStreamlines
#   DTMRISeedStreamlinesFromSegmentation
#   DTMRIUpdate
#   DTMRISetOperation math
#   DTMRIUpdateMathParams
#   DTMRICreateEmptyVolume
#   DTMRIDoMath
#   DTMRIApplyVisualizationParameters
#   DTMRIDeleteVTKObject
#   DTMRIMakeVTKObject
#   DTMRIAddObjectProperty
#   DTMRIBuildVTK
#   ConvertVolumeToTensors
#   DTMRIWriteStructuredPoints
#   DTMRISaveStreamlinesAsIJKPoints subdir name verbose
#   DTMRISaveStreamlinesAsPolyLines subdir name verbose
#   DTMRISaveStreamlinesAsModel
#   DTMRIGetScaledIjkCoordinatesFromWorldCoordinates x y z
#   DTMRICalculateActorMatrix transform t
#   DTMRICalculateIJKtoRASRotationMatrix
#   DTMRI SetActive
#==========================================================================auto=

#-------------------------------------------------------------------------------
# .PROC DTMRIInit
#  The "Init" procedure is called automatically by the slicer.  
#  It puts information about the module into a global array called Module, 
#  and it also initializes module-level variables.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIInit {} {
    global DTMRI Module Volume env
    
    set m DTMRI

    # Source all appropriate tcl files here. 
    source "$env(SLICER_HOME)/Modules/vtkDTMRI/tcl/notebook.tcl"
    
    # Load tensor registration module.
    source "$env(SLICER_HOME)/Modules/vtkDTMRI/tcl/DTMRITensorRegistration.tcl"
    DTMRIRegInit
     
    # Module Summary Info
    #------------------------------------
    set Module($m,overview) "Diffusion DTMRI MRI visualization and more..."
    set Module($m,author) "Lauren O'Donnell"
    set Module($m,category) "Visualisation"

    # version info
    lappend Module(versions) [ParseCVSInfo $m \
                  {$Revision: 1.58 $} {$Date: 2005/01/23 06:44:42 $}]

    # Define Tabs
    #------------------------------------
    set Module($m,row1List) "Help Input Convert Display ROI"
    set Module($m,row1Name) "{Help} {Input} {Convert} {Disp} {ROI}"
    set Module($m,row1,tab) Input
    # Use these lines to add a second row of tabs
    set Module($m,row2List) "Scalars Advanced Regist Save"
    set Module($m,row2Name) "{Scalars} {Advanced} {Regist} {Save}"
    set Module($m,row2,tab) Scalars
    

    
    # Define Procedures
    #------------------------------------
    set Module($m,procGUI) DTMRIBuildGUI
    set Module($m,procMRML) DTMRIUpdateMRML
    set Module($m,procVTK) DTMRIBuildVTK
    set Module($m,procEnter) DTMRIEnter
    set Module($m,procExit) DTMRIExit
    
    # Define Dependencies
    #------------------------------------
    # This module depends on Csys (in future)
    #set Module($m,depend) Csys
    set Module($m,depend) ""
    
    # Create any specific bindings for this module
    #------------------------------------
    DTMRICreateBindings


    # Props: GUI tab we are currently on
    #------------------------------------
    set DTMRI(propertyType) Basic
    
    # Initial path to search when loading files
    #------------------------------------
    set DTMRI(DefaultDir) ""

    #------------------------------------
    # LSDI conversion variables
    #------------------------------------
   
    # These variables should be in the main-variables 
    # file and must be modified the first time slicer is 
    # installed to tell the program where are the python 
    # interpreter and the lsdi_slicer.py script.

    #variable that indicates where is the python interpreter
    set DTMRI(pythonintdir) /projects/lmi/local/SunOS/bin/python

    #variable that indicates where is the binary of the lsdi_slicer.py script
    set DTMRI(LSDIpydir) /projects/lmi/local/SunOS/bin/lsdi_slicer.py

    #------------------------------------
    # handling patterns variables
    #------------------------------------

    # List with the existing patterns
    # DTMRI(patternnames)

    # List with the information of the pattern called "patternname"
    # DTMRI("patternname", parameters)

    # Variable with the name of the pattern selected in the menubutton. Used to retrieve information of the pattern when converting tensors.
    # DTMRI(selectedpattern)

    # Variables associated to entries for creating a new pattern
    set DTMRI(name,name) ""
    set DTMRI(name,numberOfGradients) ""
    set DTMRI(name,firstGradientImage) ""
    set DTMRI(name,lastGradientImage) ""
    set DTMRI(name,firstNoGradientImage) ""
    set DTMRI(name,lastNoGradienImage) ""
    set DTMRI(name,gradients) ""
    set DTMRI(name,lebihan) ""
    #This variable specifies the order of the gradients disposal (slice interleaved or volume interleaved)
    set DTMRI(name,order) ""


    #------------------------------------
    # conversion from volume to DTMRIs variables
    #------------------------------------
    vtkImageDiffusionTensor _default
    set DTMRI(convert,numberOfGradients) [_default GetNumberOfGradients]
    set DTMRI(convert,gradients) ""
    for {set i 0} {$i < $DTMRI(convert,numberOfGradients)} {incr i} {
        _default SelectDiffusionGradient $i
        lappend DTMRI(convert,gradients) [_default GetSelectedDiffusionGradient]
    }
    _default Delete
    # puts $DTMRI(convert,gradients)
    set DTMRI(convert,firstGradientImage) 1
    set DTMRI(convert,lastGradientImage) 6
    set DTMRI(convert,firstNoGradientImage) 7
    set DTMRI(convert,lastNoGradientImage) 7

    #Specific variables for Mosaic format (This should be extracted from Dicom header)
    set DTMRI(convert,mosaicTiles) 8
    set DTMRI(convert,mosaicSlices) 60
    
    #This variable is used by Create-Pattern button and indicates weather it has to hide or show the create pattern frame. On status 0 --> show. On status 1 --> hide.
    set DTMRI(convert,show) 0

    set DTMRI(convert,makeDWIasVolume) 0
    #------------------------------------
    # Visualization-related variables
    #------------------------------------

    # type of settings in 3d view, anno, etc
    set DTMRI(mode,visualizationSettingsType) default
    set DTMRI(mode,visualizationSettingsTypeList) {DTMRIs default}
    set DTMRI(mode,visualizationSettingsTypeList,tooltips) [list \
                                "3D View settings to display DTMRIs: transparent slices." \
                                "Reset to Slicer default settings."  \
                                   ]
                                   
   # whether removing actors when leaving the module or not
   set DTMRI(mode,visualizationRemoveTypeList) {On Off}
   set DTMRI(mode,visualizationRemoveTypeValue) {1 0}
   set DTMRI(mode,visualizationRemoveTypeList,tooltips) [list \
       "Remove Glyphs and Streamlines when leaving the module." \
       "Keep Glyphs and Streamlines when leaving the module." \
       ]


    # type of reformatting
    set DTMRI(mode,reformatType) 0
    #set DTMRI(mode,reformatTypeList) {None 0 1 2}
    #set DTMRI(mode,reformatTypeList) {0 1 2}
    set DTMRI(mode,reformatTypeList) {0 1 2 {0 1 2} None}
    set DTMRI(mode,reformatTypeList,text) {"" "" "" All Vol}
    set DTMRI(mode,reformatTypeList,tooltips) [list \
                           "Display DTMRIs as glyphs (ex. lines) in the location of the leftmost slice."  \
                           "Display DTMRIs as glyphs (ex. lines) in the location of the middle slice."  \
                           "Display DTMRIs as glyphs (ex. lines) in the location of the rightmost slice."  \
                           "Display DTMRIS as glyphs in all the slice views (axial, sagittal and coronal)." \
               "Display all DTMRIs in the volume.  Please use an ROI." \
                          ]
    #set DTMRI(mode,reformatTypeList,tooltips) [list \
    #        "No reformatting: display all DTMRIs." \
    #       "Reformat DTMRIs along with slice 0."  \
    #      "Reformat DTMRIs along with slice 1."  \
    #     "Reformat DTMRIs along with slice 2."  \
    #]

    # whether we are currently displaying glyphs
    set DTMRI(mode,visualizationType,glyphsOn) 0ff
    set DTMRI(mode,visualizationType,glyphsOnList) {On Off}
    set DTMRI(mode,visualizationType,glyphsOnList,tooltip) [list \
                                "Display each DTMRI as a glyph\n(for example a line or ellipsoid)" \
                                "Do not display glyphs" ]

    # whether we are currently displaying tracts
    set DTMRI(mode,visualizationType,tractsOn) 0n
    set DTMRI(mode,visualizationType,tractsOnList) {On Off Delete}
    set DTMRI(mode,visualizationType,tractsOnList,tooltip) [list \
                                "Display all 'tracts'" \
                                "Hide all 'tracts'" \
                                "Clear all 'tracts'" ]
    # guard against multiple actor add/remove from GUI
    set DTMRI(vtk,streamline,actorsAdded) 1

    # type of visualization settings GUI to display to user
    set DTMRI(mode,visualizationTypeGui) Tracts
    set DTMRI(mode,visualizationTypeGuiList) {Help Tracts AutoTracts SaveTracts}
    set DTMRI(mode,visualizationTypeGuiList,tooltip) "Select from this menu\n and settings for each type\n of visualization will appear below."

    # type of glyph to display (default to lines since fastest)
    set DTMRI(mode,glyphType) Lines
    set DTMRI(mode,glyphTypeList) {Axes Lines Ellipsoids Boxes}
    set DTMRI(mode,glyphTypeList,tooltips) {{Display DTMRIs as 3 axes aligned with eigenvectors and scaled by eigenvalues.} {Display DTMRIs as lines aligned with one eigenvector and scaled by its eigenvalue.} {Display DTMRIs as ellipses aligned with eigenvectors and scaled by eigenvalues.} {Display DTMRIs as scaled oriented cubes.}}

    # type of eigenvector to draw glyph lines for
    set DTMRI(mode,glyphEigenvector) Max
    set DTMRI(mode,glyphEigenvectorList) {Max Middle Min}
    set DTMRI(mode,glyphEigenvectorList,tooltips) {{When displaying DTMRIs as Lines, use the eigenvector corresponding to the largest eigenvalue.} {When displaying DTMRIs as Lines, use the eigenvector corresponding to the middle eigenvalue.} {When displaying DTMRIs as Lines, use the eigenvector corresponding to the smallest eigenvalue.}}

    # type of glyph coloring
    set DTMRI(mode,glyphColor) Linear; # default linear matches the vtk class
    set DTMRI(mode,glyphColorList) {Linear Planar Spherical Max Middle Min MaxMinusMiddle RA FA Direction}
    set DTMRI(mode,glyphColorList,tooltip) "Color DTMRIs according to\nLinear, Planar, or Spherical measures,\nwith the Max, Middle, or Min eigenvalue,\nwith relative or fractional anisotropy (RA or FA),\nor by direction of major eigenvector."
   
    # glyhs visualization resolution
    set DTMRI(mode,glyphResolution) 3
    set DTMRI(mode,glyphResolution,min) 1
    set DTMRI(mode,glyphResolution,max) 5


    # type of tract coloring
    set DTMRI(mode,tractColor) SolidColor;
    set DTMRI(mode,tractColorList) {SolidColor MultiColor}
    set DTMRI(mode,tractColorList,tooltip) "Color tracts with a solid color \nOR MultiColor by scalars from the menu below."


    # How to handle display of colors: like W/L but scalar range
    set DTMRI(mode,glyphScalarRange) Auto
    set DTMRI(mode,glyphScalarRangeList) {Auto Manual}
    set DTMRI(mode,glyphScalarRangeList,tooltips) [list \
                               "Scalar range will be set to max and min scalar in the data." \
                               "User-adjustable scalar range to highlight areas of interest (like window/level does)."]
    # slider min/max values
    set DTMRI(mode,glyphScalarRange,min) 0
    set DTMRI(mode,glyphScalarRange,max) 10
    # slider current settings
    set DTMRI(mode,glyphScalarRange,low) 0
    set DTMRI(mode,glyphScalarRange,hi) 1

    # whether to reformat DTMRIs along with slices
    set DTMRI(mode,reformat) 0

    # display properties of the actors
    #set DTMRI(actor,ambient) 1
    #set DTMRI(actor,diffuse) .2
    #set DTMRI(actor,specular) .4

    # Whether to remove actors on module exit
    set DTMRI(vtk,actors,removeOnExit) 1
    set DTMRI(vtk,actors,firstEnter) 1

    # Whether the glyph actors are currently present in the scene
    set DTMRI(glyphs,actorsAdded) 0

    # scalar bar
    set DTMRI(mode,scalarBar) Off
    set DTMRI(mode,scalarBarList) {On Off}
    set DTMRI(mode,scalarBarList,tooltips) [list \
                        "Display a scalar bar to show correspondence between numbers and colors." \
                        "Do not display the scalar bar."]


    #------------------------------------
    # Variables for streamline display
    #------------------------------------
    # BSpline Orders
    set DTMRI(stream,BSplineOrder) "3"
    set DTMRI(stream,BSplineOrderList) {"0" "1" "2" "3" "4" "5"}
    set DTMRI(stream,BSplineOrderList,tooltip) {"Order of the BSpline interpolation."}

    # Method Orders
    set DTMRI(stream,MethodOrder) "rk4"
    set DTMRI(stream,MethodOrderList) {"rk2" "rk4" "rk45"}
    set DTMRI(stream,MethodOrderList,tooltip) {"Order of the tractography"}

    # type of tracting method
    set DTMRI(stream,tractingMethod) NoSpline
    set DTMRI(stream,tractingMethodList) {NoSpline BSpline }
    set DTMRI(stream,tractingMethodList,tooltip) {"Method for interpolating signal"}

    set DTMRI(stream,methodvariableList) [list UpperBoundBias LowerBoundBias CorrectionBias ]

    set DTMRI(stream,methodvariableList,text) [list "High Fractional Anisotropy" "Low Fractional Anisotropy" "Correction Bias Magnitude" ]

    set DTMRI(stream,methodvariableList,tooltips) [list \
                               "Inferior bound for fractional anisotropy before adding a regularization bias"\
                               "Lowest fractional anisotropy allowable for tractography"\
                               "Magnitude of the correction bias added for tractography" ]
    set DTMRI(stream,variableList) [list \
                    MaximumPropagationDistance IntegrationStepLength \
                    StepLength Radius  NumberOfSides MaxCurvature MinFractionalAnisotropy]
    set DTMRI(stream,precisevariableList) [list \
                           MaximumPropagationDistance MinimumPropagationDistance TerminalEigenvalue \
                           IntegrationStepLength \
                           StepLength Radius  NumberOfSides  \
                           MaxStep MinStep MaxError MaxAngle LengthOfMaxAngle]
    set DTMRI(stream,variableList,text) [list \
                         "Max Length" "Step Size" \
                         "Smoothness (along)" "Radius"  "Smoothness (around)" "Curvature Threshold" "FA Threshold"]
    set DTMRI(stream,precisevariableList,text) [list \
                            "Max Length" "Min Length" "Terminal Eigenvalue"\
                            "Step Size" \
                            "Smoothness (along)" "Radius"  "Smoothness (around)" \
                            "Max Step" "Min Step" "Max Error" "Max Angle" "Length for Max Angle"]
    set DTMRI(stream,variableList,tooltips) [list \
                         "MaximumPropagationDistance: Tractography will stop after this distance" \
                         "IntegrationStepLength: step size when following path" \
                         "StepLength: Length of each displayed tube segment" \
                         "Radius: Initial radius (thickness) of displayed tube" \
                         "NumberOfSides: Number of sides of displayed tube" \
                         "Curvature Threshold: Max curvature allowed in tracking"\
                         "FA Threshold: If FA falls below this value, tracking stops"]
    
    set DTMRI(stream,precisevariableList,tooltips) [list \
                            "MaximumPropagationDistance: Tractography will stop after this distance" \
                            "MinimumPropagationDistance: Streamline will be rejected if total length is under this value" \
                            "TerminalEigenvalue: Set minimum propagation speed"\
                            "IntegrationStepLength: step size when following path" \
                            "StepLength: Length of each displayed tube segment" \
                            "Radius: Initial radius (thickness) of displayed tube" \
                            "NumberOfSides: Number of sides of displayed tube" \
                            "MaxStep: Maximum step size when following path" \
                            "MinStep: Minimum step size when following path" \
                            "MaxError: Maximum Error of each step" \
                            "MaxAngle: Maximum Angle allowed per fiber" \
                            "MaxError: Length of fiber when considering maximum angle" ]

    # Upper Bound to add regularization Bias
    set DTMRI(stream,UpperBoundBias)  0.3
    # Lower Bound to add regularization Bias
    set DTMRI(stream,LowerBoundBias)  0.2
    # Magnitude of the correction bias
    set DTMRI(stream,CorrectionBias)  0.5

    set DTMRI(stream,MaximumPropagationDistance)  600.0
    set DTMRI(stream,MinimumPropagationDistance)  30.0
    # Terminal Eigenvalue
    set DTMRI(stream,TerminalEigenvalue)  0.0
    # nominal integration step size (expressed as a fraction of the
    # size of each cell)  0.2 is default
    set DTMRI(stream,IntegrationStepLength)  0.1
    # Set/Get the Maximum Step of integration
    set DTMRI(stream,MaxStep) 1.0
    # Set/Get the Minimum Step of integration
    set DTMRI(stream,MinStep) 0.001
    # Set/Get the Maximum Error per step of integration
    set DTMRI(stream,MaxError) 0.000001

    # Set/Get the Maximum Angle of a fiber
    set DTMRI(stream,MaxAngle) 30

    # Set/Get the length of the fiber when considering the maximum angle
    set DTMRI(stream,LengthOfMaxAngle) 1
    # Set / get the length of a tube segment composing the
    # hyperstreamline. The length is specified as a fraction of the
    # diagonal length of the input bounding box.  0.01 is vtk default
    set DTMRI(stream,StepLength)  0.005
    # radius of (polydata) tube that is displayed
    #set DTMRI(stream,Radius)  0.2 
    set DTMRI(stream,Radius)  0.4
    # sides of tube
    #set DTMRI(stream,NumberOfSides)  4
    set DTMRI(stream,NumberOfSides)  6
    #set DTMRI(stream,MaxCurvature) 1.3
    set DTMRI(stream,MaxCurvature) 1.15
    set DTMRI(stream,MinFractionalAnisotropy) 0.07

    #------------------------------------
    # Variables for auto streamline display
    #------------------------------------
    set DTMRI(mode,autoTractsLabel,tooltip) "A tract will be seeded in each voxel of the ROI which is colored with this label."

    #------------------------------------
    # Variables for preprocessing
    #------------------------------------

    # upper and lower values allowable when thresholding
    set DTMRI(thresh,threshold,rangeLow) 0
    set DTMRI(thresh,threshold,rangeHigh) 500

    # type of thresholding to use to reduce number of DTMRIs
    set DTMRI(mode,threshold) None
    set DTMRI(mode,thresholdList) {None Trace LinearMeasure SphericalMeasure PlanarMeasure}
    set DTMRI(mode,thresholdList,tooltips) {{No thresholding.  Display all DTMRIs.} {Only display DTMRIs where the trace is between the threshold values.}  {Only display DTMRIs where the anisotropy is between the threshold values.}}

    # type of masking to use to reduce volume of DTMRIs
    set DTMRI(mode,mask) None
    set DTMRI(mode,maskList) {None MaskWithLabelmap}
    set DTMRI(mode,maskList,tooltips) {{No masking.  Display all DTMRIs.} {Only display DTMRIs where the mask labelmap shows the chosen label value.}}
    set DTMRI(mode,maskLabel,tooltip) "The ROI colored with this label will be used to mask DTMRIs.  DTMRIs will be shown only inside the ROI."

    # labelmap to use as mask
    set DTMRI(MaskLabelmap) $Volume(idNone)

    #------------------------------------
    # Variables for producing scalar volumes
    #------------------------------------

    # math op to produce scalars from DTMRIs
    set DTMRI(scalars,operation) Trace
    set DTMRI(scalars,operationList) [list Trace Determinant \
                      RelativeAnisotropy FractionalAnisotropy LinearMeasure \
                      PlanarMeasure SphericalMeasure MaxEigenvalue \
                      MiddleEigenvalue MinEigenvalue ColorByOrientation D11 D22 D33]

    set DTMRI(scalars,operationList,tooltip) "Produce a scalar volume from DTMRI data.\nTrace, Determinant, Anisotropy, and Eigenvalues produce grayscale volumes,\nwhile Orientation produces a 3-component (Color) volume that is best viewed in the 3D window."

    # how much to scale the output floats by
    set DTMRI(scalars,scaleFactor) 10000
    set DTMRI(scalars,scaleFactor,tooltip) \
    "Multiplicative factor applied to output images for better viewing."
    
    # whether to compute vol from ROI or whole DTMRI volume
    set DTMRI(scalars,ROI) None
    set DTMRI(scalars,ROIList) {None Threshold Mask}
    set DTMRI(scalars,ROIList,tooltips) {"No ROI: derive the scalar volume from the entire DTMRI volume." "Use the thresholded area defined in the ROI tab to mask the DTMRI volume before scalar volume creation." "Use the mask labelmap volume defined in the ROI tab to mask the DTMRI volume before scalar volume creation."}


    #------------------------------------
    # Developers panel variables
    #------------------------------------
    set DTMRI(devel,subdir) ""
    set DTMRI(devel,fileNamePoints) ""
    set DTMRI(devel,fileName) "DTMRIs.vtk"
    set tmp "\
            {1 0 0 0}  \
            {0 1 0 0}  \
            {0 0 1 0}  \
            {0 0 0 1}  "
    set rows {0 1 2 3}
    set cols {0 1 2 3}    
    foreach row $rows {
        foreach col $cols {
            set DTMRI(recalculate,userMatrix,$row,$col) \
                [lindex [lindex $tmp $row] $col]
        } 
    }

    #------------------------------------
    # Diffusion panel variables
    #------------------------------------


    # Init the tensor registration
    #------------------------------------
    DTMRIRegInit


    #------------------------------------
    # Number display variables
    #------------------------------------
    # round floats to 8 digits
    set DTMRI(floatingPointFormat) "%0.5f"
    

    set DTMRI(Description) ""
    set DTMRI(Name) ""

}

################################################################
#  Procedures called automatically by the slicer
################################################################

#-------------------------------------------------------------------------------
# .PROC DTMRIUpdateMRML
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIUpdateMRML {} {
    global Tensor DTMRI

    set t $Tensor(activeID)
    
    if {$t != "" } {
        # in case transformation matrices have moved around
        # our tensor data, set up the tractography matrix again.
        # transform from World coords to scaledIJK of the tensors
        vtkTransform transform
        DTMRICalculateActorMatrix transform $t    
        transform Inverse
        DTMRI(vtk,streamlineControl) SetWorldToTensorScaledIJK transform
        transform Delete 
    }
    
     # Do MRML update for Tensor Registration tab. Necessary because
     # multiple lists are used.
     if {([catch "package require vtkAG"]==0)&&([info exist DTMRI(reg,AG)])} {
       # This is needed to handle deletion of tensors.
       if {[catch "Tensor($DTMRI(InputTensorSource),node) GetName"]==1} {
     set DTMRI(InputTensorSource) $Tensor(idNone)
         $DTMRI(mbInputTensorSource) config -text None
       }
       if {[catch "Tensor($DTMRI(InputTensorTarget),node) GetName"]==1} {
     set DTMRI(InputTensorTarget) $Tensor(idNone)
         $DTMRI(mbInputTensorTarget) config -text None
       }
       if {[catch "Tensor($DTMRI(ResultTensor),node) GetName"]==1} {
     set DTMRI(ResultTensor) -5
       }
       DevUpdateNodeSelectButton Tensor DTMRI InputTensorSource   InputTensorSource   DevSelectNode
       DevUpdateNodeSelectButton Tensor DTMRI InputTensorTarget   InputTensorTarget   DevSelectNode 0 0 0 DTMRIReg2DUpdate
       DevUpdateNodeSelectButton Tensor DTMRI ResultTensor  ResultTensor  DevSelectNode  0 1 0
       DevSelectNode Tensor $DTMRI(ResultTensor) DTMRI ResultTensor ResultTensor
       DevUpdateNodeSelectButton Volume DTMRI InputCoregVol InputCoregVol DevSelectNode
     }
       
}

#-------------------------------------------------------------------------------
# .PROC DTMRIEnter
# Called when this module is entered by the user.  Pushes the event manager
# for this module. 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIEnter {} {
    global DTMRI Slice View
    
    # set global flag to avoid possible render loop
    set View(resetCameraClippingRange) 0

    # add event handling for 3D
    #CsysPushBindings DTMRI DTMRI3DStreamlineEvents
    #puts "Lauren Fix bindings"
    # add actor for csys
    #puts "Not adding csys actor"
    #MainAddActor DTMRI(coordinateAxesTool,actor)
    
    # add event handling for slices
    EvActivateBindingSet DTMRISlice0Events
    EvActivateBindingSet DTMRISlice1Events
    EvActivateBindingSet DTMRISlice2Events

    # add event handling for 3D
    EvActivateBindingSet DTMRI3DEvents

    # configure all scrolled GUIs so frames inside fit
    DTMRISizeScrolledGUI $DTMRI(scrolledGui,advanced)

    # color label selection widgets
    LabelsColorWidgets


    # Default to reformatting along with the currently active slice
    set DTMRI(mode,reformatType) $Slice(activeID)

    #Add our actors the first time we enter the module during exec
    if {$DTMRI(vtk,actors,firstEnter)} {
        # do not add actors, since pipeline has no input yet. add in DTMRISetActive instead.
        #DTMRIAddAllActors
        set DTMRI(vtk,actors,firstEnter) 0
    } else {  
      # Add our actors if removed on module exit.
      if {$DTMRI(vtk,actors,removeOnExit)} {
      DTMRIAddAllActors
      } else {
      #Reconnect glyphs vis pipeline
      DTMRI(vtk,glyphs,append) SetOutput [DTMRI(vtk,glyphs,mapper) GetInput]
      }
    }  
    Render3D

    #Update LMI logo
    set modulepath $::PACKAGE_DIR_VTKDTMRI/../../../images
    if {[file exist [ExpandPath [file join \
                     $modulepath "slicerLMIlogo.ppm"]]]} {
        image create photo iWelcome \
        -file [ExpandPath [file join $modulepath "slicerLMIlogo.ppm"]]
    }
}

#-------------------------------------------------------------------------------
# .PROC DTMRIExit
# Called when this module is exited by the user.  Pops the event manager
# for this module.  
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIExit {} {
    global DTMRI View
    
    # unset global flag to avoid possible render loop
    set View(resetCameraClippingRange) 1

    # get rid of event handling for csys
    #CsysPopBindings DTMRI
    # remove actor for csys
    #MainRemoveActor DTMRI(coordinateAxesTool,actor)


    # remove event handling for slices
    EvDeactivateBindingSet DTMRISlice0Events
    EvDeactivateBindingSet DTMRISlice1Events
    EvDeactivateBindingSet DTMRISlice2Events

    # remove event handling for 3D
    EvDeactivateBindingSet DTMRI3DEvents

    # Remove our actors if the user wants that on module exit.
    if {$DTMRI(vtk,actors,removeOnExit)} {
        DTMRIRemoveAllActors
    } else {
    #Disconnect vis glyphs pipeline
    DTMRI(vtk,glyphs,append) UnRegisterAllOutputs
    }
    
    # make 3D slices opaque now
    #MainSlicesReset3DOpacity
    
    #Restore standar slicer logo
    image create photo iWelcome \
        -file [ExpandPath [file join gui "welcome.ppm"]]


}

################################################################
#  Procedures for building the GUI
################################################################

#-------------------------------------------------------------------------------
# .PROC DTMRIBuildGUI
# Builds the GUI panel.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIBuildGUI {} {
    global Module Gui DTMRI Label Volume Tensor

    #-------------------------------------------
    # Frame Hierarchy:
    #-------------------------------------------
    # Help
    # Display
    #    Active
    #       VisMethods
    #          VisParams
    #             None
    #             Glyphs
    #             Tracts
    #             AutoTracts
    #             SaveTracts
    #       VisUpdate
    # ROI
    # Scalars
    # Props
    # Advanced
    # Diffuse
    #-------------------------------------------

    #puts "Lauren in DTMRIBuildGUI, fix the frame hierarchy comment"

    #-------------------------------------------
    # Help frame
    #-------------------------------------------
    # Write the "help" in the form of psuedo-html.  
    # Refer to the documentation for details on the syntax.
    #
    set help "
    This module allows visualization of DTMRI-valued data, 
especially Diffusion DTMRI MRI.
    <P>

    For <B>tractography</B>, point at the voxel of interest with the mouse and click\n the letter '<B>s</B>' (for start, or streamline). To <B>delete</B> a tract, point at it and click '<B>d</B>' (for delete).

    <P>
    Description by tab:
    <BR>
    <B>Disp (Visualization and Display Settings Tab)</B>
    <BR>
    <UL>
    <LI><B>3D View Settings:</B> click 'DTMRIs' view for transparent slices (this makes it easier to see 3D glyphs and tracts). 
    <LI><B>Display Glyphs:</B> turn glyphs on and off. Glyphs are little models for each DTMRI.  They display the eigensystem (principal directions of diffusion).
    <LI><B>Glyphs on Slice:</B> glyphs are displayed in the 3D view over this reformatted slice.  The slice-selection buttons are colored to match the colors of the three slice windows at the bottom of the Viewer window.
    <LI><B>Display Tracts:</B> turn display of tracts on and off, or delete all tracts.  Tracts are seeded when you point the mouse and hit the 's' key.  There are many more settings for tracts under the Visualization Menu below.
    <LI><B>Visualization Menu:</B> Settings for Tracts and Glyphs.
    </UL>


    <P>
    <B>Props Tab</B>
    <BR>
    <UL>
    <LI>This tab is for file reading/DTMRI conversion.
    </UL>
    "
    regsub -all "\n" $help {} help
    MainHelpApplyTags DTMRI $help
    MainHelpBuildGUI DTMRI



#############################################################################################
#############################################################################################
#############################################################################################

    #-------------------------------------------
    # Input frame
    #-------------------------------------------
 
    set fInput $Module(DTMRI,fInput)



    set f $fInput
    frame $f.fTitle -bg $Gui(backdrop)
    pack $f.fTitle -side top -padx $Gui(pad) -pady $Gui(pad) -fill x -anchor w


    Notebook:create $f.fNotebook \
                        -pages {{Option 1} {Option 2} {Option 3}} \
                        -pad 2 \
                        -bg $Gui(activeWorkspace) \
                        -height 260 \
                        -width 240
    pack $f.fNotebook -fill both -expand 1

    set f $fInput.fNotebook

    set FrameOption1 [Notebook:frame $f {Option 1}] 
    set FrameOption2 [Notebook:frame $f {Option 2}]
    set FrameOption3 [Notebook:frame $f {Option 3}]

#    foreach frame "$FrameOption1 $FrameOption2 $FrameOption3" {
#        frame $frame -bg $Gui(activeWorkspace)
#        pack $frame -side top -padx $Gui(pad) -pady $Gui(pad) -fill x -anchor w
#    }

    # $f.fTitle configure -bg $Gui(backdrop)
    foreach frame "$FrameOption1 $FrameOption2 $FrameOption3" {
        $frame configure  -relief groove -bd 3 
        foreach secframe "OptionNumber Input What How" {
        frame $frame.f$secframe -bg $Gui(activeWorkspace)
        pack $frame.f$secframe -side top -padx $Gui(pad) -pady $Gui(pad) -fill x -anchor w
    }
    DevAddLabel $frame.fInput.l1 "The input is:"
    $frame.fInput.l1 configure -font {helvetica 7 normal}
    DevAddLabel $frame.fWhat.l1 "What to do:"
    $frame.fWhat.l1 configure -font {helvetica 7 normal}
    DevAddLabel $frame.fHow.l1 "How to:"
    $frame.fHow.l1 configure -font {helvetica 7 normal}

    foreach secframe "Input What How" {
        pack $frame.f$secframe.l1 -side top -anchor w -padx $Gui(pad) -pady 0
        }
    }



    #-------------------------------------------
    # Input->Title frame
    #-------------------------------------------
    set f $fInput.fTitle

    foreach frame "Wellcome Select" {
        frame $f.f$frame -bg $Gui(backdrop)
        pack $f.f$frame -side top -padx $Gui(pad) -pady $Gui(pad) -fill x
    }

    #-------------------------------------------
    # Input->Title frame->Wellcome
    #-------------------------------------------
    set f $fInput.fTitle.fWellcome
    
    DevAddLabel $f.lWellcome "Welcome to the DTMRI Module"
    $f.lWellcome configure -fg White -font {helvetica 10 bold}  -bg $Gui(backdrop) -bd 0 -relief groove
    pack $f.lWellcome -side top -padx $Gui(pad) -pady $Gui(pad)

    DevAddLabel $f.lOption "Select Option"
    $f.lOption configure -fg White -font {helvetica 9 normal}  -bg $Gui(backdrop) -bd 0
    pack $f.lOption -side top -padx $Gui(pad) -pady 0


    #-------------------------------------------
    # Input->Option1 frame->OptionNumber
    #-------------------------------------------
    set f $FrameOption1.fOptionNumber

    DevAddLabel $f.lnumber "Option 1"
    $f.lnumber configure -font {helvetica 10 bold}
    pack $f.lnumber -side top -padx $Gui(pad) -pady $Gui(pad) -anchor w
    

    #-------------------------------------------
    # Input->Option1 frame->Input
    #-------------------------------------------
    set f $FrameOption1.fInput

    DevAddLabel $f.l2 "You have loaded LSDI gradient data\n from scanner ( I.* )"
    $f.l2 configure -font {helvetica 8 bold}
    pack $f.l2 -side top -padx 10 -pady 2 -anchor w
    

    #-------------------------------------------
    # Input->Option1 frame->What
    #-------------------------------------------
    set f $FrameOption1.fWhat

    DevAddLabel $f.l2 "Run LSDI script"
    $f.l2 configure -font {helvetica 8 bold} -justify left
    pack $f.l2 -side top -padx 10 -pady 2 -anchor w
    

    #-------------------------------------------
    # Input->Option1 frame->How
    #-------------------------------------------
    set f $FrameOption1.fHow

    frame $f.f1 -bg $Gui(activeWorkspace)
    pack $f.f1 -side left -padx 8 -pady 2 -anchor w

    # menu to select a volume: will set Volume(activeID)
    DevAddSelectButton  Volume $f.f1 Active "Select Input Volume:" left "Input Volume to Run LSDI Script to." 13 BLA
    $f.f1.lActive configure -bg $Gui(activeWorkspace) -fg black -font {helvetica 8 bold} -justify left
    $f.f1.mbActive configure -heigh 1 -bd 2 -pady 4 -bg $Gui(activeWorkspace)
    
    # Append these menus and buttons to lists 
    # that get refreshed during UpdateMRML
    lappend Volume(mbActiveList) $f.f1.mbActive
    lappend Volume(mActiveList) $f.f1.mbActive.m
    
    frame $f.f2 -bg $Gui(activeWorkspace)
    pack $f.f2 -side left -padx 0 -pady 2 -anchor w

    label $f.f2.l -bg $Gui(activeWorkspace) -text and -font {helvetica 8 bold}
    pack $f.f2.l -side top -padx 0 -pady 2 -anchor n

    button $f.f2.bButton -bg $Gui(activeWorkspace) -text "Run Script" -font {helvetica 6 normal} -heigh 1 -command {
    RunLSDIrecon
        DTMRIDisplayNewData
    }
    pack $f.f2.bButton -side top -padx 0 -pady $Gui(pad) -anchor n -anchor s
    TooltipAdd $f.f2.bButton "Once Selected a Volume Data, \n Press this Button to Run Script.\n Notice that the Volume Data to convert \n must be in a separate directory \n with no other data."

    #-------------------------------------------
    # Input->Option2 frame->OptionNumber
    #-------------------------------------------
    set f $FrameOption2.fOptionNumber

    DevAddLabel $f.lnumber "Option 2"
    $f.lnumber configure -font {helvetica 10 bold}
    pack $f.lnumber -side top -padx $Gui(pad) -pady $Gui(pad) -anchor w
    

    #-------------------------------------------
    # Input->Option2 frame->Input
    #-------------------------------------------
    set f $FrameOption2.fInput

    DevAddLabel $f.l2 "You have loaded DTMRI gradient data\n or output data from LSDI scripts (D.*)\n This option for non LSDI data!"
    $f.l2 configure -font {helvetica 8 bold}
    pack $f.l2 -side top -padx 10 -pady 2 -anchor w
    

    #-------------------------------------------
    # Input->Option2 frame->What
    #-------------------------------------------
    set f $FrameOption2.fWhat

    DevAddLabel $f.l2 "Calculate tensors from gradient data"
    $f.l2 configure -font {helvetica 8 bold}
    pack $f.l2 -side top -padx 10 -pady 2 -anchor w
    

    #-------------------------------------------
    # Input->Option2 frame->How
    #-------------------------------------------
    set f $FrameOption2.fHow

    DevAddLabel $f.l2 "Press 'Convert' Tab above\n and follow instructions"
    $f.l2 configure -font {helvetica 8 bold}
    pack $f.l2 -side top -padx 10 -pady 2 -anchor w

    #-------------------------------------------
    # Input->Option3 frame->OptionNumber
    #-------------------------------------------
    set f $FrameOption3.fOptionNumber

    DevAddLabel $f.lnumber "Option 3"
    $f.lnumber configure -font {helvetica 10 bold}
    pack $f.lnumber -side top -padx $Gui(pad) -pady $Gui(pad) -anchor w
    

    #-------------------------------------------
    # Input->Option3 frame->Input
    #-------------------------------------------
    set f $FrameOption3.fInput

    DevAddLabel $f.l2 "You have loaded a vtk tensor volume"
    $f.l2 configure -font {helvetica 8 bold}
    pack $f.l2 -side top -padx 10 -pady 2 -anchor w
    

    #-------------------------------------------
    # Input->Option3 frame->What
    #-------------------------------------------
    set f $FrameOption3.fWhat

    DevAddLabel $f.l2 "The data does not need to be\n further converted. Ready to start\n visualizing and working"
    $f.l2 configure -font {helvetica 8 bold}
    pack $f.l2 -side top -padx 10 -pady 2 -anchor w


    #-------------------------------------------
    # Input->Option3 frame->How
    #-------------------------------------------
    set f $FrameOption3.fHow

    DevAddLabel $f.l2 "Press 'Display',\n 'ROI' or 'Scalar' Tab"
    $f.l2 configure -font {helvetica 8 bold} -justify left
    pack $f.l2 -side top -padx 10 -pady 2 -anchor w






#############################################################################################
#############################################################################################
#############################################################################################




    
    #-------------------------------------------
    # Display frame
    #-------------------------------------------
    set fDisplay $Module(DTMRI,fDisplay)
    set f $fDisplay

    frame $f.fActive    -bg $Gui(backdrop) -relief sunken -bd 2
    pack $f.fActive -side top -padx $Gui(pad) -pady $Gui(pad) -fill x

    frame $f.fSettings  -bg $Gui(activeWorkspace)
    pack $f.fSettings -side top -padx $Gui(pad) -pady $Gui(pad) -fill x
    
    frame $f.fRemove  -bg $Gui(activeWorkspace)
    pack $f.fRemove -side top -padx $Gui(pad) -pady $Gui(pad) -fill x

#    frame $f.fGlyphsMode  -bg $Gui(activeWorkspace)
#    pack $f.fGlyphsMode -side top -padx $Gui(pad) -pady $Gui(pad) -fill x

    frame $f.fNotebook  -bg $Gui(activeWorkspace)
    pack $f.fNotebook -side top -padx $Gui(pad) -pady $Gui(pad) -fill x

#    frame $f.fTractsMode  -bg $Gui(activeWorkspace)
#    pack $f.fTractsMode -side top -padx $Gui(pad) -pady $Gui(pad) -fill x

#    frame $f.fVisMethods  -bg $Gui(activeWorkspace)
#    pack $f.fVisMethods -side top -padx $Gui(pad) -pady $Gui(pad) -fill both -expand true
#    #$f.fVisMethods config -relief groove -bd 3
#    $f.fVisMethods config -relief sunken -bd 2

#    foreach frame "VisUpdate" {
#        frame $f.f$frame -bg $Gui(activeWorkspace)
#        pack $f.f$frame -side top -padx $Gui(pad) -pady $Gui(pad) -fill both
#    }

    
    #-------------------------------------------
    # Display->Active frame
    #-------------------------------------------
    set f $fDisplay.fActive

    # menu to select active DTMRI
    DevAddSelectButton  Tensor $f Active "Active DTMRI:" Pack \
    "Active DTMRI" 20 BLA 
    
    # Append these menus and buttons to lists 
    # that get refreshed during UpdateMRML
    lappend Tensor(mbActiveList) $f.mbActive
    lappend Tensor(mActiveList) $f.mbActive.m

    #-------------------------------------------
    # Display->Settings frame
    #-------------------------------------------
    set f $fDisplay.fSettings

    DevAddLabel $f.l "3D View Settings:"
    pack $f.l -side left -padx $Gui(pad) -pady 0

    foreach vis $DTMRI(mode,visualizationSettingsTypeList) tip $DTMRI(mode,visualizationSettingsTypeList,tooltips) {
        eval {radiobutton $f.rMode$vis \
          -text "$vis" -value "$vis" \
          -variable DTMRI(mode,visualizationSettingsType) \
          -command {DTMRIApplyVisualizationSettings} \
          -indicatoron 0} $Gui(WCA) 
        pack $f.rMode$vis -side left -padx 0 -pady 0
        TooltipAdd  $f.rMode$vis $tip
    }   

    set f $fDisplay.fRemove

    eval {label $f.lRemove -text "Remove on Exit: "} $Gui(WLA)
    pack $f.lRemove -side left -pady $Gui(pad) -padx $Gui(pad)
    # Add menu items
    foreach vis $DTMRI(mode,visualizationRemoveTypeList) val $DTMRI(mode,visualizationRemoveTypeValue) \
            tip $DTMRI(mode,visualizationRemoveTypeList,tooltips) {
        eval {radiobutton $f.r$vis \
              -text "$vis" \
              -value $val \
              -variable DTMRI(vtk,actors,removeOnExit) \
              -indicatoron 0} $Gui(WCA)
        pack $f.r$vis -side left -padx 0 -pady 0
        TooltipAdd  $f.r$vis $tip     
   }          

    #-------------------------------------------
    # Display->Notebook frame
    #-------------------------------------------
    set f $fDisplay.fNotebook


    Notebook:create $f.fNotebook \
                    -pages {{Display Glyphs} {Tractography}} \
                    -pad 2 \
                    -bg $Gui(activeWorkspace) \
                    -height 600 \
                    -width 240
    pack $f.fNotebook -fill both -expand 1

    set f $f.fNotebook

    set Glyph [Notebook:frame $f {Display Glyphs}] 
    set Tract [Notebook:frame $f {Tractography}]

    frame $Glyph.fReformat  -bg $Gui(activeWorkspace)
    pack $Glyph.fReformat -side top -padx $Gui(pad) -pady $Gui(pad) -fill x

    frame $Glyph.fGlyphsMode  -bg $Gui(activeWorkspace)
    pack $Glyph.fGlyphsMode -side top -padx $Gui(pad) -pady $Gui(pad) -fill x

    frame $Tract.fTractsMode  -bg $Gui(activeWorkspace)
    pack $Tract.fTractsMode -side top -padx $Gui(pad) -pady $Gui(pad) -fill x

    frame $Glyph.fVisMethods  -bg $Gui(activeWorkspace) -relief sunken -bd 2
    pack $Glyph.fVisMethods -side top -padx $Gui(pad) -pady $Gui(pad) -fill both -expand true

    frame $Tract.fVisMethods  -bg $Gui(activeWorkspace) -bd 2
    pack $Tract.fVisMethods -side top -padx $Gui(pad) -pady $Gui(pad) -fill both -expand true


    #-------------------------------------------
    # Display->Notebook -> Glyph frame -> Reformat
    #-------------------------------------------
    set f $Glyph.fReformat

    DevAddLabel $f.l "Glyphs on Slice:"
    pack $f.l -side left -padx $Gui(pad) -pady 0

    set colors [list  $Gui(slice0) $Gui(slice1) $Gui(slice2) $Gui(activeWorkspace) $Gui(activeWorkspace)]
    set widths [list  2 2 2 4 4]

    foreach vis $DTMRI(mode,reformatTypeList) \
    tip $DTMRI(mode,reformatTypeList,tooltips) \
    text $DTMRI(mode,reformatTypeList,text) \
    color $colors \
    width $widths {
        eval {radiobutton $f.rMode$vis \
              -text "$text" -value "$vis" \
              -variable DTMRI(mode,reformatType) \
              -command {DTMRIUpdateReformatType} \
              -indicatoron 0 } $Gui(WCA) \
        {-bg $color -selectcolor $color -width $width}
        pack $f.rMode$vis -side left -padx 0 -pady 0
        TooltipAdd  $f.rMode$vis $tip
    }
    
    #-------------------------------------------
    # Display -> Notebook -> Glyph frame ->->GlyphsMode frame
    #-------------------------------------------
    set f $Glyph.fGlyphsMode

    eval {label $f.lVis -text "Display Glyphs: "} $Gui(WLA)
    pack $f.lVis -side left -pady $Gui(pad) -padx $Gui(pad)
    # Add menu items
    foreach vis $DTMRI(mode,visualizationType,glyphsOnList) \
    tip $DTMRI(mode,visualizationType,glyphsOnList,tooltip) {
        eval {radiobutton $f.r$vis \
              -text $vis \
              -command "DTMRIUpdate" \
              -value $vis \
              -variable DTMRI(mode,visualizationType,glyphsOn) \
              -indicatoron 0} $Gui(WCA)

        pack $f.r$vis -side left -fill x
        TooltipAdd $f.r$vis $tip
    }

    #-------------------------------------------
    # Display-> Notebook -> Tract frame->TractsMode frame
    #-------------------------------------------
    set f $Tract.fTractsMode

    eval {label $f.lVis -text "Display 'Tracts': "} $Gui(WLA)
    pack $f.lVis -side left -pady $Gui(pad) -padx $Gui(pad)
    # Add menu items
    foreach vis $DTMRI(mode,visualizationType,tractsOnList) \
    tip $DTMRI(mode,visualizationType,tractsOnList,tooltip) {
        eval {radiobutton $f.r$vis \
              -text $vis \
              -command "DTMRIUpdateStreamlines" \
              -value $vis \
              -variable DTMRI(mode,visualizationType,tractsOn) \
              -indicatoron 0} $Gui(WCA)

        pack $f.r$vis -side left -fill x
        TooltipAdd $f.r$vis $tip
    }

    #-------------------------------------------
    # Display-> Notebook -> Tract frame ->VisMethods frame
    #-------------------------------------------
    set f $Tract.fVisMethods

    frame $f.fVisMode -bg $Gui(activeWorkspace) 
    pack $f.fVisMode -side top -padx 0 -pady 0 -fill x

    # note the height is necessary to place frames inside later
    frame $f.fVisParams -bg $Gui(activeWorkspace) -height 500
    pack $f.fVisParams -side top -padx 0 -pady $Gui(pad) -fill both -expand true
    $f.fVisMode config -relief sunken -bd 2
    #$f.fVisParams config -relief groove -bd 3
    #$f.fVisParams config -bd 3

    #-----------------------------------------2--
    # Display-> Notebook ->Tract frame ->VisMethods ->VisMode frame
    #-------------------------------------------
    set f $Tract.fVisMethods.fVisMode

    eval {label $f.lVis -text "Visualization Menu: "} $Gui(WLA)
    eval {menubutton $f.mbVis -text $DTMRI(mode,visualizationTypeGui) \
          -relief raised -bd 2 -width 10 \
          -menu $f.mbVis.m} $Gui(WMBA)
    eval {menu $f.mbVis.m} $Gui(WMA)
    pack $f.lVis $f.mbVis -side left -pady $Gui(pad) -padx $Gui(pad)
    # Add menu items
    foreach vis $DTMRI(mode,visualizationTypeGuiList) {
        $f.mbVis.m add command -label $vis \
        -command "DTMRIRaiseMoreOptionsFrame $vis"
    }
    # save menubutton for config
    set DTMRI(gui,mbVisMode) $f.mbVis
    # Add a tooltip
    TooltipAdd $f.mbVis $DTMRI(mode,visualizationTypeGuiList,tooltip)

    #-------------------------------------------
    # Display-> Notebook ->Tract frame ->VisMethods ->VisParams frame
    #-------------------------------------------
    set f $Tract.fVisMethods.fVisParams
    set fParams $f

    # make a parameters frame for each visualization type
    # types are: Help  Tracts AutoTracts SaveTracts
    foreach frame $DTMRI(mode,visualizationTypeGuiList) {
        frame $f.f$frame -bg $Gui(activeWorkspace)
        # for raising one frame at a time
        place $f.f$frame -in $f -relheight 1.0 -relwidth 1.0
        #pack $f.f$frame -side top -padx 0 -pady $Gui(pad) -fill x
        set DTMRI(frame,$frame) $f.f$frame
    }
    raise $DTMRI(frame,$DTMRI(mode,visualizationTypeGui))

    ##########################################################
    #  HELP   (frame raised when Glyphs are selected)
    ##########################################################

    #-------------------------------------------
    # Display-> Notebook ->Tract frame->VisMethods->VisParams->Help frame
    #-------------------------------------------
    set f $fParams.fHelp

    DevAddLabel $f.l "Select from the Visualization\n menu above to adjust\n visualization parameters."
    DevAddLabel $f.l2 "For tractography, point at \nthe voxel of interest with\n the mouse and click\n the letter 's'. To delete\n a tract, point and click 'd'."
    pack $f.l $f.l2 -side top -padx $Gui(pad) -pady $Gui(pad)

    ##########################################################
    #  GLYPHS   (frame raised when Glyphs are selected)
    ##########################################################

    #-------------------------------------------
    # Display-> Notebook ->Glyph frame->VisMethods->VisParams->Glyphs frame
    #-------------------------------------------
    frame $Glyph.fVisMethods.fGlyphs -bg $Gui(activeWorkspace)
    pack $Glyph.fVisMethods.fGlyphs -side top -padx 0 -pady $Gui(pad) -fill x

    set f $Glyph.fVisMethods.fGlyphs

    foreach frame "Resolution GlyphType Lines Colors ScalarBar GlyphScalarRange Slider" {
        frame $f.f$frame -bg $Gui(activeWorkspace)
        pack $f.f$frame -side top -padx $Gui(pad) -pady $Gui(pad) -fill both
    }

    #-------------------------------------------
    # Display-> Notebook ->Glyph frame->VisMethods->VisParams->Glyphs->Resolution frame
    #-------------------------------------------
    set f $Glyph.fVisMethods.fGlyphs.fResolution
    
    eval {label $f.l -text "Resolution (fine->gross):"\
          -width 12 -justify right } $Gui(WLA)

    eval {scale $f.s -from $DTMRI(mode,glyphResolution,min) \
                          -to $DTMRI(mode,glyphResolution,max)    \
          -variable  DTMRI(mode,glyphResolution)\
      -command DTMRIUpdateGlyphResolution \
          -orient vertical     \
          -resolution 1      \
          } $Gui(WSA)

      pack $f.l $f.s -side left -padx $Gui(pad) -pady 0


    #-------------------------------------------
    # Display-> Notebook ->Glyph frame->VisMethods->VisParams->Glyphs->GlyphType frame
    #-------------------------------------------
    set f $Glyph.fVisMethods.fGlyphs.fGlyphType

    DevAddLabel $f.l "Glyph Type:"
    pack $f.l -side left -padx $Gui(pad) -pady 1

    eval {menubutton $f.mbVis -text $DTMRI(mode,glyphType) \
          -relief raised -bd 2 -width 12 \
          -menu $f.mbVis.m} $Gui(WMBA)
    eval {menu $f.mbVis.m} $Gui(WMA)
    pack  $f.mbVis -side left -pady 1 -padx $Gui(pad)
    # Add menu items
    foreach vis $DTMRI(mode,glyphTypeList) {
        $f.mbVis.m add command -label $vis \
        -command "$f.mbVis config -text $vis; set DTMRI(mode,glyphType) $vis; DTMRIUpdate"
    }
    # save menubutton for config
    set DTMRI(gui,mbGlyphType) $f.mbVis
    # Add a tooltip
    #TooltipAdd $f.mbVis $DTMRI(mode,glyphColorList,tooltip)

    #-------------------------------------------
    # Display-> Notebook ->Glyph frame->VisMethods->VisParams->Glyphs->Lines frame
    #-------------------------------------------

    set f $Glyph.fVisMethods.fGlyphs.fLines

    DevAddLabel $f.l "Line Type:"
    pack $f.l -side left -padx $Gui(pad) -pady 1

    foreach vis $DTMRI(mode,glyphEigenvectorList) tip $DTMRI(mode,glyphEigenvectorList,tooltips) {
        eval {radiobutton $f.rMode$vis \
          -text "$vis" -value "$vis" \
          -variable DTMRI(mode,glyphEigenvector) \
          -command DTMRIUpdateGlyphEigenvector \
          -indicatoron 0} $Gui(WCA)
        pack $f.rMode$vis -side left -padx 0 -pady 1
        TooltipAdd $f.rMode$vis $tip
    }

    #-------------------------------------------
    # Display-> Notebook ->Glyph frame->VisMethods->VisParams->Glyphs->Colors frame
    #-------------------------------------------
    set f $Glyph.fVisMethods.fGlyphs.fColors

    eval {label $f.lVis -text "Color by: "} $Gui(WLA)
    eval {menubutton $f.mbVis -text $DTMRI(mode,glyphColor) \
          -relief raised -bd 2 -width 12 \
          -menu $f.mbVis.m} $Gui(WMBA)
    eval {menu $f.mbVis.m} $Gui(WMA)
    pack $f.lVis $f.mbVis -side left -pady 1 -padx $Gui(pad)
    # Add menu items
    foreach vis $DTMRI(mode,glyphColorList) {
        $f.mbVis.m add command -label $vis \
        -command "set DTMRI(mode,glyphColor) $vis; DTMRIUpdateGlyphColor"
    }
    # save menubutton for config
    set DTMRI(gui,mbGlyphColor) $f.mbVis
    # Add a tooltip
    TooltipAdd $f.mbVis $DTMRI(mode,glyphColorList,tooltip)

    #-------------------------------------------
    # Display-> Notebook ->Glyph frame->VisMethods->VisParams->Glyphs->ScalarBar frame
    #-------------------------------------------
    set f $Glyph.fVisMethods.fGlyphs.fScalarBar

    DevAddLabel $f.l "Scalar Bar:"
    pack $f.l -side left -padx $Gui(pad) -pady 1

    foreach vis $DTMRI(mode,scalarBarList) tip $DTMRI(mode,scalarBarList,tooltips) {
        eval {radiobutton $f.rMode$vis \
          -text "$vis" -value "$vis" \
          -variable DTMRI(mode,scalarBar) \
          -command {DTMRIUpdateScalarBar} \
          -indicatoron 0} $Gui(WCA)
        pack $f.rMode$vis -side left -padx 0 -pady 1
        TooltipAdd  $f.rMode$vis $tip
    }

    #-------------------------------------------
    # Display-> Notebook ->Glyph frame->VisMethods->VisParams->Glyphs->GlyphScalarRange frame
    #-------------------------------------------
    set f $Glyph.fVisMethods.fGlyphs.fGlyphScalarRange

    DevAddLabel $f.l "Scalar Range:"
    pack $f.l -side left -padx $Gui(pad) -pady 1

    foreach vis $DTMRI(mode,glyphScalarRangeList) tip $DTMRI(mode,glyphScalarRangeList,tooltips) {
        eval {radiobutton $f.rMode$vis \
          -text "$vis" -value "$vis" \
          -variable DTMRI(mode,glyphScalarRange) \
          -command {DTMRIUpdateGlyphScalarRange; Render3D} \
          -indicatoron 0} $Gui(WCA)
        pack $f.rMode$vis -side left -padx 0 -pady 1
        TooltipAdd  $f.rMode$vis $tip
    }

    #-------------------------------------------
    # Display-> Notebook ->Glyph frame->VisMethods->VisParams->Glyphs->Slider frame
    #-------------------------------------------
    foreach slider "Low Hi" text "Lo Hi" {

        set f $Glyph.fVisMethods.fGlyphs.fSlider

        frame $f.f$slider -bg $Gui(activeWorkspace)
        pack $f.f$slider -side top -padx $Gui(pad) -pady 1
        set f $f.f$slider

        eval {label $f.l$slider -text "$text:"} $Gui(WLA)
        eval {entry $f.e$slider -width 10 \
          -textvariable DTMRI(mode,glyphScalarRange,[Uncap $slider])} \
        $Gui(WEA)
        eval {scale $f.s$slider -from $DTMRI(mode,glyphScalarRange,min) \
          -to $DTMRI(mode,glyphScalarRange,max) \
          -length 90 \
          -variable DTMRI(mode,glyphScalarRange,[Uncap $slider]) \
          -resolution 0.1 \
          -command {DTMRIUpdateGlyphScalarRange; Render3D}} \
        $Gui(WSA) {-sliderlength 15}
        pack $f.l$slider $f.e$slider $f.s$slider -side left  -padx $Gui(pad)
        set DTMRI(gui,slider,$slider) $f.s$slider
        bind $f.e${slider} <Return>   \
        "DTMRIUpdateGlyphScalarRange ${slider}; Render3D"

    }

    ##########################################################
    #  TRACTS   (frame raised when Tracts are selected)
    ##########################################################

    #-------------------------------------------
    # Display-> Notebook ->Tract frame->VisMethods->VisParams->Tracts frame
    #-------------------------------------------
    set f $fParams.fTracts

    foreach frame "Colors Entries" {
        frame $f.f$frame -bg $Gui(activeWorkspace)
        pack $f.f$frame -side top -padx 0 -pady $Gui(pad) -fill x
    }

    #-------------------------------------------
    # Display-> Notebook ->Tract frame->VisMethods->VisParams->Tracts->Colors frame
    #-------------------------------------------
    set f $fParams.fTracts.fColors
    foreach frame "ChooseColor ColorBy ColorByVol" {
        frame $f.f$frame -bg $Gui(activeWorkspace)
        pack $f.f$frame -side top -padx $Gui(pad) -pady $Gui(pad) -fill x
    }

    #-------------------------------------------
    # Display-> Notebook ->Tract frame->VisMethods->VisParams->Tracts->Colors->ChooseColor frame
    #-------------------------------------------
    set f $fParams.fTracts.fColors.fChooseColor

    DevAddButton $f.b "Color:" {ShowColors DTMRIUpdateTractColorToSolid}
    eval {entry $f.e -width 20 \
          -textvariable Label(name)} $Gui(WEA) \
            {-bg $Gui(activeWorkspace) -state disabled}
    pack $f.b $f.e -side left -padx $Gui(pad) -pady $Gui(pad) -fill x

    lappend Label(colorWidgetList) $f.e

    #-------------------------------------------
    # Display-> Notebook ->Tract frame->VisMethods->VisParams->Tracts->Colors->ColorBy frame
    #-------------------------------------------
    set f $fParams.fTracts.fColors.fColorBy

    eval {label $f.lVis -text "Color by: "} $Gui(WLA)
    eval {menubutton $f.mbVis -text $DTMRI(mode,tractColor) \
          -relief raised -bd 2 -width 12 \
          -menu $f.mbVis.m} $Gui(WMBA)
    eval {menu $f.mbVis.m} $Gui(WMA)
    pack $f.lVis $f.mbVis -side left -pady 1 -padx $Gui(pad)
    # Add menu items
    foreach vis $DTMRI(mode,tractColorList) {
        $f.mbVis.m add command -label $vis \
        -command "set DTMRI(mode,tractColor) $vis; DTMRIUpdateTractColor"
    }
    # save menubutton for config
    set DTMRI(gui,mbTractColor) $f.mbVis
    # Add a tooltip
    TooltipAdd $f.mbVis $DTMRI(mode,tractColorList,tooltip)

    #-------------------------------------------
    # Display-> Notebook ->Tract frame->VisMethods->VisParams->Tracts->Colors->ColorByVol frame
    #-------------------------------------------
    set f $fParams.fTracts.fColors.fColorByVol

    # menu to select a volume: will set Volume(activeID)
    set name ColorByVolume
    DevAddSelectButton  Volume $f $name "Color by Volume:" Pack \
    "First select Color by MultiColor, \nthen select the volume to use \nto color the tracts. \nFor example to color by FA, \ncreate the FA volume using the \n<More...> tab in this module, \nthen the <Scalars> tab.  \nThen select that volume from this list." \
    13
    
    # Append these menus and buttons to lists 
    # that get refreshed during UpdateMRML
    lappend Volume(mbActiveList) $f.mb$name
    lappend Volume(mActiveList) $f.mb$name.m

    #-------------------------------------------
    # Display-> Notebook ->Tract frame->VisMethods->VisParams->Tracts->Entries frame
    #-------------------------------------------
    set f $fParams.fTracts.fEntries

    frame $f.fTractingMethod -bg $Gui(activeWorkspace) 
    pack $f.fTractingMethod -side top -padx 0 -pady 0 -fill x

    # note the height is necessary to place frames inside later
    frame $f.fTractingVar -bg $Gui(activeWorkspace) -height 500
    pack $f.fTractingVar -side top -padx 0 -pady $Gui(pad) -fill both -expand true

    #    frame $f -bg $Gui(activeWorkspace)
    #    pack $f -side top -padx $Gui(pad) -pady 1 -fill x

    set f $fParams.fTracts.fEntries.fTractingMethod

    eval {label $f.lVis -text "Tracting Method: "} $Gui(WLA)
    eval {menubutton $f.mbVis -text $DTMRI(stream,tractingMethod) \
          -relief raised -bd 2 -width 12 \
          -menu $f.mbVis.m} $Gui(WMBA)
    eval {menu $f.mbVis.m} $Gui(WMA)
    pack $f.lVis $f.mbVis -side left -pady 1 -padx $Gui(pad)
    foreach vis $DTMRI(stream,tractingMethodList) {
        $f.mbVis.m add command -label $vis \
        -command "DTMRIUpdateTractingMethod $vis"
    }
    # save menubutton for config
    set DTMRI(gui,mbTractingMethod) $f.mbVis
    # Add a tooltip
    TooltipAdd $f.mbVis $DTMRI(stream,tractingMethodList,tooltip)

    set f $fParams.fTracts.fEntries.fTractingVar

    #    frame $f -bg $Gui(activeWorkspace)
    #place $f.fVar -in $f -relheight 1.0 -relwidth 1.0
    #    pack $f -side top -padx 0 -pady $Gui(pad) -fill both -expand true
    #    pack $f.fVisParams -side top -padx 0 -pady $Gui(pad) -fill both -expand true

    foreach frame $DTMRI(stream,tractingMethodList) {
        frame $f.f$frame -bg $Gui(activeWorkspace)
        # for raising one frame at a time
        place $f.f$frame -in $f -relheight 1.0 -relwidth 1.0
        #pack $f.f$frame -side top -padx 0 -pady 1 -fill x
        set DTMRI(stream,tractingFrame,$frame) $f.f$frame
    }
    raise $DTMRI(stream,tractingFrame,$DTMRI(stream,tractingMethod))
    
    set f $DTMRI(stream,tractingFrame,BSpline)
    
    frame $f.fBSplineOrder -bg $Gui(activeWorkspace) 
    pack $f.fBSplineOrder -side top -padx 0 -pady 0 -fill x

    set f $f.fBSplineOrder

    eval {label $f.lVis -text "Spline Order: "} $Gui(WLA)

    eval {menubutton $f.mbVis -text $DTMRI(stream,BSplineOrder) \
          -relief raised -bd 2 -width 12 \
          -menu $f.mbVis.m} $Gui(WMBA)
    eval {menu $f.mbVis.m} $Gui(WMA)
    pack $f.lVis $f.mbVis -side left -pady 1 -padx $Gui(pad)
    # Add menu items
    foreach vis $DTMRI(stream,BSplineOrderList) {
        $f.mbVis.m add command -label $vis \
        -command "DTMRIUpdateBSplineOrder $vis"
    }
    # save menubutton for config
    set DTMRI(gui,mbBSplineOrder) $f.mbVis
    # Add a tooltip
    TooltipAdd $f.mbVis $DTMRI(stream,BSplineOrderList,tooltip)

    set f $DTMRI(stream,tractingFrame,BSpline)
    
    frame $f.fMethodOrder -bg $Gui(activeWorkspace) 
    pack $f.fMethodOrder -side top -padx 0 -pady 0 -fill x

    set f $f.fMethodOrder

    eval {label $f.lVis -text "Method Order: "} $Gui(WLA)

    eval {menubutton $f.mbVis -text $DTMRI(stream,MethodOrder) \
          -relief raised -bd 2 -width 12 \
          -menu $f.mbVis.m} $Gui(WMBA)
    eval {menu $f.mbVis.m} $Gui(WMA)
    pack $f.lVis $f.mbVis -side left -pady 1 -padx $Gui(pad)
    # save menubutton for config
    set DTMRI(gui,mbMethodOrder) $f.mbVis
    # Add menu items
    foreach vis $DTMRI(stream,MethodOrderList) {
        $f.mbVis.m add command -label $vis \
        -command "set DTMRI(vtk,ivps) DTMRI(vtk,$vis); $DTMRI(gui,mbMethodOrder) config -text $vis"
    }
    # Add a tooltip
    TooltipAdd $f.mbVis $DTMRI(stream,BSplineOrderList,tooltip)

    foreach entry $DTMRI(stream,methodvariableList) \
        text $DTMRI(stream,methodvariableList,text) \
        tip $DTMRI(stream,methodvariableList,tooltips) {
        
        set f $DTMRI(stream,tractingFrame,BSpline)
        
        frame $f.f$entry -bg $Gui(activeWorkspace)
        #place $f.f$frame -in $f -relheight 1.0 -relwidth 1.0
        pack $f.f$entry -side top -padx $Gui(pad) -pady 1 -fill x
        set f $f.f$entry

        eval {label $f.l$entry -text "$text:"} $Gui(WLA)
        eval {entry $f.e$entry -width 10 \
              -textvariable DTMRI(stream,$entry)} \
                $Gui(WEA)
        TooltipAdd $f.l$entry $tip
        TooltipAdd $f.e$entry $tip
        pack $f.l$entry -side left  -padx $Gui(pad)
        pack $f.e$entry -side right  -padx $Gui(pad)
    }

    foreach entry $DTMRI(stream,variableList) \
    text $DTMRI(stream,variableList,text) \
    tip $DTMRI(stream,variableList,tooltips) {

        set f $DTMRI(stream,tractingFrame,NoSpline)

        frame $f.f$entry -bg $Gui(activeWorkspace)
        #place $f.f$frame -in $f -relheight 1.0 -relwidth 1.0
        pack $f.f$entry -side top -padx $Gui(pad) -pady 1 -fill x
        set f $f.f$entry

        eval {label $f.l$entry -text "$text:"} $Gui(WLA)
        eval {entry $f.e$entry -width 10 \
              -textvariable DTMRI(stream,$entry)} \
        $Gui(WEA)
        TooltipAdd $f.l$entry $tip
        TooltipAdd $f.e$entry $tip
        pack $f.l$entry -side left  -padx $Gui(pad)
        pack $f.e$entry -side right  -padx $Gui(pad)
    }

    foreach entry $DTMRI(stream,precisevariableList) \
        text $DTMRI(stream,precisevariableList,text) \
        tip $DTMRI(stream,precisevariableList,tooltips) {
        
        set f $DTMRI(stream,tractingFrame,BSpline)
        
        frame $f.f$entry -bg $Gui(activeWorkspace)
        #place $f.f$frame -in $f -relheight 1.0 -relwidth 1.0
        pack $f.f$entry -side top -padx $Gui(pad) -pady 1 -fill x
        set f $f.f$entry

        eval {label $f.l$entry -text "$text:"} $Gui(WLA)
        eval {entry $f.e$entry -width 10 \
              -textvariable DTMRI(stream,$entry)} \
                $Gui(WEA)
        TooltipAdd $f.l$entry $tip
        TooltipAdd $f.e$entry $tip
        pack $f.l$entry -side left  -padx $Gui(pad)
        pack $f.e$entry -side right  -padx $Gui(pad)
    }

    ##########################################################
    #  AUTOTRACTS   (frame raised when AutoTracts are selected)
    ##########################################################

    #-------------------------------------------
    # Display-> Notebook ->Tract frame->VisMethods->VisParams->AutoTracts frame
    #-------------------------------------------
    set f $fParams.fAutoTracts

    foreach frame "Label2 Entries" {
        frame $f.f$frame -bg $Gui(activeWorkspace)
        pack $f.f$frame -side top -padx 0 -pady 1 -fill x
    }

    #-------------------------------------------
    # Display-> Notebook ->Tract frame->VisMethods->VisParams->Autotracts->Label2 frame
    #-------------------------------------------
    set f $fParams.fAutoTracts.fLabel2

    DevAddLabel $f.l "Automatically start tractography\nfrom each voxel in an ROI."
    pack $f.l -side top -padx $Gui(pad) -pady $Gui(pad)


    #-------------------------------------------
    # Display-> Notebook ->Tract frame->VisMethods->VisParams->Tracts->Entries frame
    set f $fParams.fAutoTracts.fEntries
    foreach frame "Volume ChooseLabel Apply" {
        frame $f.f$frame -bg $Gui(activeWorkspace)
        pack $f.f$frame -side top -padx $Gui(pad) -pady $Gui(pad) -fill both
    }

    #-------------------------------------------

    #-------------------------------------------
    # Display-> Notebook ->Tract frame->VisMethods->VisParams->AutoTracts->Entries->Volume frame
    #-------------------------------------------
    set f $fParams.fAutoTracts.fEntries.fVolume

    # menu to select a volume: will set Volume(activeID)
    set name MaskLabelmap
    DevAddSelectButton  Volume $f $name "ROI Labelmap:" Grid \
    "This labelmap will be used to seed tracts."\
    13
    
    # Append these menus and buttons to lists 
    # that get refreshed during UpdateMRML
    lappend Volume(mbActiveList) $f.mb$name
    lappend Volume(mActiveList) $f.mb$name.m

    #-------------------------------------------
    # Display-> Notebook ->Tract frame->VisMethods->VisParams->AutoTracts->Entries->ChooseLabel frame
    #-------------------------------------------
    set f $fParams.fAutoTracts.fEntries.fChooseLabel

    # mask label
    eval {button $f.bOutput -text "Label:" \
          -command "ShowLabels DTMRIUpdateMaskLabel"} $Gui(WBA)
    eval {entry $f.eOutput -width 6 \
          -textvariable Label(label)} $Gui(WEA)
    bind $f.eOutput <Return>   "DTMRIUpdateMaskLabel"
    bind $f.eOutput <FocusOut> "DTMRIUpdateMaskLabel"
    eval {entry $f.eName -width 14 \
          -textvariable Label(name)} $Gui(WEA) \
            {-bg $Gui(activeWorkspace) -state disabled}
    grid $f.bOutput $f.eOutput $f.eName -padx 2 -pady $Gui(pad)
    grid $f.eOutput $f.eName -sticky w
    
    lappend Label(colorWidgetList) $f.eName

    TooltipAdd  $f.bOutput $DTMRI(mode,autoTractsLabel,tooltip)
    TooltipAdd  $f.eOutput $DTMRI(mode,autoTractsLabel,tooltip)
    TooltipAdd  $f.eName $DTMRI(mode,autoTractsLabel,tooltip)


    #-------------------------------------------
    # Display-> Notebook ->Tract frame->VisMethods->VisParams->AutoTracts->Entries->Apply frame
    #-------------------------------------------
    set f $fParams.fAutoTracts.fEntries.fApply
    DevAddButton $f.bApply "Seed 'Tracts' in ROI" \
        {puts "Seeding streamlines"; DTMRISeedStreamlinesFromSegmentation}
    pack $f.bApply -side top -padx $Gui(pad) -pady $Gui(pad)
    TooltipAdd  $f.bApply "Seed a 'tract' from each point in the ROI.\nThis can be slow; be patient."



    ##########################################################
    #  SAVETRACTS   (frame raised when SaveTracts are selected)
    ##########################################################

    #-------------------------------------------
    # Display-> Notebook ->Tract frame->VisMethods->VisParams->SaveTracts frame
    #-------------------------------------------
    set f $fParams.fSaveTracts

    foreach frame "Entries" {
        frame $f.f$frame -bg $Gui(activeWorkspace)
        pack $f.f$frame -side top -padx 0 -pady 1 -fill x
    }

    #-------------------------------------------
    # Display--> Notebook ->Tract frame>VisMethods->VisParams->SaveTracts->Entries frame
    #-------------------------------------------
    set f $fParams.fSaveTracts.fEntries
    foreach frame "Info1 Apply1 Info2 Apply2" {
        frame $f.f$frame -bg $Gui(activeWorkspace)
        pack $f.f$frame -side top -padx $Gui(pad) -pady $Gui(pad) -fill both
    }

    #-------------------------------------------
    # Display-> Notebook ->Tract frame->VisMethods->VisParams->SaveTracts->Entries->Info frame
    #-------------------------------------------
    set f $fParams.fSaveTracts.fEntries.fInfo1
    DevAddLabel $f.l "Save the tracts you have created."
    pack $f.l -side top -padx $Gui(pad) -pady $Gui(pad)

    #-------------------------------------------
    # Display-> Notebook ->Tract frame->VisMethods->VisParams->SaveTracts->Entries->Apply frame
    #-------------------------------------------
    set f $fParams.fSaveTracts.fEntries.fApply1
    DevAddButton $f.bApply "Save tracts in model file(s)" \
        {puts "Saving streamlines"; DTMRISaveStreamlinesAsModel}
    pack $f.bApply -side top -padx $Gui(pad) -pady $Gui(pad)
    TooltipAdd  $f.bApply "Save tracts to vtk file(s).\nEach color of tract will become a separate model.\n Choose the initial part of the filename, and models\nwill be saved as filename_0.vtk, filename_1.vtk, etc.\nThen you can load the models into slicer\n(they must be re-added to the mrml tree)."

    #-------------------------------------------
    # Display-> Notebook ->Tract frame->VisMethods->VisParams->SaveTracts->Entries->Info frame
    #-------------------------------------------
    set f $fParams.fSaveTracts.fEntries.fInfo2
    DevAddLabel $f.l "Save currently visible tracts as a polyline.\n Useful for further processing on tracts.\nONLY DEVELOPERS"
    pack $f.l -side top -padx $Gui(pad) -pady $Gui(pad)

    #-------------------------------------------
    # Display-> Notebook ->Tract frame->VisMethods->VisParams->SaveTracts->Entries->Apply frame
    #-------------------------------------------
    set f $fParams.fSaveTracts.fEntries.fApply2
    DevAddButton $f.bApply "Save tracts in vtk file" \
        {puts "Saving streamlines"; DTMRISaveStreamlinesAsPolyLines "" tracts}
    pack $f.bApply -side top -padx $Gui(pad) -pady $Gui(pad)
    TooltipAdd  $f.bApply "Save visible tracts to vtk file as a set of polylines."

    #-------------------------------------------
    # Display-> Notebook ->Tract frame->VisUpdate frame
    #-------------------------------------------
    #set f $fDisplay.fVisUpdate
    #DevAddButton $f.bTest "Junk" {puts "this button is junk"} 4    
    #pack $f.bTest -side top -padx 0 -pady 0



#############################################################################################
#############################################################################################
#############################################################################################


    #-------------------------------------------
    # ROI frame
    #-------------------------------------------
    set fROI $Module(DTMRI,fROI)
    set f $fROI

    frame $f.fActive    -bg $Gui(backdrop) -relief sunken -bd 2
    pack $f.fActive -side top -padx $Gui(pad) -pady $Gui(pad) -fill x

    foreach frame "Threshold Mask" {
        frame $f.f$frame -bg $Gui(activeWorkspace)
        pack $f.f$frame -side top -padx $Gui(pad) -pady $Gui(pad) -fill both
        $f.f$frame config -relief groove -bd 3
    }

    #-------------------------------------------
    # ROI->Active frame
    #-------------------------------------------
    set f $fROI.fActive

    # menu to select active DTMRI
    DevAddSelectButton  Tensor $f Active "Active DTMRI:" Pack \
    "Active DTMRI" 20 BLA 
    
    # Append these menus and buttons to lists 
    # that get refreshed during UpdateMRML
    lappend Tensor(mbActiveList) $f.mbActive
    lappend Tensor(mActiveList) $f.mbActive.m

    #-------------------------------------------
    # ROI->Threshold frame
    #-------------------------------------------
    set f $fROI.fThreshold

    foreach frame "Label Mode Slider" {
        frame $f.f$frame -bg $Gui(activeWorkspace)
        pack $f.f$frame -side top -padx $Gui(pad) -pady $Gui(pad) -fill both
    }

    #-------------------------------------------
    # ROI->Threshold->Label frame
    #-------------------------------------------
    set f $fROI.fThreshold.fLabel

    DevAddLabel $f.l "DTMRI Threshold Settings"
    pack $f.l -side top -padx $Gui(pad) -pady $Gui(pad)

    #-------------------------------------------
    # ROI->Threshold->Mode frame
    #-------------------------------------------
    set f $fROI.fThreshold.fMode

    DevAddLabel $f.l "Value:"
    pack $f.l -side left -padx $Gui(pad) -pady 0

    foreach vis $DTMRI(mode,thresholdList) tip $DTMRI(mode,thresholdList,tooltips) {
        eval {radiobutton $f.rMode$vis \
          -text "$vis" -value "$vis" \
          -variable DTMRI(mode,threshold) \
          -command {DTMRIUpdate} \
          -indicatoron 0} $Gui(WCA)
        pack $f.rMode$vis -side left -padx 0 -pady 0
        TooltipAdd  $f.rMode$vis $tip
    }    

    #-------------------------------------------
    # ROI->Threshold->Slider frame
    #-------------------------------------------
    foreach slider "Lower Upper" text "Lo Hi" {

        set f $fROI.fThreshold.fSlider

        frame $f.f$slider -bg $Gui(activeWorkspace)
        pack $f.f$slider -side top -padx $Gui(pad) -pady $Gui(pad)
        set f $f.f$slider

        eval {label $f.l$slider -text "$text:"} $Gui(WLA)
        eval {entry $f.e$slider -width 6 \
          -textvariable DTMRI(thresh,threshold,[Uncap $slider])} \
        $Gui(WEA)
        bind $f.e$slider <Return>   "DTMRIUpdateThreshold"
        #bind $f.e$slider <FocusOut> "EdThresholdUpdate; RenderActive;"
        eval {scale $f.s$slider -from $DTMRI(thresh,threshold,rangeLow) \
          -to $DTMRI(thresh,threshold,rangeHigh) \
          -length 130 \
          -variable DTMRI(thresh,threshold,[Uncap $slider]) \
          -resolution 0.1 \
          -command {DTMRIUpdateThreshold}} \
        $Gui(WSA) {-sliderlength 15}
        #grid $f.l$slider $f.e$slider -padx 2 -pady 2 -sticky w
        #grid $f.l$slider -sticky e
        #grid $f.s$slider -columnspan 2 -pady 2 
        pack $f.l$slider $f.e$slider $f.s$slider -side left  -padx $Gui(pad)
        set DTMRI(gui,slider,$slider) $f.s$slider
    }


    #-------------------------------------------
    # ROI->Mask frame
    #-------------------------------------------
    set f $fROI.fMask

    foreach frame "Label Mode Volume ChooseLabel" {
        frame $f.f$frame -bg $Gui(activeWorkspace)
        pack $f.f$frame -side top -padx $Gui(pad) -pady $Gui(pad) -fill both
    }

    #-------------------------------------------
    # ROI->Mask->Label frame
    #-------------------------------------------
    set f $fROI.fMask.fLabel

    DevAddLabel $f.l "DTMRI Mask Settings"
    pack $f.l -side top -padx $Gui(pad) -pady $Gui(pad)

    #-------------------------------------------
    # ROI->Mask->Mode frame
    #-------------------------------------------
    set f $fROI.fMask.fMode

    DevAddLabel $f.l "Mask:"
    pack $f.l -side left -padx $Gui(pad) -pady 0

    foreach vis $DTMRI(mode,maskList) tip $DTMRI(mode,maskList,tooltips) {
        eval {radiobutton $f.rMode$vis \
          -text "$vis" -value "$vis" \
          -variable DTMRI(mode,mask) \
          -command {DTMRIUpdate} \
          -indicatoron 0} $Gui(WCA)
        pack $f.rMode$vis -side left -padx 0 -pady 0
        TooltipAdd  $f.rMode$vis $tip
    }    

    #-------------------------------------------
    # ROI->Mask->Volume frame
    #-------------------------------------------
    set f $fROI.fMask.fVolume

    # menu to select a volume: will set Volume(activeID)
    set name MaskLabelmap
    DevAddSelectButton  Volume $f $name "Mask Labelmap:" Grid \
        "Select a labelmap volume to use as a mask.\nDTMRIs will be displayed only where the label matches the label you select below." \
        13
    
    # Append these menus and buttons to lists 
    # that get refreshed during UpdateMRML
    lappend Volume(mbActiveList) $f.mb$name
    lappend Volume(mActiveList) $f.mb$name.m

    #-------------------------------------------
    # ROI->Mask->ChooseLabel frame
    #-------------------------------------------
    set f $fROI.fMask.fChooseLabel

    # mask label
    eval {button $f.bOutput -text "Label:" \
          -command "ShowLabels DTMRIUpdateMaskLabel"} $Gui(WBA)
    eval {entry $f.eOutput -width 6 \
          -textvariable Label(label)} $Gui(WEA)
    bind $f.eOutput <Return>   "DTMRIUpdateMaskLabel"
    bind $f.eOutput <FocusOut> "DTMRIUpdateMaskLabel"
    eval {entry $f.eName -width 14 \
          -textvariable Label(name)} $Gui(WEA) \
            {-bg $Gui(activeWorkspace) -state disabled}
    grid $f.bOutput $f.eOutput $f.eName -padx 2 -pady $Gui(pad)
    grid $f.eOutput $f.eName -sticky w
    
    lappend Label(colorWidgetList) $f.eName

    TooltipAdd  $f.bOutput $DTMRI(mode,maskLabel,tooltip)
    TooltipAdd  $f.eOutput $DTMRI(mode,maskLabel,tooltip)
    TooltipAdd  $f.eName $DTMRI(mode,maskLabel,tooltip)


#######################################################################################
#######################################################################################
#######################################################################################


    #-------------------------------------------
    # Scalars frame
    #-------------------------------------------
    set fScalars $Module(DTMRI,fScalars)
    set f $fScalars
    
    frame $f.fActive    -bg $Gui(backdrop) -relief sunken -bd 2
    pack $f.fActive -side top -padx $Gui(pad) -pady $Gui(pad) -fill x

    foreach frame "Top" {
        frame $f.f$frame -bg $Gui(activeWorkspace)
        pack $f.f$frame -side top -padx $Gui(pad) -pady $Gui(pad) -fill both
        $f.f$frame config -relief groove -bd 3
    }

    #-------------------------------------------
    # Scalars->Active frame
    #-------------------------------------------
    set f $fScalars.fActive

    # menu to select active DTMRI
    DevAddSelectButton  Tensor $f Active "Active DTMRI:" Pack \
    "Active DTMRI" 20 BLA 
    
    # Append these menus and buttons to lists 
    # that get refreshed during UpdateMRML
    lappend Tensor(mbActiveList) $f.mbActive
    lappend Tensor(mActiveList) $f.mbActive.m
    
    #-------------------------------------------
    # Scalars->Top frame
    #-------------------------------------------
    set f $fScalars.fTop
    
    foreach frame "ChooseOutput UseROI ScaleFactor Apply" {
        frame $f.f$frame -bg $Gui(activeWorkspace)
        pack $f.f$frame -side top -padx $Gui(pad) -pady $Gui(pad) -fill x
    }

    #-------------------------------------------
    # Scalars->Top->ChooseOutput frame
    #-------------------------------------------
    set f $fScalars.fTop.fChooseOutput

    eval {label $f.lMath -text "Create Volume: "} $Gui(WLA)
    eval {menubutton $f.mbMath -text $DTMRI(scalars,operation) \
          -relief raised -bd 2 -width 20 \
          -menu $f.mbMath.m} $Gui(WMBA)

    eval {menu $f.mbMath.m} $Gui(WMA)
    pack $f.lMath $f.mbMath -side left -pady $Gui(pad) -padx $Gui(pad)
    # Add menu items
    foreach math $DTMRI(scalars,operationList) {
        $f.mbMath.m add command -label $math \
        -command "DTMRISetOperation $math"
    }
    # save menubutton for config
    set DTMRI(gui,mbMath) $f.mbMath
    # Add a tooltip
    TooltipAdd $f.mbMath $DTMRI(scalars,operationList,tooltip)

    #-------------------------------------------
    # Scalars->Top->UseROI frame
    #-------------------------------------------
    set f $fScalars.fTop.fUseROI

    DevAddLabel $f.l "ROI:"
    pack $f.l -side left -padx $Gui(pad) -pady 0

    foreach vis $DTMRI(scalars,ROIList) tip $DTMRI(scalars,ROIList,tooltips) {
        eval {radiobutton $f.rMode$vis \
          -text "$vis" -value "$vis" \
          -variable DTMRI(scalars,ROI) \
          -command DTMRIUpdateMathParams \
          -indicatoron 0} $Gui(WCA)
        pack $f.rMode$vis -side left -padx 0 -pady 0
        TooltipAdd  $f.rMode$vis $tip
    }    

    #-------------------------------------------
    # Scalars->Top->ScaleFactor frame
    #-------------------------------------------
    set f $fScalars.fTop.fScaleFactor
    DevAddLabel $f.l "Scale Factor:"
    eval {entry $f.e -width 14 \
          -textvariable DTMRI(scalars,scaleFactor)} $Gui(WEA)
    TooltipAdd $f.e $DTMRI(scalars,scaleFactor,tooltip) 
    pack $f.l $f.e -side left -padx $Gui(pad) -pady 0

    #-------------------------------------------
    # Scalars->Top->Apply frame
    #-------------------------------------------
    set f $fScalars.fTop.fApply

    DevAddButton $f.bApply "Apply" "DTMRIDoMath"    
    pack $f.bApply -side top -padx 0 -pady 0

#######################################################################################
#######################################################################################
#######################################################################################

    #-------------------------------------------
    # Convert frame
    #-------------------------------------------
    set fConvert $Module(DTMRI,fConvert)
    set f $fConvert
    
    foreach frame "Convert ShowPattern Pattern" {
        frame $f.f$frame -bg $Gui(activeWorkspace)
        pack $f.f$frame -side top -padx $Gui(pad) -pady $Gui(pad) -fill x -anchor w
    }

    pack forget $f.fPattern
    $f.fConvert configure  -relief groove -bd 3 


    #-------------------------------------------
    # Convert->Convert frame
    #-------------------------------------------
    set f $fConvert.fConvert

    foreach frame "Title Select Pattern Apply" {
        frame $f.f$frame -bg $Gui(activeWorkspace)
        $f.fTitle configure -bg $Gui(backdrop)
        pack $f.f$frame -side top -padx $Gui(pad) -pady $Gui(pad) -fill x
    }

    #-------------------------------------------
    # Convert->Convert->Title frame
    #-------------------------------------------
    set f $fConvert.fConvert.fTitle
     
    DevAddLabel $f.lWellcome "Convert Tensors"
    $f.lWellcome configure -fg White -font {helvetica 10 bold}  -bg $Gui(backdrop) -bd 0 -relief groove
    pack $f.lWellcome -side top -padx $Gui(pad) -pady $Gui(pad)
   
    DevAddLabel $f.lOption "This tab converts gradient data\n to diffusion tensor"
    $f.lOption configure -fg White -font {helvetica 9 normal}  -bg $Gui(backdrop) -bd 0
    pack $f.lOption -side top -padx $Gui(pad) -pady 2
    

    #-------------------------------------------
    # Convert->Convert->Select frame
    #-------------------------------------------
    set f $fConvert.fConvert.fSelect
    # Lauren test
    # menu to select a volume: will set Volume(activeID)
    DevAddSelectButton  Volume $f Active "Input Volume:" Pack \
            "Input Volume to create DTMRIs from." 13 BLA
    

    # Append these menus and buttons to lists 
    # that get refreshed during UpdateMRML
    lappend Volume(mbActiveList) $f.mbActive
    lappend Volume(mActiveList) $f.mbActive.m


    #-------------------------------------------
    # Convert->Convert->Pattern frame
    #-------------------------------------------
#nowworking
    set f $fConvert.fConvert.fPattern

    DevAddLabel $f.lLabel "Protocol:"
    $f.lLabel configure -bg $Gui(backdrop) -fg white
    eval {menubutton $f.mbPattern -text "None" -relief raised -bd 2 -menu $f.mbPattern.menu -width 15} $Gui(WMBA)
    eval {menu $f.mbPattern.menu}  $Gui(WMA)
    button $f.bProp -text Prop. -width 5 -font {helvetica 8} -bg $Gui(normalButton) -fg $Gui(textDark)  -activebackground $Gui(activeButton) -activeforeground $Gui(textDark)  -bd $Gui(borderWidth) -padx 0 -pady 0 -relief raised -command {
        catch {DevInfoWindow $DTMRI($DTMRI(selectedpattern),tip)}
        catch {puts $DTMRI($DTMRI(selectedpattern),tip)}
        #DTMRIViewProps
    }

    pack $f.lLabel $f.bProp -side left -padx $Gui(pad) -pady $Gui(pad)
    DTMRILoadPattern
    TooltipAdd $f.lLabel "Choose a protocol to convert tensors.\n If desired does not exist, create one in the frame below."
    

#    #-------------------------------------------
#    # Convert->Convert->Apply frame
#    #-------------------------------------------
    set f $fConvert.fConvert.fApply
    DevAddButton $f.bTest "Convert Volume" ConvertVolumeToTensors 20
    pack $f.bTest -side top -padx 0 -pady $Gui(pad) -fill x -padx $Gui(pad)


    #-------------------------------------------
    # Convert->ShowPattern frame
    #-------------------------------------------
    set f $fConvert.fShowPattern
    
    DevAddLabel $f.lLabel "Create a new protocol if your data\n does not fit the predefined ones"

    button $f.bShow -text "Create New Protocol" -bg $Gui(backdrop) -fg white -font {helvetica 9 bold} -command {
        ShowPatternFrame 
        after 250 DTMRIDisplayScrollBar DTMRI Convert}
    TooltipAdd $f.bShow "Press this button to enter Create-Protocol Frame"
    pack $f.lLabel $f.bShow -side top -pady 2 -fill x




    #-------------------------------------------
    # Convert->Pattern->Gradients Title frame
    #-------------------------------------------

#    set f $fConvert.fPattern
#    frame $f.fTitle -bg $Gui(backdrop)
#    pack $f.fTitle -side top -padx $Gui(pad) -pady $Gui(pad) -fill x

#    set f $fConvert.fPattern.fTitle
#    set f $Page.fTitle
   
#    DevAddLabel $f.lWellcome "Create New Protocol"
#    $f.lWellcome configure -fg White -font {helvetica 10 bold}  -bg $Gui(backdrop) -bd 0 -relief groove
#    pack $f.lWellcome -side top -padx $Gui(pad) -pady 0
   


    #-------------------------------------------
    # Convert->Pattern frame (create tabs)
    #-------------------------------------------
    set f $fConvert.fPattern
    DevAddLabel $f.lIni "Gradient Ordering scheme:"
    pack $f.lIni -side top -pady 2

    Notebook:create $f.fNotebook \
                    -pages {{Slice Interleav.} {Volume Interleav.}} \
                    -pad 2 \
                    -bg $Gui(activeWorkspace) \
                    -height 325 \
                    -width 240
    pack $f.fNotebook -fill both -expand 1

    set f $fConvert.fPattern.fNotebook

    set FrameCont [Notebook:frame $f {Slice Interleav.}] 
    set FrameInter [Notebook:frame $f {Volume Interleav.}]

    foreach Page "$FrameCont $FrameInter" {   

        #-------------------------------------------
        # Convert->Pattern frame
        #-------------------------------------------
    #    set f $fConvert.fPattern
        set f $Page

        foreach frame "Name Disposal GradientNum GradientImages NoGradientImages Gradients Parameter Create" {
            frame $f.f$frame -bg $Gui(activeWorkspace)
            pack $f.f$frame -side top -padx $Gui(pad) -pady $Gui(pad) -fill x
        }

        $f configure  -relief sunken -bd 3 

        #-------------------------------------------
        # Convert->Pattern->Gradients Title frame
        #-------------------------------------------

    #    set f $fConvert.fPattern
    #    frame $f.fTitle -bg $Gui(backdrop)
    #    pack $f.fTitle -side top -padx $Gui(pad) -pady $Gui(pad) -fill x

        set f $fConvert.fPattern.fTitle
    #    set f $Page.fTitle
       
    #    DevAddLabel $f.lWellcome "Create New Protocol"
    #    $f.lWellcome configure -fg White -font {helvetica 10 bold}  -bg $Gui(backdrop) -bd 0 -relief groove
    #    pack $f.lWellcome -side top -padx $Gui(pad) -pady $Gui(pad)
       

        #-------------------------------------------
        # Convert->Pattern->Gradients Name frame
        #-------------------------------------------

    #    set f $fConvert.fPattern.fName
        set f $Page.fName

        $f configure -relief raised -padx 2 -pady 2
        DevAddLabel $f.lTitle "Protocol Name:"
    #   $f.lTitle configure -relief sunken -background gray -bd 2
        DevAddEntry DTMRI name,name $f.eName 15
        pack $f.lTitle $f.eName -side left -padx $Gui(pad) -pady 4 -fill x


     
        #-------------------------------------------
        # Convert->Pattern->Gradients Disposal frame
        #-------------------------------------------

    #    set f $fConvert.fPattern.fDisposal
        set f $Page.fDisposal

        $f configure -relief raised -padx 2 -pady 2
        DevAddLabel $f.lTitle "Gradients/Baselines disposal in Volume:"
        $f.lTitle configure -relief sunken -background gray -bd 2
        pack $f.lTitle -side top -padx $Gui(pad) -pady 4 -fill x
     
        #-------------------------------------------
        # Convert->Pattern->GradientNum frame
        #-------------------------------------------
    #    set f $fConvert.fPattern.fGradientNum
        set f $Page.fGradientNum
        
        DevAddLabel $f.l "Number of Gradient Directions:"
        eval {entry $f.eEntry \
            -textvariable DTMRI(name,numberOfGradients) \
            -width 5} $Gui(WEA)
        pack $f.l $f.eEntry -side left -padx $Gui(pad) -pady 0 -fill x

        #-------------------------------------------
        # Convert->Pattern->GradientImages frame
        #-------------------------------------------
    #    set f $fConvert.fPattern.fGradientImages
        set f $Page.fGradientImages

        DevAddLabel $f.l "Gradient:"
        eval {entry $f.eEntry1 \
              -textvariable DTMRI(name,firstGradientImage) \
              -width 5} $Gui(WEA)
        eval {entry $f.eEntry2 \
              -textvariable DTMRI(name,lastGradientImage) \
              -width 5} $Gui(WEA)
        pack $f.l $f.eEntry1 $f.eEntry2 -side left -padx $Gui(pad) -pady 0 -fill x
        TooltipAdd $f.eEntry1 \
            "First gradient (diffusion-weighted)\nimage number at first slice location"
        TooltipAdd $f.eEntry2 \
            "Last gradient (diffusion-weighted)\niimage number at first slice location"

        #-------------------------------------------
        # Convert->Pattern->NoGradientImages frame
        #-------------------------------------------
    #    set f $fConvert.fPattern.fNoGradientImages
        set f $Page.fNoGradientImages


        DevAddLabel $f.l "Baseline:"
        eval {entry $f.eEntry1 \
              -textvariable DTMRI(name,firstNoGradientImage) \
              -width 5} $Gui(WEA)
        eval {entry $f.eEntry2 \
              -textvariable DTMRI(name,lastNoGradientImage) \
              -width 5} $Gui(WEA)
        pack $f.l $f.eEntry1 $f.eEntry2 -side left -padx $Gui(pad) -pady 0 -fill x
        TooltipAdd $f.eEntry1 \
            "First NO gradient (not diffusion-weighted)\nimage number at first slice location"
        TooltipAdd $f.eEntry2 \
            "Last NO gradient (not diffusion-weighted)\n image number at first slice location"

        #-------------------------------------------
        # Convert->Pattern->Gradients frame
        #-------------------------------------------
    #    set f $fConvert.fPattern.fGradients
        set f $Page.fGradients


        DevAddLabel $f.lLabel "Directions:"
        frame $f.fEntry -bg $Gui(activeWorkspace)
        eval {entry $f.fEntry.eEntry \
            -textvariable DTMRI(name,gradients) \
            -width 25 -xscrollcommand [list $f.fEntry.sx set]} $Gui(WEA)
            scrollbar $f.fEntry.sx -orient horizontal -command [list $f.fEntry.eEntry xview] -bg $Gui(normalButton) -width 10 -troughcolor $Gui(normalButton) 
        pack $f.fEntry.eEntry $f.fEntry.sx -side top -padx 0 -pady 0 -fill x
        pack $f.lLabel $f.fEntry -side left -padx $Gui(pad) -pady $Gui(pad) -fill x -anchor n
        #pack $f.sx -side top -padx $Gui(pad) -pady 0 -fill x
        TooltipAdd $f.fEntry.eEntry "List of diffusion gradient directions"

        #-------------------------------------------
        # Convert->Pattern->Parameters frame
        #-------------------------------------------




    # This frame is supposed to hold the entries for needed parameters in tensors conversion.

    #    set f $fConvert.fPattern.fParameter
        set f $Page.fParameter

        $f configure -relief raised -padx 2 -pady 2
        DevAddLabel $f.lTitle "Conversion Parameters:"
        $f.lTitle configure -relief sunken -background gray -bd 2
        pack $f.lTitle -side top -padx $Gui(pad) -pady 4 -fill x
        DevAddLabel $f.lLeBihan "LeBihan factor (b):"
        eval {entry $f.eEntrylebihan \
            -textvariable DTMRI(name,lebihan)  \
            -width 4} $Gui(WEA)
        eval {scale $f.slebihan -from 100 -to 5000 -variable DTMRI(name,lebihan) -orient vertical -resolution 10 -width 10} $Gui(WSA)
        pack $f.lLeBihan $f.eEntrylebihan $f.slebihan  -side left -padx $Gui(pad) -pady 0 -fill x -padx $Gui(pad)
        TooltipAdd $f.eEntrylebihan "Diffusion weighting factor, introduced and defined by LeBihan et al.(1986)"
      
    }

    #-------------------------------------------
    # Convert->Pattern->FrameCont-->Create frame
    #-------------------------------------------

    set f $FrameCont.fCreate
    DevAddButton $f.bCreate "Create New Protocol" DTMRICreatePatternSlice 8
    pack $f.bCreate -side top -pady $Gui(pad) -fill x
    TooltipAdd $f.bCreate "Click this button to create a new protocol after filling in parameters entries"
    

    #-------------------------------------------
    # Convert->Pattern->FrameInter-->Create frame
    #-------------------------------------------

    set f $FrameInter.fCreate
    DevAddButton $f.bCreate "Create New Protocol" DTMRICreatePatternVolume 8
    pack $f.bCreate -side top -pady $Gui(pad) -fill x
    TooltipAdd $f.bCreate "Click this button to create a new protocol after filling in parameters entries"
    

     #-------------------------------------------
     # Regist frame
     #-------------------------------------------

     DTMRIBuildRegistFrame


######################################################################################
######################################################################################
######################################################################################

    #-------------------------------------------
    # Advanced frame
    #-------------------------------------------
    set fAdvanced $Module(DTMRI,fAdvanced)
    set f $fAdvanced
    
    foreach frame "Top Middle Bottom" {
        frame $f.f$frame -bg $Gui(activeWorkspace)
        pack $f.f$frame -side top -padx 0 -pady $Gui(pad) -fill x
    }

    #-------------------------------------------
    # Advanced->Top frame
    #-------------------------------------------
    set f $fAdvanced.fTop
    DevAddLabel $f.l "VTK objects in the pipeline"
    pack $f.l -side top -padx $Gui(pad) -pady $Gui(pad)

    #-------------------------------------------
    # Advanced->Middle frame
    #-------------------------------------------
    set f $fAdvanced.fMiddle
    set fScrolled [DTMRIBuildScrolledGUI $f]
    set DTMRI(scrolledGui,advanced) $fScrolled

    # loop through all the vtk objects and build GUIs
    #------------------------------------              
    foreach o $DTMRI(vtkObjectList) {

        set f $fScrolled

        # if the object has properties
        #-------------------------------------------
        if {$DTMRI(vtkPropertyList,$o) != ""} {
            
            # make a new frame for this vtk object
            #-------------------------------------------
            frame $f.f$o -bg $Gui(activeWorkspace)
            $f.f$o configure  -relief groove -bd 3 
            pack $f.f$o -side top -padx $Gui(pad) -pady 2 -fill x
            
            # object name becomes the label for the frame
            #-------------------------------------------
            # Lauren we need an object description
            # and also basic or advanced attrib
            DevAddLabel $f.f$o.l$o [Cap $o]
            pack $f.f$o.l$o -side top \
                -padx 0 -pady 0
        }

        # loop through all the parameters for this object
        # and build appropriate user entry stuff for each
        #------------------------------------
        foreach p $DTMRI(vtkPropertyList,$o) {

            set f $fScrolled.f$o

            # name of entire tcl variable
            set variableName DTMRI(vtk,$o,$p)
            # its value is:
            set value $DTMRI(vtk,$o,$p)
            # description of the parameter
            set desc $DTMRI(vtk,$o,$p,description)
            # datatype of the parameter
            set type $DTMRI(vtk,$o,$p,type)

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
    # end foreach vtk object in DTMRIs object list

    # Here's a button with text "Apply" that calls "AdvancedApply"
    DevAddButton $fAdvanced.fMiddle.bApply Apply DTMRIAdvancedApply
    pack $fAdvanced.fMiddle.bApply -side top -padx $Gui(pad) -pady $Gui(pad)


####################################################################################
####################################################################################
####################################################################################


    #-------------------------------------------
    # Save frame
    #-------------------------------------------
    set fSave $Module(DTMRI,fSave)
    set f $fSave
    
    frame $f.fActive    -bg $Gui(backdrop) -relief sunken -bd 2
    pack $f.fActive -side top -padx $Gui(pad) -pady $Gui(pad) -fill x
    
    foreach frame "Top Middle Bottom" {
        frame $f.f$frame -bg $Gui(activeWorkspace)
        pack $f.f$frame -side top -padx 0 -pady $Gui(pad) -fill x
    }
    $f.fTop configure  -relief groove -bd 3 
    $f.fMiddle configure  -relief groove -bd 3 

    #-------------------------------------------
    # Scalars->Active frame
    #-------------------------------------------
    set f $fSave.fActive

    # menu to select active DTMRI
    DevAddSelectButton  Tensor $f Active "Active DTMRI:" Pack \
    "Active DTMRI" 20 BLA 
    
    # Append these menus and buttons to lists 
    # that get refreshed during UpdateMRML
    lappend Tensor(mbActiveList) $f.mbActive
    lappend Tensor(mActiveList) $f.mbActive.m

    #-------------------------------------------
    # Save->Top frame
    #-------------------------------------------
    set f $fSave.fTop

    DevAddButton $f.bSave "Save Tensors" {DTMRIWriteStructuredPoints $DTMRI(devel,fileName)}
    pack $f.bSave -side top -padx $Gui(pad) -pady $Gui(pad)
    TooltipAdd $f.bSave "Save tensor data (Active DTMRI) to vtk file format."

    #-------------------------------------------
    # Save->Middle frame
    #-------------------------------------------
    set f $fSave.fMiddle
    frame $f.fButton  -bg $Gui(activeWorkspace)
    pack $f.fButton -side top -padx $Gui(pad) -pady $Gui(pad)

    set f $fSave.fMiddle.fButton
    DevAddButton $f.bApply "Save tract points" \
        {DTMRISaveStreamlinesAsIJKPoints}
    TooltipAdd $f.bApply "Save text file(s) with the tract paths.\n This does not save vtk models."

    pack $f.bApply -side top -padx $Gui(pad) -pady $Gui(pad) 
}


#-------------------------------------------------------------------------------
# .PROC DTMRIRaiseMoreOptionsFrame
# 
# .ARGS
# string mode identifies the frame to raise
# .END
#-------------------------------------------------------------------------------
proc DTMRIRaiseMoreOptionsFrame {mode} {
    global DTMRI

    raise $DTMRI(frame,$mode)
    focus $DTMRI(frame,$mode)

    set DTMRI(mode,visualizationTypeGui) $mode
    # config menubutton
    $DTMRI(gui,mbVisMode)    config -text $mode
}

#-------------------------------------------------------------------------------
# .PROC DTMRIBuildScrolledGUI
# 
# .ARGS
# string f path to frame
# .END
#-------------------------------------------------------------------------------
proc DTMRIBuildScrolledGUI {f} {
    global Gui DTMRI

    # window paths
    #-------------------------------------------
    set canvas $f.cGrid
    set s $f.sGrid
    
    # create canvas and scrollbar
    #-------------------------------------------
    canvas $canvas -yscrollcommand "$s set" -bg $Gui(activeWorkspace)
    eval "scrollbar $s -command \"DTMRICheckScrollLimits $canvas yview\"\
            $Gui(WSBA)"
    pack $s -side right -fill y
    pack $canvas -side top -fill both -pady $Gui(pad) -expand true
    
    set f $canvas.f
    #frame $f -bd 0 -bg $Gui(activeWorkspace)
    frame $f -bd 0
    $f configure  -relief groove -bd 3 
    
    # put the frame inside the canvas (so it can scroll)
    #-------------------------------------------
    $canvas create window 0 0 -anchor nw -window $f
    
    # y spacing important for calculation of frame height for scrolling
    set pady 2
    
    # save name of canvas to configure later
    set DTMRI(scrolledGUI,$f,canvas) $canvas

    # return path to the frame for filling
    return $f
}


#-------------------------------------------------------------------------------
# .PROC DTMRICheckScrollLimits
# This procedure allows scrolling only if the entire frame is not visible
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRICheckScrollLimits {args} {

    set canvas [lindex $args 0]
    set view   [lindex $args 1]
    set fracs [$canvas $view]

    if {double([lindex $fracs 0]) == 0.0 && \
            double([lindex $fracs 1]) == 1.0} {
        return
    }
    eval $args
}

#-------------------------------------------------------------------------------
# .PROC DTMRISizeScrolledGUI
# 
# .ARGS
# string f path to frame
# .END
#-------------------------------------------------------------------------------
proc DTMRISizeScrolledGUI {f} {
    global DTMRI

    # see how tall our frame is these days
    set height [winfo reqheight  $f]    
    set canvas $DTMRI(scrolledGUI,$f,canvas)

    # tell the canvas to scroll so we can see the whole frame
    $canvas config -scrollregion "0 0 1 $height"
}

#-------------------------------------------------------------------------------
# .PROC DTMRISetPropertyType
# raise a panel in the GUI
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRISetPropertyType {} {
    global Module DTMRI

    #Lauren need properties subframes for this to work
    #raise $Volume(f$Volume(propertyType))
    #focus $Volume(f$Volume(propertyType))

    # Lauren temporarily use this
    raise $Module(DTMRI,f$DTMRI(propertyType))
}

################################################################
#  Procedures called by the GUI: Apply, Cancel, etc.
################################################################


#-------------------------------------------------------------------------------
# .PROC RunLSDIrecon
# Convert volume data from scanner to a module readable data 
# so that DTMRI can convert tensors
#  active MRML node (this is NEW or an existing node). 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc RunLSDIrecon {} {
    global DTMRI Volume  Mrml Module PACKAGE_DIR_VTKDTMRI
    
    set v $Volume(activeID)
    if {$v == "" || $v == $Volume(idNone)} {
        puts "Can't create new data from NONE Volume. Load a Volume Data and Select it."
        DevInfoWindow "Can't create new data from NONE Volume.\n Load a Volume Data and Select it."
        return
    }

    #
    # Copy LSDIrecon.par in the selected volume data directory  
    #

    #puts $Mrml(dir)/Modules/vtkDTMRI/LSDIrecon_par
    #puts $Volume(DefaultDir)

    puts "Copying LSDIrecon_par to Volume Data directory..."
    set a [catch {file copy $PACKAGE_DIR_VTKDTMRI/../../../LSDIrecon_par $Volume(DefaultDir)}]
    if {$a} {
       DevInfoWindow "You don't have permission \n to write in the selected directory."
       return
    }

    puts "Changing to Volume Data directory..."
    cd $Volume(DefaultDir)

    #
    # Running LSDI script 
    #

    if {[file exists $DTMRI(LSDIpydir)] == 1 &&
        [file executable $DTMRI(pythonintdir)] == 1} {
        puts "Creating new volume data (D.###)..."

        catch {exec $DTMRI(pythonintdir) $DTMRI(LSDIpydir)} convertingerror
    } else {
        DevInfoWindow "Error: Cannot find $DTMRI(LSDIpydir)\nor execute $DTMRI(pythonintdir)\nUnable to create new volume data"
        return
    }
}


#-------------------------------------------------------------------------------
# .PROC ShowPatternFrame
#  Show and hide Create-Pattern Frame from the Convert Tab.  
# .ARGS
# .END
#-------------------------------------------------------------------------------
    proc ShowPatternFrame {} {
    
    global DTMRI Volume Mrml Module Gui

    set fConvert $Module(DTMRI,fConvert)
    set f $fConvert

    if { $DTMRI(convert,show) == 1} {
        pack forget $f.fPattern
        set DTMRI(convert,show) 0
        return
    }

    if { $DTMRI(convert,show) == 0 } {
        pack $f.fPattern -padx $Gui(pad) -pady $Gui(pad)
    
        set DTMRI(convert,show) 1
        return
    }

}


#-------------------------------------------------------------------------------
# .PROC DTMRIDisplayScrollBar
#  If the size of a workframe changes, display the scrollbar if necessary.
#  
#-------------------------------------------------------------------------------

   proc DTMRIDisplayScrollBar {module tab} {
    global Module

    set reqHeight [winfo reqheight $Module($module,f$tab)]
    # puts $reqHeight 
    # puts $Module(.tMain.fControls,scrolledHeight)
    MainSetScrollbarHeight $reqHeight
    if {$reqHeight > $Module(.tMain.fControls,scrolledHeight)} { 
        MainSetScrollbarVisibility 1
    } else {
        MainSetScrollbarVisibility 0
    }

}


#-------------------------------------------------------------------------------
# .PROC DTMRICreatePatternSlice
# Write new patterns defined by user in $env(HOME)/PatternData and update patterns selectbutton
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRICreatePatternSlice {} {
        global Module Gui Volume DTMRI Mrml env

        set DTMRI(patternpar) ""

        # check if name field is filled in
        if {$DTMRI(name,name) != ""} {

            # check if all fields are filled in
            foreach par {numberOfGradients firstGradientImage lastGradientImage firstNoGradientImage lastNoGradientImage lebihan gradients} {
       
                if {$DTMRI(name,$par) != ""} {

                    # put information of the entries of create pattern frame in a list in order to write this information in a file
                    lappend DTMRI(patternpar) $DTMRI(name,$par)

                } else {

                    puts "You must fill in $par entry"
                    break

                }

            }

            lappend DTMRI(patternpar) "SLICE"

        } else {

            puts "You must fill in name entry"
        return

        }



        if {[file exists $env(HOME)/PatternsData/] != 1} then {

            file mkdir $env(HOME)/PatternsData/

        }

        if {$DTMRI(name,name) != ""} {
    
            if {[file exists $env(HOME)/PatternsData/$DTMRI(name,name)] != 0} then {

                puts "You are modifying an existing file"

            }
    
            set filelist [open $env(HOME)/PatternsData/$DTMRI(name,name) {RDWR CREAT}]
            puts  $filelist "# This line is the label that tells the code that this is a pattern file"
            puts  $filelist "vtkDTMRIprotocol"
            puts  $filelist "\n "
            puts  $filelist "# Enter a new pattern in the following order\n"
            #seek $filelist -0 end
            puts  $filelist "# Name NoOfGradients FirstGradient LastGradient FirstBaseLine LastBaseLine Lebihan GradientDirections\n"
            #seek $filelist -0 end
            puts  $filelist "\n "
            #seek $filelist -0 end
            puts $filelist $DTMRI(patternpar)    
            close $filelist
        
            DTMRILoadPattern

        }
 
}


#-------------------------------------------------------------------------------
# .PROC DTMRICreatePatternVolume
# Write new patterns defined by user in $env(HOME)/PatternData and update patterns selectbutton
#  
#-------------------------------------------------------------------------------
proc DTMRICreatePatternVolume {} {
      global Module Gui Volume DTMRI Mrml env

      set DTMRI(patternpar) ""

      # check if name field is filled in
      if {$DTMRI(name,name) != ""} {

        # check if all fields are filled in
        foreach par {numberOfGradients firstGradientImage lastGradientImage firstNoGradientImage lastNoGradientImage lebihan gradients} {
       
          if {$DTMRI(name,$par) != ""} {

              # put information of the entries of create pattern frame in a list in order to write this information in a file
              lappend DTMRI(patternpar) $DTMRI(name,$par)

          } else {

              puts "You must fill in $par entry"
              break

          }

        }

        lappend DTMRI(patternpar) "VOLUME"

      } else {

        puts "You must fill in name entry"
        return

      }




      if {[file exists $env(HOME)/PatternsData/] != 1} then {

          file mkdir $env(HOME)/PatternsData/

      }
    
      if {$DTMRI(name,name) != ""} {

          if {[file exists $env(HOME)/PatternsData/$DTMRI(name,name)] != 0} then {

              puts "You are modifying an existing file"

          }

          set filelist [open $env(HOME)/PatternsData/$DTMRI(name,name) {RDWR CREAT}]
          puts  $filelist "# This line is the label that tells the code that this is a pattern file"
          puts  $filelist "vtkDTMRIprotocol"
          puts  $filelist "\n "
          puts  $filelist "# Enter a new pattern in the following order\n"
          #seek $filelist -0 end
          puts  $filelist "# Name NoOfGradients FirstGradient LastGradient FirstBaseLine LastBaseLine Lebihan GradientDirections\n"
          #seek $filelist -0 end
          puts  $filelist "\n "
          #seek $filelist -0 end
          puts $filelist $DTMRI(patternpar)    
          close $filelist

          DTMRILoadPattern

      }
} 




#-------------------------------------------------------------------------------
# .PROC DTMRILoadPattern
# Looks for files with information of patterns and adds this information in the menubutton of the create pattern frame
#  
#-------------------------------------------------------------------------------
#nowworking2

proc DTMRILoadPattern {} {
    global Module Gui Volume DTMRI Mrml env PACKAGE_DIR_VTKDTMRI

   # if DTMRI(patternames) already exists, initialize it and its information
   
   if {[info exists DTMRI(patternnames)]} {
        foreach a $DTMRI(patternnames) {
               set DTMRI($a,parameters) ""
        }
        set DTMRI(patternnames) ""
   } else {set DTMRI(patternnames) ""}
   if {[info exists DTMRI(patternnamesdef)]} {
        foreach a $DTMRI(patternnamesdef) {
            set DTMRI($a,parameters) ""
        }
        set DTMRI(patternnamesdef) ""
   }
 
   if {[info exists DTMRI(localpatternnames)]} {
        foreach a $DTMRI(localpatternnames) {
           set DTMRI($a,parameters) ""
        }
        set DTMRI(localpatternnames) ""
    }
   
    # look for a file containing pattern information, if it exists, put this information in variable lists

    if { [file exists $PACKAGE_DIR_VTKDTMRI/../../../data/] != 0 } then {

        #set DTMRI(patternnamesdef) [exec ls $PACKAGE_DIR_VTKDTMRI/../../../data/]
      set DTMRI(patternnamesdef) [glob -tail -directory $PACKAGE_DIR_VTKDTMRI/../../../data/ *]
      # check if the file contains pattern information
      foreach pattern $DTMRI(patternnamesdef) {
        set DTMRI(ispatternfile) 0
       
            if { [file isfile $PACKAGE_DIR_VTKDTMRI/../../../data/$pattern] != 0 } {

                catch [set filelist [open $PACKAGE_DIR_VTKDTMRI/../../../data/$pattern {RDONLY}]]
                while {[eof $filelist] != 1} {

                    set line [gets $filelist]
                    if {[lindex $line 0] == "vtkDTMRIprotocol"} {
                        set DTMRI(ispatternfile) 1
                    }
                }

           }

            if {$DTMRI(ispatternfile) == 1} {
                lappend DTMRI(patternnames) $pattern
            }    
       }


    

     # put pattern information into modules variables
    foreach pattern $DTMRI(patternnames) {

        catch [set filelist [open $PACKAGE_DIR_VTKDTMRI/../../../data/$pattern {RDONLY}]]
        while {[eof $filelist] != 1} {

            set line [gets $filelist]
          if {[lindex $line 0] != "vtkDTMRIprotocol"} {
                if {[lindex $line 0] != ""} {
                    if {[lindex $line 0] != "#"} {
                        for {set i 0} {$i<[llength $line]} {incr i} {
                         
                            lappend DTMRI($pattern,parameters) [lindex $line $i]
                        }
                    }
                }
            }
        }
    }

   } else {
       set DTMRI(patternnames) ""
   } 

     
   if { [file exists $env(HOME)/PatternsData/] != 0 } then {

    #set DTMRI(localpatternnamesdef) [exec ls $env(HOME)/PatternsData/]
    set DTMRI(localpatternnamesdef) [glob -tail -directory $env(HOME)/PatternsData/ *]
    set DTMRI(localpatternnames) ""

    # check if the file contains pattern information
    foreach pattern $DTMRI(localpatternnamesdef) {
    set DTMRI(ispatternfile) 0    
       
       if { [file isfile $env(HOME)/PatternsData/$pattern] != 0 } {

        catch [set filelist [open $env(HOME)/PatternsData/$pattern {RDONLY}]]
        while {[eof $filelist] != 1} {

            set line [gets $filelist]
            if { [ lindex $line  0 ] == "vtkDTMRIprotocol" } {
                set DTMRI(ispatternfile) 1
            }
        }

       }

        if {$DTMRI(ispatternfile) == 1} {
            lappend DTMRI(localpatternnames) $pattern
        }    
    }
 
     # Variable containing all the patterns available (the ones from the module and the locals ones)
    set DTMRI(patternnames) [concat $DTMRI(patternnames) $DTMRI(localpatternnames)]

     # put pattern information into modules variables
        foreach pattern $DTMRI(localpatternnames) {

        catch [set filelist [open $env(HOME)/PatternsData/$pattern {RDONLY}]]
            while {[eof $filelist] != 1} {

                set line [gets $filelist]
            if {[lindex $line 0] != "vtkDTMRIprotocol"} {
                    if {[lindex $line 0] != ""} {
                        if {[lindex $line 0] != "#"} {
                            for {set i 0} {$i<[llength $line]} {incr i} {
                             
                                lappend DTMRI($pattern,parameters) [lindex $line $i]

                            }
                        }
                    }
                }

            }

         }
     }

    destroy $Module(DTMRI,fConvert).fConvert.fPattern.mbPattern.menu
    eval {menu $Module(DTMRI,fConvert).fConvert.fPattern.mbPattern.menu}  $Gui(WMA)

    # load existing patterns in the menu of the menubutton
    foreach z $DTMRI(patternnames) {
        set DTMRI(patt) $z
        pack forget $Module(DTMRI,fConvert).fConvert.fPattern.mbPattern      
        $Module(DTMRI,fConvert).fConvert.fPattern.mbPattern.menu add command -label $z -command "
        set DTMRI(selectedpattern) $DTMRI(patt)
        $Module(DTMRI,fConvert).fConvert.fPattern.mbPattern config -text $DTMRI(patt) 
        set DTMRI($DTMRI(patt),tip) {Selected Protocol:\n $DTMRI(patt) \n Number of gradients:\n [lindex $DTMRI($DTMRI(patt),parameters) 0] \n First Gradient in Slice:\n [lindex $DTMRI($DTMRI(patt),parameters) 1] \n Last Gradient in Slice:\n [lindex $DTMRI($DTMRI(patt),parameters) 2] \n Baselines:\n from [lindex $DTMRI($DTMRI(patt),parameters) 3] to [lindex $DTMRI($DTMRI(patt),parameters) 4] \n B-value:\n [lindex $DTMRI($DTMRI(patt),parameters) 5] \n Gradients Directions:\n [lindex $DTMRI($DTMRI(patt),parameters) 6] \n The gradient order is:\n [lindex $DTMRI($DTMRI(patt),parameters) 7] interleaved}
     
        "

     }  
    pack  $Module(DTMRI,fConvert).fConvert.fPattern.mbPattern -side left -padx $Gui(pad) -pady $Gui(pad) -after $Module(DTMRI,fConvert).fConvert.fPattern.lLabel
}
 

#-------------------------------------------------------------------------------
# .PROC DTMRIUpdateTipsPattern
#  
#-------------------------------------------------------------------------------

#proc DTMRIUpdateTipsPattern {} {

#tkwait variable $DTMRI(selectedpattern)
#after 1000
#puts "Reading Module"

#catch {TooltipAdd $Module(DTMRI,fConvert).fConvert.fPattern.mbPattern $DTMRI($DTMRI(selectedpattern),tip)}

#puts $DTMRI($DTMRI(selectedpattern),tip)

#}

  
#-------------------------------------------------------------------------------
# .PROC DTMRIViewProps
#  
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# .PROC DTMRIViewProps
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIViewProps {} {
    puts $DTMRI(selectedpattern)

    if { [info exists DTMRI(selectedpattern)] } {
        DevInfoWindow $DTMRI($DTMRI(selectedpattern),tip)
    }

}
                                         

#-------------------------------------------------------------------------------
# .PROC DTMRIDisplayNewData
#  Once converted the volume data with LSDI script, load and display new data.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIDisplayNewData {} {
    
    global DTMRI Volume  Mrml Module
    
    set v $Volume(activeID)
    if {$v == "" || $v == $Volume(idNone)} {
        puts "Can't create new data from NONE Volume. Load a Volume Data and Select it."
        DevInfoWindow "Can't create new data from NONE Volume.\n Load a Volume Data and Select it."
        return
    }

    #
    # Copy LSDIrecon.par in the selected volume data directory  
    #

    

    puts "Ready."

    #
    # Load the new volume data (D.#) 
    #

    set Volume(activeID) NEW
    set Volume(firstFile) $Volume(DefaultDir)/D.001
    VolumesSetFirst
    VolumesSetLast
    puts "Reading $Volume(name)..."
    VolumesPropsApply
    puts "Displaying New Volume Data..."
    RenderAll
    

  
}


#-------------------------------------------------------------------------------
# .PROC DTMRIPropsApply
#  Apply the settings from the GUI into the currently
#  active MRML node (this is NEW or an existing node).  
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIPropsApply {} {
    global DTMRI Module Tensor
    puts "Lauren in DTMRIPropsApply, note this only works for NEW currently"
    
    set d $Tensor(activeID)
    if {$d == ""} {return}

    # Check all user input
    #-------------------------------------------
    set errcode [MainTensorValidateUserInput]
    if {$errcode != "1"} {
        return $errcode
    }

    # If we are in the process of adding a new data object
    #--------------------------------------------------------
    if {$d == "NEW"} {

        # Create the node
        set newvol [MainMrmlAddNode Volume Tensor]
        set i [$newvol GetID]

        # Set everything up in the node.
        MainTensorSetAllVariablesToNode $i

        # Update MRML (this will read in the new data)
        MainUpdateMRML
        # If failed, then it's no longer in the idList
        # Lauren this is a bug that the user is not informed?
        # And we stay frozen...
        if {[lsearch $Tensor(idList) $i] == -1} {
            puts "Lauren node doesn't exist, should unfreeze and fix volumes.tcltoo"
            return
        }

        # Lauren what is this for?
        set DTMRI(freeze) 0

        # Activate the new data object
        DTMRISetActive $i

    } else {
        # do we do a re-read of the object if user changed certain things?
        # Lauren implement this?
        #MainTensorSetAllVariablesToNode
    }

    # Apply normal settings changed by user (no file reread needed)
    #--------------------------------------------------------
    # Lauren these are only things that can be changed,
    # need to sort all vars into change/no change categories
    # OR just need to do a reread after if certain things changed.
    #MainTensorSetAllVariablesToNode "update"

    # If we were adding a NEW object, unfreeze tabs now
    #--------------------------------------------------------
    if {$Module(freezer) != ""} {
        set cmd "Tab $Module(freezer)"
        set Module(freezer) ""
        eval $cmd
    }

    # Update MRML to apply changed settings
    #--------------------------------------------------------
    MainUpdateMRML
    puts "end of DTMRI props apply"
}

#-------------------------------------------------------------------------------
# .PROC DTMRIPropsCancel
# Cancel 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIPropsCancel {} {
    global DTMRI Module
    puts "Lauren in DTMRIPropsCancel: need to get out of freezer"

    set DTMRI(freeze) 0
    # If we gave up on adding a NEW object, unfreeze tabs now
    #--------------------------------------------------------
    if {$Module(freezer) != ""} {
        set cmd "Tab $Module(freezer)"
        set Module(freezer) ""
        eval $cmd
    }
}

#-------------------------------------------------------------------------------
# .PROC DTMRIAdvancedApply
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIAdvancedApply {} {
    global DTMRI    
    puts "Applying"
    DTMRIApplyVisualizationParameters    
    puts "done applying"
    
    # display our changes
    Render3D
}

#-------------------------------------------------------------------------------
# .PROC DTMRISetFileName
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRISetFileName {} {
    global DTMRI
    
    # Do nothing if the user cancelled
    if {$DTMRI(FileName) == ""} {return}
    
    # Update the Default Directory
    set DTMRI(DefaultDir) [file dirname $DTMRI(FileName)]
    
    # Name the DTMRIs based on the entered file.
    set DTMRI(Name) [ file root [file tail $DTMRI(FileName)]]
}


################################################################
#  bindings for user interaction
################################################################


#-------------------------------------------------------------------------------
# .PROC DTMRICreateBindings
#  Makes bindings for the module.  These are in effect when module is entered
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRICreateBindings {} {
    global Gui Ev; # CustomCsys Csys
    
    #EvDeclareEventHandler DTMRICsysEvents <KeyPress-c> {CustomCsysDoSomethingCool}

    # this seeds a stream when the l key is hit (use s instead, it's nicer)
    EvDeclareEventHandler DTMRISlicesStreamlineEvents <KeyPress-l> \
    { if { [SelectPick2D %W %x %y] != 0 } \
          {  eval DTMRISelectStartHyperStreamline $Select(xyz); Render3D } }
    # this seeds a stream when the s key is hit
    EvDeclareEventHandler DTMRISlicesStreamlineEvents <KeyPress-s> \
    { if { [SelectPick2D %W %x %y] != 0 } \
          {  eval DTMRISelectStartHyperStreamline $Select(xyz); Render3D } }
    
    EvAddWidgetToBindingSet DTMRISlice0Events $Gui(fSl0Win) {DTMRISlicesStreamlineEvents}
    EvAddWidgetToBindingSet DTMRISlice1Events $Gui(fSl1Win) {DTMRISlicesStreamlineEvents}
    EvAddWidgetToBindingSet DTMRISlice2Events $Gui(fSl2Win) {DTMRISlicesStreamlineEvents}

    # this seeds a stream when the l key is hit (use s instead, it's nicer)
    EvDeclareEventHandler DTMRI3DStreamlineEvents <KeyPress-l> \
    { if { [SelectPick DTMRI(vtk,picker) %W %x %y] != 0 } \
          { eval DTMRISelectStartHyperStreamline $Select(xyz);Render3D } }
    # this seeds a stream when the s key is hit
    EvDeclareEventHandler DTMRI3DStreamlineEvents <KeyPress-s> \
    { if { [SelectPick DTMRI(vtk,picker) %W %x %y] != 0 } \
          { eval DTMRISelectStartHyperStreamline $Select(xyz);Render3D } }

    EvDeclareEventHandler DTMRI3DStreamlineEvents <KeyPress-d> \
    { if { [SelectPick DTMRI(vtk,picker) %W %x %y] != 0 } \
          { eval DTMRISelectRemoveHyperStreamline $Select(xyz);Render3D } }

    # This contains all the regular events from tkInteractor.tcl, 
    # which will happen after ours.  For some reason we don't need 
    # this for the slice windows, apparently their original bindings
    # are not done using Ev.tcl and they stay even when we add ours.
    EvAddWidgetToBindingSet DTMRI3DEvents $Gui(fViewWin) {{DTMRI3DStreamlineEvents} {tkMouseClickEvents} {tkMotionEvents} {tkRegularEvents}}
}




################################################################
#  little procedures to handle display control, interaction with user
################################################################


#-------------------------------------------------------------------------------
# .PROC DTMRIRoundFloatingPoint
# Format floats for GUI display (we don't want -5e-11)
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIRoundFloatingPoint {val} {
    global DTMRI

    return [format $DTMRI(floatingPointFormat) $val]
}


#-------------------------------------------------------------------------------
# .PROC DTMRIRemoveAllActors
# Rm all actors from scene.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIRemoveAllActors {} {
    global DTMRI
    
    # rm glyphs
    MainRemoveActor DTMRI(vtk,glyphs,actor)

    # rm streamlines
    DTMRIRemoveAllStreamlines

    Render3D

    set DTMRI(glyphs,actorsAdded) 0
}

#-------------------------------------------------------------------------------
# .PROC DTMRIAddAllActors
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIAddAllActors {} {
    global DTMRI
    
    # rm glyphs
    MainAddActor DTMRI(vtk,glyphs,actor)

    # rm streamlines
    DTMRIAddAllStreamlines

    Render3D

    set DTMRI(glyphs,actorsAdded) 1
}


#-------------------------------------------------------------------------------
# .PROC DTMRIUpdateReformatType
#  Reformat the requested slice (from GUI input) or all.  Then call
#  pipeline update proc (DTMRIUpdate) to make this happen.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIUpdateReformatType {} {
    global DTMRI

    set mode $DTMRI(mode,reformatType)

    set result ok

    # make sure we don't display all DTMRIs by accident
    switch $mode {
        "None" {
            set message "This will display ALL DTMRIs.  If the volume is not masked using a labelmap or threshold ROI, this may take a long time or not work on your machine.  Proceed?"
            set result [tk_messageBox -type okcancel -message $message]
        }
    }

    # display what was requested
    if {$result == "ok"} {
        DTMRIUpdate
    }
}

#-------------------------------------------------------------------------------
# .PROC DTMRIUpdateScalarBar
# Display scalar bar for glyph coloring
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIUpdateScalarBar {} {
    global DTMRI

    set mode $DTMRI(mode,scalarBar)

    switch $mode {
        "On" {
            DTMRIShowScalarBar
        }
        "Off" {
            DTMRIHideScalarBar
        }
    }

    Render3D
}

#-------------------------------------------------------------------------------
# .PROC DTMRIShowScalarBar
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIShowScalarBar {} {
    DTMRIUpdateGlyphScalarRange
    DTMRI(vtk,scalarBar,actor) VisibilityOn
    #viewRen AddProp DTMRI(vtk,scalarBar,actor)
}

#-------------------------------------------------------------------------------
# .PROC DTMRIHideScalarBar
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIHideScalarBar {} {
    DTMRI(vtk,scalarBar,actor) VisibilityOff
    #viewRen RemoveActor DTMRI(vtk,scalarBar,actor)
}


#-------------------------------------------------------------------------------
# .PROC DTMRIUpdateThreshold
# If we are thresholding the glyphs to display a subvolume and
# the user requests a new threshold range this is called.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIUpdateThreshold {{not_used ""}} {
    global DTMRI
    
    DTMRI(vtk,thresh,threshold)  ThresholdBetween \
    $DTMRI(thresh,threshold,lower) \
    $DTMRI(thresh,threshold,upper)

    # Update pipelines
    Render3D
}

#-------------------------------------------------------------------------------
# .PROC DTMRIUpdateMaskLabel
# If we are masking the glyphs to display a subvolume and
# the user requests a new mask label value this is called. 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIUpdateMaskLabel {} {
    global Label

    LabelsFindLabel

    # this label becomes 1 in the mask
    set thresh DTMRI(vtk,mask,threshold)
    $thresh ThresholdBetween $Label(label) $Label(label)

    # Update pipelines
    Render3D
}

#-------------------------------------------------------------------------------
# .PROC DTMRISpecificVisualizationSettings
# Set up visualization to see DTMRIs well.
# Transparent 3D slices and black background...
# 
# FUTURE IDEAS:
# It would be nice if this sort of setting could be pushed/
# popped like the bindings stack that Peter wrote (Events.tcl).
# This would allow modules to control the visualization
# but not interfere with other modules.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRISpecificVisualizationSettings {} {
    global Anno

    # let us see DTMRIs through the slices
    MainSlicesSet3DOpacityAll 0.5
    #MainSlicesSet3DOpacityAll 0.1
    #MainViewSetBackgroundColor Black
    # show all digits of float data (i.e. trace)
    MainAnnoSetPixelDisplayFormat "full"
    # turn off those irritating letters
    set Anno(letters) 0
    MainAnnoSetVisibility
}

#-------------------------------------------------------------------------------
# .PROC DTMRIResetDefaultVisualizationSettings
# Undo the DTMRISpecific settings and use defaults 
# of the slicer.  
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIResetDefaultVisualizationSettings {} {
    global Anno

    # let us see DTMRIs through the slices
    MainSlicesReset3DOpacityAll
    #MainViewSetBackgroundColor Blue
    # show all digits of float data (i.e. trace)
    MainAnnoSetPixelDisplayFormat "default"
    # turn back on those irritating letters
    #set Anno(letters) 1
    MainAnnoSetVisibility
}

#-------------------------------------------------------------------------------
# .PROC DTMRIApplyVisualizationSettings
#  Set the settings the user requested, default or for DTMRIs
# .ARGS
# str mode optional, default or DTMRIs
# .END
#-------------------------------------------------------------------------------
proc DTMRIApplyVisualizationSettings {{mode ""}} {
    global DTMRI
    
    if {$mode == ""} {
        set mode $DTMRI(mode,visualizationSettingsType)
    }
    
    switch $mode {
        "default" {
            DTMRIResetDefaultVisualizationSettings
        }
        "DTMRIs" {
            DTMRISpecificVisualizationSettings
        }
    }

    Render3D
}

################################################################
#  visualization procedures that deal with glyphs
################################################################
#-------------------------------------------------------------------------------
# .PROC DTMRIUpdateGlyphResolution
# choose the resolution of the glyphs
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIUpdateGlyphResolution { value } {
    global DTMRI

    foreach plane "0 1 2" {
      DTMRI(vtk,glyphs$plane) SetResolution $DTMRI(mode,glyphResolution)
    }
    #update 3D window (causes pipeline update)
    Render3D
}

#-------------------------------------------------------------------------------
# .PROC DTMRIUpdateGlyphEigenvector
# choose max middle or min for display
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIUpdateGlyphEigenvector {} {
    global DTMRI

    set mode $DTMRI(mode,glyphEigenvector)

    # Scaling along x-axis corresponds to major 
    # eigenvector, etc.  So move the line to 
    # point along the proper axis for scaling
    switch $mode {
        "Max" {
            DTMRI(vtk,glyphs,line) SetPoint1 -1 0 0
            DTMRI(vtk,glyphs,line) SetPoint2 1 0 0    
        }
        "Middle" {
            DTMRI(vtk,glyphs,line) SetPoint1 0 -1 0
            DTMRI(vtk,glyphs,line) SetPoint2 0 1 0    
        }
        "Min" {
            DTMRI(vtk,glyphs,line) SetPoint1 0 0 -1
            DTMRI(vtk,glyphs,line) SetPoint2 0 0 1    
        }
    }
    # Update pipelines
    Render3D
}

#-------------------------------------------------------------------------------
# .PROC DTMRIUpdateGlyphColor
# switch between various color options the user can select for glyphs
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIUpdateGlyphColor {} {
    global DTMRI
    
    set mode $DTMRI(mode,glyphColor)
    
    # display new mode while we are working...
    $DTMRI(gui,mbGlyphColor)    config -text $mode
    
    foreach plane {0 1 2} {
    switch $mode {
        "Linear" {
            DTMRI(vtk,glyphs$plane) ColorGlyphsWithLinearMeasure
        }
        "Planar" {
            DTMRI(vtk,glyphs$plane) ColorGlyphsWithPlanarMeasure
        }
        "Spherical" {
            DTMRI(vtk,glyphs$plane) ColorGlyphsWithSphericalMeasure
        }
        "Max" {
            DTMRI(vtk,glyphs$plane) ColorGlyphsWithMaxEigenvalue
        }
        "Middle" {
            DTMRI(vtk,glyphs$plane) ColorGlyphsWithMiddleEigenvalue
        }
        "Min" {
            DTMRI(vtk,glyphs$plane) ColorGlyphsWithMinEigenvalue
        }
        "MaxMinusMiddle" {
            DTMRI(vtk,glyphs$plane) ColorGlyphsWithMaxMinusMidEigenvalue
        }
        "RA" {
            DTMRI(vtk,glyphs$plane) ColorGlyphsWithRelativeAnisotropy
        }
        "FA" {
            DTMRI(vtk,glyphs$plane) ColorGlyphsWithFractionalAnisotropy
        }
        "Direction" {
            DTMRI(vtk,glyphs$plane) ColorGlyphsWithDirection
        }
        
    }
    
    }
    # Tell actor where to get scalar range
    set DTMRI(mode,glyphScalarRange) Auto
    DTMRIUpdateGlyphScalarRange

    # Update pipelines
    Render3D

}

#-------------------------------------------------------------------------------
# .PROC DTMRIUpdateGlyphScalarRange
# Called to reset the scalar range displayed to correspond to the 
# numbers output by the current coloring method
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIUpdateGlyphScalarRange {{not_used ""}} {
    global DTMRI Tensor

    # make sure we have a DTMRI displayed now
    set t $Tensor(activeID)
    if {$t == "" || $t == $Tensor(idNone)} {
        return
    }

    # make sure the pipeline is up-to-date so we get the right
    # scalar range.  Otherwise the first render will not have
    # the right glyph colors.
    DTMRI(vtk,glyphs,append) Update

    set mode $DTMRI(mode,glyphScalarRange)

    # find scalar range if not set by user
    switch $mode {
        "Auto" {
            scan [[DTMRI(vtk,glyphs,append) GetOutput] GetScalarRange] \
        "%f %f" s1 s2
        }
        "Manual" {
            set s1 $DTMRI(mode,glyphScalarRange,low) 
            set s2 $DTMRI(mode,glyphScalarRange,hi) 
        }
    }

    # make sure that the scalars hi and low are not equal since
    # this causes an error from the mapper
    if {$s2 == $s1} {
        set s1 0
        set s2 1
    }    
    # set this scalar range for glyph display
    DTMRI(vtk,glyphs,mapper) SetScalarRange $s1 $s2

    # Round the scalar range numbers to requested precision
    # This way -4e-12 will not look like a negative eigenvalue in
    # the GUI
    set DTMRI(mode,glyphScalarRange,low) \
    [DTMRIRoundFloatingPoint $s1]
    set DTMRI(mode,glyphScalarRange,hi) \
    [DTMRIRoundFloatingPoint $s2]

    # This causes multiple renders since for some reason
    # the scalar bar does not update on the first one
    Render3D
}


################################################################
#  visualization procedures that deal with tracts
################################################################


#-------------------------------------------------------------------------------
# .PROC DTMRISelectRemoveHyperStreamline
#  Remove the selected hyperstreamline
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRISelectRemoveHyperStreamline {x y z} {
    global DTMRI
    global Select

    puts "Select Picker  (x,y,z):  $x $y $z"

    # see which actor was picked
    set actor [DTMRI(vtk,picker) GetActor]

    DTMRI(vtk,streamlineControl) DeleteStreamline $actor
}

#-------------------------------------------------------------------------------
# .PROC DTMRISelectStartHyperStreamline
# Given x,y,z in world coordinates, starts a streamline from that point
# in the active DTMRI dataset.
# .ARGS
# int x 
# int y
# int z 
# .END
#-------------------------------------------------------------------------------
proc DTMRISelectStartHyperStreamline {x y z {render "true"} } {
    global DTMRI Tensor Color Label Volume
    global Select


    set t $Tensor(activeID)
    if {$t == "" || $t == $Tensor(idNone)} {
        puts "DTMRISelect: No DTMRIs have been read into the slicer"
        return
    }
    
    # set mode to On (the Display Tracts button will go On)
    set DTMRI(mode,visualizationType,tractsOn) On


    # Set up all parameters from the user
    # NOTE: TODO: make an Apply button and only call this 
    # when the user changes settings. Here it is too slow.
    DTMRIUpdateStreamlineSettings

    # actually create and display the streamline
    DTMRI(vtk,streamlineControl) SeedStreamlineFromPoint $x $y $z
    DTMRI(vtk,streamlineControl) AddStreamlinesToScene

    # Force pipeline execution and render scene
    #------------------------------------
    if { $render == "true" } {
        Render3D
    }
}


#-------------------------------------------------------------------------------
# .PROC DTMRIUpdateStreamlineSettings
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIUpdateStreamlineSettings {} {
    global DTMRI

    # set up type of streamline to create
    switch $DTMRI(stream,tractingMethod) {
        "BSpline" {

            # What type of streamline object to create
            DTMRI(vtk,streamlineControl) UseVtkPreciseHyperStreamlinePoints

            # apply correct settings to example streamline object
            set streamline "streamlineControl,vtkPreciseHyperStreamlinePoints"

            DTMRI(vtk,$streamline) SetMethod $DTMRI(vtk,ivps)
            if {$DTMRI(stream,LowerBoundBias) > $DTMRI(stream,UpperBoundBias)} {
                set DTMRI(stream,UpperBoundBias) $DTMRI(stream,LowerBoundBias)
            }
            DTMRI(vtk,$streamline) SetTerminalFractionalAnisotropy \
                $DTMRI(stream,LowerBoundBias)
            foreach var $DTMRI(stream,methodvariableList) {
                DTMRI(vtk,itf) Set$var $DTMRI(stream,$var)
            }
            foreach var $DTMRI(stream,precisevariableList) {
                if { $var == "MaxAngle" } {
                    DTMRI(vtk,$streamline) Set$var \
                        [ expr cos( $DTMRI(stream,$var) * 3.14159265 / 180 ) ]
                } else {
                    DTMRI(vtk,$streamline) Set$var $DTMRI(stream,$var)
                }
    
            }

        }

        "NoSpline" {
            # What type of streamline object to create
            DTMRI(vtk,streamlineControl) UseVtkHyperStreamlinePoints

            # apply correct settings to example streamline object
            set streamline "streamlineControl,vtkHyperStreamlinePoints"
            foreach var $DTMRI(stream,variableList) {
                DTMRI(vtk,$streamline) Set$var $DTMRI(stream,$var)
            }

            
        }
    }
}


#-------------------------------------------------------------------------------
# .PROC DTMRIUpdateStreamlines
# show/hide/delete all
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIUpdateStreamlines {} {
    global DTMRI
    
    set mode $DTMRI(mode,visualizationType,tractsOn)

    switch $mode {
        "On" {
            # add actors
            DTMRIAddAllStreamlines
        }
        "Off" {
            # hide actors
            DTMRIRemoveAllStreamlines
        }
        "Delete" {
            # kill all objects
            DTMRIDeleteAllStreamlines
            # set mode to Off (will be set to On when add new stream)
            set DTMRI(mode,visualizationType,tractsOn) Off
        }
    }
}



#-------------------------------------------------------------------------------
# .PROC DTMRIUpdateTractingMethod
# .ARGS
# TractingMethod
# .END
#-------------------------------------------------------------------------------
proc DTMRIUpdateTractingMethod { TractingMethod } {
    global DTMRI Tensor
 
    if {$TractingMethod != $DTMRI(stream,tractingMethod) } {
        set DTMRI(stream,tractingMethod) $TractingMethod
        switch $DTMRI(stream,tractingMethod) {
            "NoSpline" {
                raise $DTMRI(stream,tractingFrame,NoSpline)
                focus $DTMRI(stream,tractingFrame,NoSpline)
                $DTMRI(gui,mbTractingMethod)    config -text $TractingMethod
                
            }
            "BSpline" {
                raise $DTMRI(stream,tractingFrame,BSpline)
                focus $DTMRI(stream,tractingFrame,BSpline)
                $DTMRI(gui,mbTractingMethod)    config -text $TractingMethod

                # Apparently all of these Updates really are needed
                # set up the BSpline tractography pipeline
                set t $Tensor(activeID)
                set DTMRI(vtk,BSpline,data) 1
                set DTMRI(vtk,BSpline,init) 1;
                DTMRI(vtk,itf) SetDataBounds [Tensor($t,data) GetOutput]
                for {set i 0} {$i < 6} {incr i} {
                    DTMRI(vtk,extractor($i)) SetInput [Tensor($t,data) GetOutput]
                }
                for {set i 0} {$i < 6} {incr i} {
                    DTMRI(vtk,extractor($i)) Update
                    DTMRI(vtk,bspline($i)) SetInput [DTMRI(vtk,extractor($i)) GetOutput]
                }          
                DTMRIUpdateBSplineOrder $DTMRI(stream,BSplineOrder)
                for {set i 0} {$i < 6} {incr i} {
                    DTMRI(vtk,bspline($i)) Update
                    DTMRI(vtk,impComp($i)) SetInput [DTMRI(vtk,bspline($i)) GetOutput]
                }

            }
        }
    }
}

#-------------------------------------------------------------------------------
# .PROC DTMRIUpdateBSplineOrder
# .ARGS
# SplineOrder
# .END
#-------------------------------------------------------------------------------
proc DTMRIUpdateBSplineOrder { SplineOrder } {
    global DTMRI
    if { $SplineOrder != $DTMRI(stream,BSplineOrder) } {
        set DTMRI(stream,BSplineOrder) $SplineOrder
        $DTMRI(gui,mbBSplineOrder)    config -text $SplineOrder

        for {set i 0} {$i < 6} {incr i 1} {
            DTMRI(vtk,impComp($i)) SetSplineOrder $SplineOrder
            DTMRI(vtk,bspline($i)) SetSplineOrder $SplineOrder
            if { $DTMRI(vtk,BSpline,init) == 1 } {
                DTMRI(vtk,bspline($i)) Update
                DTMRI(vtk,impComp($i)) SetInput [DTMRI(vtk,bspline($i)) GetOutput]
            }
        }

    }
}


#-------------------------------------------------------------------------------
# .PROC DTMRIUpdateTractColorToSolid
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIUpdateTractColorToSolid {} {
    DTMRIUpdateTractColor SolidColor
}

#-------------------------------------------------------------------------------
# .PROC DTMRIUpdateTractColorToMulti
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIUpdateTractColorToMulti {} {
    DTMRIUpdateTractColor MultiColor
}

#-------------------------------------------------------------------------------
# .PROC DTMRIUpdateTractColor
# configure the coloring to be solid or scalar per triangle 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIUpdateTractColor {{mode ""}} {
    global DTMRI Volume Tensor Color Label

    if {$mode == ""} {
        set mode $DTMRI(mode,tractColor)
    }
    
    # whether scalars should be displayed
    switch $mode {
        "SolidColor" {

            # display new mode while we are working...
            $DTMRI(gui,mbTractColor)    config -text $mode

            # find color from the name we have saved; use 1st as default
            set c [lindex $Color(idList) 1]
            foreach id $Color(idList) {
                if {[Color($id,node) GetName] == $Label(name)} {
                    set c $id
                }
            }
            # set up properties of the new actors we will create
            set prop [DTMRI(vtk,streamlineControl) GetStreamlineProperty] 
            #$prop SetAmbient       [Color($c,node) GetAmbient]
            #$prop SetDiffuse       [Color($c,node) GetDiffuse]
            #$prop SetSpecular      [Color($c,node) GetSpecular]
            #$prop SetSpecularPower [Color($c,node) GetPower]
            eval $prop SetColor    [Color($c,node) GetDiffuseColor] 

            # display solid colors instead of scalars
            DTMRI(vtk,streamlineControl) ScalarVisibilityOff
        }
        "MultiColor" {
            # put the volume we wish to color by as the Scalars field 
            # in the tensor volume.
            set t $Tensor(activeID)            
            set v $Volume(activeID)

            # make sure they have the same extent
            set ext1 [[Tensor($t,data) GetOutput] GetWholeExtent]
            set ext2 [[Volume($v,vol) GetOutput] GetWholeExtent]
            if {[string equal $ext1 $ext2]} {

                $DTMRI(gui,mbTractColor)    config -text $mode

                # put the scalars there
                DTMRI(vtk,streamline,merge) SetScalars [Volume($v,vol) GetOutput]

                # setting scalars like this caused a crash in
                # the vtkMrmlDataVolume's vtkImageAccumulateDiscrete. why??
                #[[Tensor($t,data) GetOutput] GetPointData] SetScalars \
                #    [[[Volume($v,vol) GetOutput] GetPointData] GetScalars]

                DTMRI(vtk,streamlineControl) ScalarVisibilityOn
                eval {[DTMRI(vtk,streamlineControl) GetStreamlineLookupTable] \
                          SetRange} [[Volume($v,vol) GetOutput] GetScalarRange]
                
                # set up properties of the new actors we will create
                set prop [DTMRI(vtk,streamlineControl) GetStreamlineProperty] 
                # By default make them brighter than slicer default colors
                # slicer's colors have ambient 0, diffuse 1, and specular 0
                #$prop SetAmbient       0.5
                #$prop SetDiffuse       0.1
                #$prop SetSpecular      0.2

            } else {
                set message "Please select a volume with the same dimensions as the DTMRI dataset (for example one you have created from the Scalars tab)."
                set result [tk_messageBox  -message $message]

            }
        }
    }

    Render3D
}



#-------------------------------------------------------------------------------
# .PROC DTMRIRemoveAllStreamlines
# Remove all streamline actors from scene.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIRemoveAllStreamlines {} {
    global DTMRI

    DTMRI(vtk,streamlineControl) RemoveStreamlinesFromScene
    Render3D
}

#-------------------------------------------------------------------------------
# .PROC DTMRIAddAllStreamlines
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIAddAllStreamlines {} {
    global DTMRI

    DTMRI(vtk,streamlineControl) AddStreamlinesToScene
    Render3D
}

#-------------------------------------------------------------------------------
# .PROC DTMRIDeleteAllStreamlines
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIDeleteAllStreamlines {} {
    global DTMRI

    DTMRI(vtk,streamlineControl) DeleteAllStreamlines
    Render3D
}

#-------------------------------------------------------------------------------
# .PROC DTMRISeedStreamlinesFromSegmentation
# Seeds streamlines at all points in a segmentation.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRISeedStreamlinesFromSegmentation {{verbose 1}} {
    global DTMRI Label Tensor Volume

    set t $Tensor(activeID)
    set v $Volume(activeID)

    # make sure they are using a segmentation (labelmap)
    if {[Volume($v,node) GetLabelMap] != 1} {
        set name [Volume($v,node) GetName]
        set msg "The volume $name is not a label map (segmented ROI). Continue anyway?"
        if {[tk_messageBox -type yesno -message $msg] == "no"} {
            return
        }

    }

    # ask for user confirmation first
    if {$verbose == "1"} {
        set name [Volume($v,node) GetName]
        set msg "About to seed streamlines in all labelled voxels of volume $name.  This may take a while, so make sure the Tracts settings are what you want first. Go ahead?"
        if {[tk_messageBox -type yesno -message $msg] == "no"} {
            return
        }
    }

    # set mode to On (the Display Tracts button will go On)
    set DTMRI(mode,visualizationType,tractsOn) On

    # make sure the settings are current
    DTMRIUpdateTractColor
    DTMRIUpdateStreamlineSettings
    
    # set up the input segmented volume
    DTMRI(vtk,streamlineControl) SetInputROI [Volume($v,vol) GetOutput] 
    DTMRI(vtk,streamlineControl) SetInputROIValue $Label(label)

    # Get positioning information from the MRML node
    # world space (what you see in the viewer) to ijk (array) space
    vtkTransform transform
    transform SetMatrix [Volume($v,node) GetWldToIjk]
    # now it's ijk to world
    transform Inverse
    DTMRI(vtk,streamlineControl) SetROIToWorld transform
    transform Delete

    # create all streamlines
    puts "Original number of tracts: [[DTMRI(vtk,streamlineControl) GetStreamlines] GetNumberOfItems]"
    DTMRI(vtk,streamlineControl) SeedStreamlinesFromROI
    puts "New number of tracts will be: [[DTMRI(vtk,streamlineControl) GetStreamlines] GetNumberOfItems]"
    puts "Creating and displaying new tracts..."

    # actually display streamlines 
    # (this is the slow part since it causes pipeline execution)
    DTMRI(vtk,streamlineControl) AddStreamlinesToScene
}



#-------------------------------------------------------------------------------
# .PROC DTMRISeedStreamlinesFromSegmentation
# Seeds streamlines at all points in a segmentation.
# This does not display anything, just one by one seeds
# the streamline and saves it to disk. So nothing is 
# visualized, this is for exporting files only.
# (Actually displaying all of the streamlines would be impossible
# with a whole brain ROI.)
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRISeedAndSaveStreamlinesFromSegmentation {{verbose 1}} {
    global DTMRI Label Tensor Volume

    set t $Tensor(activeID)
    set v $Volume(activeID)

    # make sure they are using a segmentation (labelmap)
    if {[Volume($v,node) GetLabelMap] != 1} {
        set name [Volume($v,node) GetName]
        set msg "The volume $name is not a label map (segmented ROI). Continue anyway?"
        if {[tk_messageBox -type yesno -message $msg] == "no"} {
            return
        }

    }

    # set base filename for all stored files
    set filename [tk_getSaveFile  -title "Save Tracts: Choose Initial Filename"]
    if { $filename == "" } {
        return
    }


    # make a subdirectory for them, named the same as the files                            
    set name [file root [file tail $filename]]
    set dir [file dirname $filename]
    set newdir [file join $dir tract_files_$name]
    file mkdir $newdir
    set filename [file join $newdir $name]
    # make a subdirectory for the vtk models                                               
    set newdir2 [file join $newdir vtk_model_files]
    file mkdir $newdir2
    set filename2 [file join $newdir2 $name]

    # ask for user confirmation first
    if {$verbose == "1"} {
        set name [Volume($v,node) GetName]
        set msg "About to seed streamlines in all labelled voxels of volume $name.  This may take a while, so make sure the Tracts settings are what you want first. Go ahead?"
        if {[tk_messageBox -type yesno -message $msg] == "no"} {
            return
        }
    }

    # make sure the settings are current for the models we save to disk              
    #DTMRIUpdateTractColor                                                          
    DTMRIUpdateStreamlineSettings

    # set up the input segmented volume
    DTMRI(vtk,streamlineControl) SetInputROI [Volume($v,vol) GetOutput] 
    DTMRI(vtk,streamlineControl) SetInputROIValue $Label(label)

    # Get positioning information from the MRML node
    # world space (what you see in the viewer) to ijk (array) space
    vtkTransform transform
    transform SetMatrix [Volume($v,node) GetWldToIjk]
    # now it's ijk to world
    transform Inverse
    DTMRI(vtk,streamlineControl) SetROIToWorld transform
    transform Delete

    # create all streamlines
    puts "Starting to seed streamlines. Files will be $filename*.*"
    DTMRI(vtk,streamlineControl) SeedAndSaveStreamlinesFromROI \
        $filename  $filename2

    # let user know something happened
    if {$verbose == "1"} {
        set msg "Finished writing tracts. The filename is: $filename*.*"
        tk_messageBox -message $msg
    }
}


################################################################
#  MAIN visualization procedure: pipeline control is here
################################################################

#-------------------------------------------------------------------------------
# .PROC DTMRIUpdate
# The whole enchilada (if this were a vtk filter, this would be
# the Execute function...)
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIUpdate {} {
    global DTMRI Slice Volume Label Gui Tensor

    set t $Tensor(activeID)
    if {$t == "" || $t == $Tensor(idNone)} {
        puts "DTMRIUpdate: Can't visualize Nothing"
        return
    }

    # reset progress text for any filter that uses the blue bar
    set Gui(progressText) "Working..."

    #------------------------------------
    # preprocessing pipeline
    #------------------------------------


    # threshold DTMRIs if required
    #------------------------------------
    set mode $DTMRI(mode,threshold)
    if {$mode != "None"} {
        
        puts "thresholding by $DTMRI(mode,threshold)"
        set math DTMRI(vtk,thresh,math)

        # calculate trace or whatever we are thresholding by
        $math SetInput 0 [Tensor($t,data) GetOutput]
        $math SetInput 1 [Tensor($t,data) GetOutput]
        $math SetOperationTo$DTMRI(mode,threshold)

        # threshold to make a mask of the area of interest
        set thresh1 DTMRI(vtk,thresh,threshold)
        $thresh1 ThresholdBetween $DTMRI(thresh,threshold,lower) \
        $DTMRI(thresh,threshold,upper)

        # this line seems to be needed
        $thresh1 Update
        
        #DTMRI(vtk,glyphs) SetScalarMask [$thresh GetOutput]
        # tell our filter to use this information
        #DTMRI(vtk,glyphs) MaskGlyphsWithScalarsOn

        #  set DTMRIs to 0 outside of mask generated above
        set mask1 DTMRI(vtk,thresh,mask)
        $mask1 SetImageInput [Tensor($t,data) GetOutput]

        set dataSource [$mask1 GetOutput]
    } else {
        set dataSource [Tensor($t,data) GetOutput]
        #DTMRI(vtk,glyphs) MaskGlyphsWithScalarsOff
    }

    # mask DTMRIs if required
    #------------------------------------
    set mode $DTMRI(mode,mask)
    if {$mode != "None"} {
        
        puts "masking by $DTMRI(mode,mask)"
        # note it would be more efficient to 
        # combine the two masks (from thresh and here) 
        # but probably not both used at once 

        set thresh DTMRI(vtk,mask,threshold)    
        $thresh ThresholdBetween $Label(label) $Label(label)
        set v $Volume(activeID)
        $thresh SetInput [Volume($v,vol) GetOutput]

        # this line seems to be needed
        $thresh Update
        
        set mask DTMRI(vtk,mask,mask)
        # use output from above thresholding pipeline as input
        $mask SetImageInput $dataSource

        # set the dataSource to point to our output 
        # for the following pipelines
        set preprocessedSource [$mask GetOutput]
    } else {
        set preprocessedSource $dataSource
    }

    #------------------------------------
    # visualization pipeline
    #------------------------------------
    #set mode $DTMRI(mode,visualizationType)
    set mode $DTMRI(mode,visualizationType,glyphsOn)
    puts "Setting glyph mode $mode for DTMRI $t"
    
    switch $mode {
        "On" {
            puts "glyphs! $DTMRI(mode,glyphType)"
            
            # Find input to pipeline
            #------------------------------------
            set slice $DTMRI(mode,reformatType)

        # find ijk->ras rotation to apply to each DTMRI
        #vtkTransform t2 
        #DTMRICalculateIJKtoRASRotationMatrix t2 $t
        #puts "Lauren testing rm -y"
        #t2 Scale 1 -1 1
        #puts [[t2 GetMatrix] Print]
        #DTMRI(vtk,glyphs) SetTensorRotationMatrix [t2 GetMatrix]
        #t2 Delete
        DTMRICalculateIJKtoRASRotationMatrix DTMRI(vtk,glyphs,trans) $t
        foreach plane {0 1 2} {
      DTMRI(vtk,glyphs$plane) SetTensorRotationMatrix [DTMRI(vtk,glyphs,trans) GetMatrix]
        }
            if {$slice != "None"} {
              foreach plane $slice {
                # We are reformatting a slice of glyphs
                DTMRI(vtk,reformat$plane) SetInput $preprocessedSource

                # set fov same as volume we are overlaying
                DTMRI(vtk,reformat$plane) SetFieldOfView [Slicer GetFieldOfView]

                # tell reformatter to obey the node
                set node Tensor($Tensor(activeID),node)
                DTMRI(vtk,reformat$plane) SetInterpolate [$node GetInterpolate]
                DTMRI(vtk,reformat$plane) SetWldToIjkMatrix [$node GetWldToIjk]
                
                #  reformat resolution should match the DTMRI resolution.
                # Use the extents to figure this out.
                set ext [[Tensor($Tensor(activeID),data) GetOutput] GetExtent]
                set resx [expr [lindex $ext 1] - [lindex $ext 0] + 1]
                set resy [expr [lindex $ext 3] - [lindex $ext 2] + 1]
                if {$resx > $resy} {
                    set res $resx
                } else {
                    set res $resy
                }

                DTMRI(vtk,reformat$plane) SetResolution $res

                set m [Slicer GetReformatMatrix $plane]
                DTMRI(vtk,reformat$plane) SetReformatMatrix $m
                set visSource [DTMRI(vtk,reformat$plane) GetOutput]
                
                # Position glyphs with the slice.
                # The glyph filter will transform output points by this 
                # matrix.  We can't just move the actor in space
                # since this will rotate the DTMRIs, so this is wrong:
                # DTMRI(vtk,glyphs,actor) SetUserMatrix $m
                DTMRI(vtk,glyphs$plane) SetVolumePositionMatrix $m
        
        DTMRI(vtk,glyphs$plane) SetInput $visSource
          }    

            } else {
                # We are displaying the whole volume of glyphs!
                set visSource $preprocessedSource
                
                # Want actor to be positioned in center with slices
                vtkTransform t1
                DTMRICalculateActorMatrix t1 $Tensor(activeID)
                
                # Position glyphs in the volume.
                # The glyph filter will transform output points by this 
                # matrix.  We can't just move the actor in space
                # since this will rotate the DTMRIs, so this is wrong:
                #DTMRI(vtk,glyphs,actor) SetUserMatrix [t1 GetMatrix]
                DTMRI(vtk,glyphs0) SetVolumePositionMatrix [t1 GetMatrix]
                t1 Delete
        
        DTMRI(vtk,glyphs0) SetInput $visSource
            }


            # Append glyphs
            #------------------------------------
        #Disconnect previous glyphs
        set prevnumInputs [DTMRI(vtk,glyphs,append) GetNumberOfInputs]
          for {set i 0} {$i < $prevnumInputs} {incr i} {
            DTMRI(vtk,glyphs,append) SetInputByNumber $i ""
          }     
            if {$slice != "None"} {
          set numInputs [llength $slice]
          DTMRI(vtk,glyphs,append) SetNumberOfInputs $numInputs
              foreach plane $slice {
            DTMRI(vtk,glyphs,append) SetInputByNumber [expr $plane%$numInputs] [DTMRI(vtk,glyphs$plane) GetOutput]
          }
        } else {
          set numInputs 1
          DTMRI(vtk,glyphs,append) SetNumberOfInputs $numInputs
          DTMRI(vtk,glyphs,append) SetInputByNumber 0 [DTMRI(vtk,glyphs0) GetOutput]
        }    
              
            # for lines don't use normals filter before mapper
        DTMRI(vtk,glyphs,mapper) SetInput \
        [DTMRI(vtk,glyphs,append) GetOutput]

            # Use axes or ellipsoids
            #------------------------------------
      foreach plane "0 1 2" {  
            switch $DTMRI(mode,glyphType) {
                "Axes" {
                    DTMRI(vtk,glyphs$plane) SetSource \
            [DTMRI(vtk,glyphs,axes) GetOutput]

                    # this is too slow, but might make nice pictures
                    #[DTMRI(vtk,glyphs,tubeAxes) GetOutput]

                }
                "Lines" {
                    DTMRI(vtk,glyphs$plane) SetSource \
            [DTMRI(vtk,glyphs,line) GetOutput]

                }
                "Ellipsoids" {
                    DTMRI(vtk,glyphs$plane) SetSource \
            [DTMRI(vtk,glyphs,sphere) GetOutput]

                    # this normal filter improves display but is slow.
                    DTMRI(vtk,glyphs,mapper) SetInput \
                        [DTMRI(vtk,glyphs,normals) GetOutput]
                }
                "Boxes" {
                    DTMRI(vtk,glyphs$plane) SetSource \
            [DTMRI(vtk,glyphs,box) GetOutput]

                    # this normal filter improves display but is slow.
                    DTMRI(vtk,glyphs,mapper) SetInput \
                        [DTMRI(vtk,glyphs,normals) GetOutput]
                }
            }
         }

            # in case this is the first time we load a tensor volume, 
            # place the actors in the scene now. (Now that there is input
            # to the pipeline this will not cause errors.)
            if {$DTMRI(glyphs,actorsAdded) == 0} {
                DTMRIAddAllActors
            }

            # Make actor visible
            #------------------------------------
            DTMRI(vtk,glyphs,actor) VisibilityOn

        }
        "Off" {
            puts "Turning off DTMRI visualization"

            # make invisible so output
            # not requested from pipeline anymore
            #------------------------------------
            DTMRI(vtk,glyphs,actor) VisibilityOff
        }
    }

    # make sure the scalars are updated (if we have anything displayed)
    if {$mode != "None" && $DTMRI(glyphs,actorsAdded)==1} {
        DTMRIUpdateGlyphScalarRange
    }
    # update 3D window (causes pipeline update)
    Render3D
}

################################################################
#  Procedures used to derive scalar volumes from DTMRI data
################################################################

#-------------------------------------------------------------------------------
# .PROC DTMRISetOperation
# Set the mathematical operation we should do to produce
# a scalar volume from the DTMRIs
# .ARGS
# str math the name of the operation from list $DTMRI(scalars,operationList)
# .END
#-------------------------------------------------------------------------------
proc DTMRISetOperation {math} {
    global DTMRI

    set DTMRI(scalars,operation) $math
    
    # config menubutton
    $DTMRI(gui,mbMath) config -text $math
}


#-------------------------------------------------------------------------------
# .PROC DTMRIUpdateMathParams
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIUpdateMathParams {} {
    global DTMRI


    # Just check that if they requested a 
    # preprocessing step, that we are already
    # doing that step
    
    set mode $DTMRI(scalars,ROI)

    set err "The $mode ROI is not currently being computed.  Please turn this feature on in the ROI tab before creating the volume."

    switch $mode {
        "None" {
        }
        "Threshold" {
            if {$DTMRI(mode,threshold)    == "None"} {
                set DTMRI(scalars,ROI) None
                tk_messageBox -message $err
            }
        }
        "Mask" {
            if {$DTMRI(mode,mask)    == "None"} {
                set DTMRI(scalars,ROI) None
                tk_messageBox -message $err
            }
        }
    }    

}

#-------------------------------------------------------------------------------
# .PROC DTMRICreateEmptyVolume
# Just like DevCreateNewCopiedVolume, but uses a Tensor node
# to copy parameters from instead of a volume node
# Used for scalar output from DTMRI math calculations.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRICreateEmptyVolume {OrigId {Description ""} { VolName ""}} {
    global Volume Tensor

    # Create the node (vtkMrmlVolumeNode class)
    set newvol [MainMrmlAddNode Volume]
    $newvol Copy Tensor($OrigId,node)
    
    # Set the Description and Name
    if {$Description != ""} {
        $newvol SetDescription $Description 
    }
    if {$VolName != ""} {
        $newvol SetName $VolName
    }

    # Create the volume (vtkMrmlDataVolume class)
    set n [$newvol GetID]
    MainVolumesCreate $n

    # This updates all the buttons to say that the
    # Volume List has changed.
    MainUpdateMRML

    return $n
}

#-------------------------------------------------------------------------------
# .PROC DTMRIDoMath
# Called to compute a scalar vol from DTMRIs
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIDoMath {{operation ""}} {
    global DTMRI Gui Tensor


    # if this was called from user input GUI menu
    if {$operation == ""} {
        set operation $DTMRI(scalars,operation) 
    }

    # validate user input
    if {[ValidateFloat $DTMRI(scalars,scaleFactor)] != "1"} {
        tk_messageBox -message \
            "Please enter a number for the scale factor."
        # reset default
        set DTMRI(scalars,scaleFactor) 1000
        return
    }

    # should use DevCreateNewCopiedVolume if have a vol node
    # to copy...
    set t $Tensor(activeID) 
    if {$t == "" || $t == $Tensor(idNone)} {
    tk_messageBox -message \
        "Please select an input DTMRI volume (Active DTMRI)"
        return
    }
    set name [Tensor($t,node) GetName]
    set name ${operation}_$name
    set description "$operation volume derived from DTMRI volume $name"
    set v [DTMRICreateEmptyVolume $t $description $name]

    # find input
    set mode $DTMRI(scalars,ROI)
    
    switch $mode {
        "None" {
            set input [Tensor($t,data) GetOutput]
        }
        "Threshold" {
            set input [DTMRI(vtk,thresh,mask) GetOutput]
        }
        "Mask" {
            set input [DTMRI(vtk,mask,mask) GetOutput]
        }
    }

    #Set up proper scale factor
    #Map result between 1 - 1000
    set rangexx [[[$input GetPointData] GetTensors] GetRange 0]
    set rangeyy [[[$input GetPointData] GetTensors] GetRange 4]
    set rangezz [[[$input GetPointData] GetTensors] GetRange 8]
    
    set maxTrace [expr [lindex $rangexx 1] + [lindex $rangeyy 1] + [lindex $rangezz 1]]
    
    puts "Running oper: $operation"
    puts "Max Trace: $maxTrace"
    
    switch -regexp -- $operation {
        {^(Trace|Determinant|D11|D22|D33|MaxEigenvalue|MiddleEigenvalue|MinEigenvalue)$} {
            set DTMRI(scalars,scaleFactor) [expr 1000.0 / $maxTrace]
        }
        {^(RelativeAnisotropy|FractionalAnisotropy|LinearMeasure|PlanarMeasure|SphericalMeasure|ColorByOrientation)$} {
            set DTMRI(scalars,scaleFactor) 1000
        }
    }
    
    puts "DTMR: scale factor $DTMRI(scalars,scaleFactor)"

    # create vtk object to do the operation
    vtkTensorMathematics math
    math SetScaleFactor $DTMRI(scalars,scaleFactor)
    math SetInput 0 $input
    math SetInput 1 $input
    math SetOperationTo$operation
    math AddObserver StartEvent MainStartProgress
    math AddObserver ProgressEvent "MainShowProgress math"
    math AddObserver EndEvent MainEndProgress
    set Gui(progressText) "Creating Volume $operation"

    # put the filter output into a slicer volume
    math Update
    #puts [[math GetOutput] Print]
    Volume($v,vol) SetImageData [math GetOutput]
    MainVolumesUpdate $v
    # tell the node what type of data so MRML file will be okay
    Volume($v,node) SetScalarType [[math GetOutput] GetScalarType]


    math SetInput 0 ""    
    math SetInput 1 ""
    # this is to disconnect the pipeline
    # this object hangs around, so try this trick from Editor.tcl:
    math SetOutput ""
    math Delete
    
    # reset blue bar text
    set Gui(progressText) ""

    # display this volume so the user knows something happened
    MainSlicesSetVolumeAll Back $v
    RenderAll
}


################################################################
#  Procedures to set up pipelines and create/modify vtk objects.
#  TODO: try to create objects only if needed!
################################################################


#-------------------------------------------------------------------------------
# .PROC DTMRIApplyVisualizationParameters
#  For interaction with pipeline under advanced tab.
#  Apply all GUI parameters into our vtk objects.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIApplyVisualizationParameters {} {
    global DTMRI

    # this code actually makes a bunch of calls like the following:
    # DTMRI(vtk,axes) SetScaleFactor $DTMRI(vtk,axes,scaleFactor)
    # DTMRI(vtk,tubeAxes) SetRadius $DTMRI(vtk,tubeAxes,radius)
    # DTMRI(vtk,glyphs) SetClampScaling 1
    # we can't do calls like MyObject MyVariableOn now

    # our naming convention is:
    # DTMRI(vtk,object)  is the name of the object
    # paramName is the name of the parameter
    # $DTMRI(vtk,object,paramName) is the value 

    # Lauren we need to validate too!!!!!!!!
    #  too bad vtk can't return a string type desrciptor...

    # loop through all vtk objects
    #------------------------------------
    foreach o $DTMRI(vtkObjectList) {

        # loop through all parameters of the object
        #------------------------------------
        foreach p $DTMRI(vtkPropertyList,$o) {

            # value of the parameter is $DTMRI(vtk,$o,$p)
            #------------------------------------
            set value $DTMRI(vtk,$o,$p)
            
            # Actually set the value appropriately in the vtk object
            #------------------------------------    

            # first capitalize the parameter name
            set param [Cap $p]
            
            # MyObject SetMyParameter $value    
            # handle the case in which value is a list with an eval 
            # this puts it into the correct format for feeding to vtk
            eval {DTMRI(vtk,$o) Set$param} $value
        }
    }

}

#-------------------------------------------------------------------------------
# .PROC DTMRIDeleteVTKObject
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIDeleteVTKObject {object} {
    global DTMRI

    # delete the object
    #------------------------------------
    DTMRI(vtk,$object) Delete

    # rm from list for updating of its variables by user
    #------------------------------------
    set i [lsearch $DTMRI(vtkObjectList) $object]
    set DTMRI(vtkObjectList) [lreplace $DTMRI(vtkObjectList) $i $i]

    # kill list of its variables
    #------------------------------------
    unset DTMRI(vtkPropertyList,$object) 
}

#-------------------------------------------------------------------------------
# .PROC DTMRIMakeVTKObject
#  Wrapper for vtk object creation.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIMakeVTKObject {class object} {
    global DTMRI

    # make the object
    #------------------------------------
    $class DTMRI(vtk,$object)

    # save on list for updating of its variables by user
    #------------------------------------
    lappend DTMRI(vtkObjectList) $object

    # initialize list of its variables
    #------------------------------------
    set DTMRI(vtkPropertyList,$object) ""
}

#-------------------------------------------------------------------------------
# .PROC DTMRIAddObjectProperty
#  Initialize vtk object access: saves object's property on list
#  for automatic GUI creation so user can change the property.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIAddObjectProperty {object parameter value type desc} {
    global DTMRI

    # create tcl variables of the form:
    #set DTMRI(vtk,tubeAxes,numberOfSides) 6
    #set DTMRI(vtk,tubeAxes,numberOfSides,type) int
    #set DTMRI(vtk,tubeAxes,numberOfSides,description) 
    #lappend DTMRI(vtkPropertyList,tubeAxes) numberOfSides 


    # make tcl variable and save its attributes (type, desc)
    #------------------------------------
    set param [Uncap $parameter]
    set DTMRI(vtk,$object,$param) $value
    set DTMRI(vtk,$object,$param,type) $type
    set DTMRI(vtk,$object,$param,description) $desc

    # save on list for updating variable by user
    #------------------------------------
    lappend DTMRI(vtkPropertyList,$object) $param
    
}

#-------------------------------------------------------------------------------
# .PROC DTMRIBuildVTK
# Called automatically by the slicer program.
# builds pipelines.
# See also DTMRIUpdate for pipeline use.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIBuildVTK {} {
    global DTMRI Module

    # Lauren: maybe this module should kill its objects on exit.
    # We must be hogging a ton of memory all over the slicer.
    # So possibly build (some) VTK upon entering module.

    #---------------------------------------------------------------
    # coordinate system actor (also called "Csys" and "gyro" 
    # in other modules).  Used for user interaction with hyperstreamlines
    #---------------------------------------------------------------
    #CsysCreate DTMRI coordinateAxesTool -1 -1 -1

    #---------------------------------------------------------------
    # Pipeline for preprocessing of glyphs
    #---------------------------------------------------------------

    # objects for thresholding before glyph display
    #------------------------------------


    #---------------------------------------------------------------
    # Pipeline for display of DTMRIs over 2D slice
    #---------------------------------------------------------------
    
    # Lauren how should reformatting be hooked into regular
    # slicer slice reformatting?  Ideally want to follow
    # the 3 slices.
    foreach plane "0 1 2" {
    DTMRIMakeVTKObject vtkImageReformat reformat$plane
    }

    # compute scalar data for thresholding
    set object thresh,math
    DTMRIMakeVTKObject vtkTensorMathematics $object
    DTMRIAddObjectProperty $object ExtractEigenvalues 1 bool {Extract Eigenvalues}

    # threshold the scalar data to produce binary mask 
    set object thresh,threshold
    #DTMRIMakeVTKObject vtkImageThresholdBeyond $object
    DTMRIMakeVTKObject vtkImageThreshold $object
    DTMRI(vtk,$object) SetInValue       1
    DTMRI(vtk,$object) SetOutValue      0
    DTMRI(vtk,$object) SetReplaceIn     1
    DTMRI(vtk,$object) SetReplaceOut    1
    DTMRI(vtk,$object) SetInput \
        [DTMRI(vtk,thresh,math) GetOutput]

    # convert the mask to unsigned char
    # Lauren it would be better to have the threshold filter do this
    set object thresh,cast
    DTMRIMakeVTKObject vtkImageCast $object
    DTMRI(vtk,$object) SetOutputScalarTypeToUnsignedChar    
    DTMRI(vtk,$object) SetInput \
        [DTMRI(vtk,thresh,threshold) GetOutput]

    # mask the DTMRIs 
    set object thresh,mask
    DTMRIMakeVTKObject vtkTensorMask $object
    #DTMRI(vtk,$object) SetMaskInput \
    #    [DTMRI(vtk,thresh,threshold) GetOutput]
    DTMRI(vtk,$object) SetMaskInput \
        [DTMRI(vtk,thresh,cast) GetOutput]

    # objects for masking before glyph display
    #------------------------------------

    # produce binary mask from the input mask labelmap
    set object mask,threshold
    #DTMRIMakeVTKObject vtkImageThresholdBeyond $object
    DTMRIMakeVTKObject vtkImageThreshold $object
    DTMRI(vtk,$object) SetInValue       1
    DTMRI(vtk,$object) SetOutValue      0
    DTMRI(vtk,$object) SetReplaceIn     1
    DTMRI(vtk,$object) SetReplaceOut    1

    # convert the mask to short
    # (use this most probable input type to try to avoid data copy)
    set object mask,cast
    DTMRIMakeVTKObject vtkImageCast $object
    DTMRI(vtk,$object) SetOutputScalarTypeToShort    
    DTMRI(vtk,$object) SetInput \
        [DTMRI(vtk,mask,threshold) GetOutput]

    # mask the DTMRIs 
    set object mask,mask
    DTMRIMakeVTKObject vtkTensorMask $object
    DTMRI(vtk,$object) SetMaskInput \
        [DTMRI(vtk,mask,cast) GetOutput]

    #---------------------------------------------------------------
    # Pipeline for display of glyphs
    #---------------------------------------------------------------

    # User interaction objects
    #------------------------------------
    # Lauren: doing this like Endoscopic (this vs PointPicker?)
    set object picker
    DTMRIMakeVTKObject vtkCellPicker $object
    DTMRIAddObjectProperty $object Tolerance 0.001 float {Pick Tolerance}

    # Lauren test by displaying picked point
    #DTMRI(vtk,picker) SetEndPickMethod "annotatePick DTMRI(vtk,picker)"
    vtkTextMapper textMapper
    if {[info commands vtkTextProperty] != ""} {
        [textMapper GetTextProperty] SetFontFamilyToArial
        [textMapper GetTextProperty] SetFontSize 20
        [textMapper GetTextProperty] BoldOn
        [textMapper GetTextProperty] ShadowOn
    } else {
        textMapper SetFontFamilyToArial
        textMapper SetFontSize 20
        textMapper BoldOn
        textMapper ShadowOn
    }
    vtkActor2D textActor
    textActor VisibilityOff
    textActor SetMapper textMapper
    [textActor GetProperty] SetColor 1 0 0
    viewRen AddActor2D textActor

    # objects for creation of polydata glyphs
    #------------------------------------

    # Axes
    set object glyphs,axes
    DTMRIMakeVTKObject vtkAxes $object
    DTMRIAddObjectProperty $object ScaleFactor 1 float {Scale Factor}
    
    # too slow: maybe useful for nice photos
    #set object glyphs,tubeAxes
    #DTMRIMakeVTKObject vtkTubeFilter $object
    #DTMRI(vtk,$object) SetInput [DTMRI(vtk,glyphs,axes) GetOutput]
    #DTMRIAddObjectProperty $object Radius 0.1 float {Radius}
    #DTMRIAddObjectProperty $object NumberOfSides 6 int \
    #    {Number Of Sides}

    # One line
    set object glyphs,line
    DTMRIMakeVTKObject vtkLineSource $object
    DTMRIAddObjectProperty $object Resolution 10 int {Resolution}
    #DTMRI(vtk,$object) SetPoint1 0 0 0
    # use a stick that points both ways, not a vector from the origin!
    DTMRI(vtk,$object) SetPoint1 -1 0 0
    DTMRI(vtk,$object) SetPoint2 1 0 0
    
    # too slow: maybe useful for nice photos
    #set object glyphs,tubeLine
    #DTMRIMakeVTKObject vtkTubeFilter $object
    #DTMRI(vtk,$object) SetInput [DTMRI(vtk,glyphs,line) GetOutput]
    #DTMRIAddObjectProperty $object Radius 0.1 float {Radius}
    #DTMRIAddObjectProperty $object NumberOfSides 6 int \
    #    {Number Of Sides}

    # Ellipsoids
    set object glyphs,sphere
    DTMRIMakeVTKObject vtkSphereSource  $object
    #DTMRIAddObjectProperty $object ThetaResolution 1 int ThetaResolution
    #DTMRIAddObjectProperty $object PhiResolution 1 int PhiResolution
    DTMRIAddObjectProperty $object ThetaResolution 12 int ThetaResolution
    DTMRIAddObjectProperty $object PhiResolution 12 int PhiResolution

    # Boxes
    set object glyphs,box
    DTMRIMakeVTKObject vtkCubeSource  $object

    # objects for placement of glyphs in dataset
    #------------------------------------
    set object glyphs
    foreach plane "0 1 2" {
    #DTMRIMakeVTKObject vtkDTMRIGlyph $object
    DTMRIMakeVTKObject vtkInteractiveTensorGlyph $object$plane
    DTMRI(vtk,glyphs$plane) SetInput ""
    #DTMRI(vtk,glyphs$plane) SetSource [DTMRI(vtk,glyphs,axes) GetOutput]
    #DTMRI(vtk,glyphs$plane) SetSource [DTMRI(vtk,glyphs,sphere) GetOutput]
    #DTMRIAddObjectProperty $object ScaleFactor 1 float {Scale Factor}
    DTMRIAddObjectProperty $object$plane ScaleFactor 1000 float {Scale Factor}
    DTMRIAddObjectProperty $object$plane ClampScaling 0 bool {Clamp Scaling}
    DTMRIAddObjectProperty $object$plane ExtractEigenvalues 1 bool {Extract Eigenvalues}
    DTMRI(vtk,$object$plane) AddObserver StartEvent MainStartProgress
    DTMRI(vtk,$object$plane) AddObserver ProgressEvent "MainShowProgress DTMRI(vtk,$object$plane)"
    DTMRI(vtk,$object$plane) AddObserver EndEvent MainEndProgress
    }
    
    set object glyphs,trans
    DTMRIMakeVTKObject vtkTransform $object
    
    #poly data append to join glyphs from the 3 slice planes
    set object glyphs,append
    DTMRIMakeVTKObject vtkAppendPolyData $object
    DTMRI(vtk,$object) UserManagedInputsOn
    
    # poly data normals filter cleans up polydata for nice display
    # use this for ellipses/boxes only
    #------------------------------------
    # very slow
    set object glyphs,normals
    DTMRIMakeVTKObject vtkPolyDataNormals $object
    DTMRI(vtk,$object) SetInput [DTMRI(vtk,glyphs,append) GetOutput]

    # Display of DTMRI glyphs: LUT and Mapper
    #------------------------------------
    set object glyphs,lut
    #DTMRIMakeVTKObject vtkLogLookupTable $object
    DTMRIMakeVTKObject vtkLookupTable $object
    DTMRIAddObjectProperty $object HueRange \
        {.6667 0.0} float {Hue Range}

    # mapper
    set object glyphs,mapper
    DTMRIMakeVTKObject vtkPolyDataMapper $object
    #Raul
    DTMRI(vtk,glyphs,mapper) SetInput [DTMRI(vtk,glyphs,append) GetOutput]
    #DTMRI(vtk,glyphs,mapper) SetInput [DTMRI(vtk,glyphs,normals) GetOutput]
    DTMRI(vtk,glyphs,mapper) SetLookupTable DTMRI(vtk,glyphs,lut)
    DTMRIAddObjectProperty $object ImmediateModeRendering \
        1 bool {Immediate Mode Rendering}    

    # Display of DTMRI glyphs: Actor
    #------------------------------------
    set object glyphs,actor
    #DTMRIMakeVTKObject vtkActor $object
    DTMRIMakeVTKObject vtkLODActor $object
    DTMRI(vtk,glyphs,actor) SetMapper DTMRI(vtk,glyphs,mapper)
    # intermediate level of detail produces visible points with 10
    [DTMRI(vtk,glyphs,actor) GetProperty] SetPointSize 10
    
    [DTMRI(vtk,glyphs,actor) GetProperty] SetAmbient 1
    [DTMRI(vtk,glyphs,actor) GetProperty] SetDiffuse .2
    [DTMRI(vtk,glyphs,actor) GetProperty] SetSpecular .4

    # Scalar bar actor
    #------------------------------------
    set object scalarBar,actor
    DTMRIMakeVTKObject vtkScalarBarActor $object
    DTMRI(vtk,scalarBar,actor) SetLookupTable DTMRI(vtk,glyphs,lut)
    viewRen AddProp DTMRI(vtk,scalarBar,actor)
    DTMRI(vtk,scalarBar,actor) VisibilityOff

    #---------------------------------------------------------------
    # Pipeline for display of tractography
    #---------------------------------------------------------------
    vtkMultipleStreamlineController DTMRI(vtk,streamlineControl)
    #DTMRI(vtk,streamlineControl) DebugOn
    # give it the renderers in which we display streamlines
    vtkCollection DTMRI(vtk,renderers)
    foreach r $Module(Renderers) {
        DTMRI(vtk,renderers) AddItem $r
    }
    DTMRI(vtk,streamlineControl) SetInputRenderers DTMRI(vtk,renderers)
    # This will be the input to the streamline controller. It lets us merge 
    # scalars from various datasets with the input tensor field
    vtkMergeFilter DTMRI(vtk,streamline,merge)

    # these are example objects used in creation of hyperstreamlines
    set streamline "streamlineControl,vtkHyperStreamlinePoints"
    vtkHyperStreamlinePoints DTMRI(vtk,$streamline) 
    DTMRI(vtk,streamlineControl) SetVtkHyperStreamlinePointsSettings \
        DTMRI(vtk,$streamline)
    set streamline "streamlineControl,vtkPreciseHyperStreamlinePoints"
    vtkPreciseHyperStreamlinePoints DTMRI(vtk,$streamline)
    DTMRI(vtk,streamlineControl) SetVtkPreciseHyperStreamlinePointsSettings \
        DTMRI(vtk,$streamline)
    


    #---------------------------------------------------------------
    # Pipeline for BSpline tractography (moved from proc DTMRIInit)
    #---------------------------------------------------------------

    DTMRIMakeVTKObject vtkTensorImplicitFunctionToFunctionSet itf
    set DTMRI(vtk,BSpline,init) 0
    set DTMRI(vtk,BSpline,data) 0
    
    if {[info command vtkITKBSplineImageFilter] == ""} {
        DevErrorWindow "DTMRI\nERROR: vtkITKBSplineImageFilter does not exist, cannot use bspline filter"
    }
    for {set i 0} {$i < 6} {incr i 1} {
        DTMRIMakeVTKObject vtkBSplineInterpolateImageFunction impComp($i)
        DTMRI(vtk,itf) AddImplicitFunction DTMRI(vtk,impComp($i)) $i
        if {[info command vtkITKBSplineImageFilter] != ""} {
            DTMRIMakeVTKObject vtkITKBSplineImageFilter bspline($i)
        } 
        DTMRIMakeVTKObject vtkExtractTensorComponents extractor($i)
        DTMRI(vtk,extractor($i)) PassTensorsToOutputOff
        DTMRI(vtk,extractor($i)) ExtractScalarsOn
        DTMRI(vtk,extractor($i)) ExtractVectorsOff
        DTMRI(vtk,extractor($i)) ExtractNormalsOff
        DTMRI(vtk,extractor($i)) ExtractTCoordsOff
        DTMRI(vtk,extractor($i)) ScalarIsComponent
    }
    
    DTMRI(vtk,extractor(0)) SetScalarComponents 0 0
    DTMRI(vtk,extractor(1)) SetScalarComponents 0 1
    DTMRI(vtk,extractor(2)) SetScalarComponents 0 2
    DTMRI(vtk,extractor(3)) SetScalarComponents 1 1
    DTMRI(vtk,extractor(4)) SetScalarComponents 1 2
    DTMRI(vtk,extractor(5)) SetScalarComponents 2 2
    
    DTMRIMakeVTKObject vtkRungeKutta45 rk45
    DTMRIMakeVTKObject vtkRungeKutta4 rk4
    DTMRIMakeVTKObject vtkRungeKutta2 rk2
    
    DTMRI(vtk,rk45) SetFunctionSet DTMRI(vtk,itf)
    DTMRI(vtk,rk4) SetFunctionSet DTMRI(vtk,itf)
    DTMRI(vtk,rk2) SetFunctionSet DTMRI(vtk,itf)
    
    set DTMRI(vtk,ivps) DTMRI(vtk,rk4)
    


    # Apply all settings from tcl variables that were
    # created above using calls to DTMRIAddObjectProperty
    #------------------------------------
    DTMRIApplyVisualizationParameters

}

################################################################
# procedures for converting volumes into DTMRIs.
# TODO: this should happen automatically and be in MRML
################################################################

#-------------------------------------------------------------------------------
# .PROC ConvertVolumeToTensors
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ConvertVolumeToTensors {} {
    global DTMRI Volume Tensor

    set v $Volume(activeID)
    if {$v == "" || $v == $Volume(idNone)} {
        puts "Can't create DTMRIs from None volume"
        return
    }

    # DTMRI creation filter
    vtkImageDiffusionTensor DTMRI
    DTMRI SetInputScaleFactor 100

    if {[info exists DTMRI(selectedpattern)]} {
        
        set DTMRI(convert,numberOfGradients) [lindex $DTMRI($DTMRI(selectedpattern),parameters) 0]
        set DTMRI(convert,firstGradientImage) [lindex $DTMRI($DTMRI(selectedpattern),parameters) 1]
        set DTMRI(convert,lastGradientImage) [lindex $DTMRI($DTMRI(selectedpattern),parameters) 2]
        set DTMRI(convert,firstNoGradientImage) [lindex $DTMRI($DTMRI(selectedpattern),parameters) 3]
        set DTMRI(convert,lastNoGradientImage) [lindex $DTMRI($DTMRI(selectedpattern),parameters) 4]
        set DTMRI(convert,lebihan) [lindex $DTMRI($DTMRI(selectedpattern),parameters) 5]
        set DTMRI(convert,gradients) [lindex $DTMRI($DTMRI(selectedpattern),parameters) 6]
        set DTMRI(convert,order) [lindex $DTMRI($DTMRI(selectedpattern),parameters) 7]
        
        #Set b-factor
        DTMRI SetB $DTMRI(convert,lebihan)
        
    } else {
        DevErrorWindow "Please select a protocol"
        DTMRI Delete
        return
        
    }

# define if the conversion is volume interleaved or slice interleaved depending on the pattern


    # setup - these are now globals linked with GUI
    #set slicePeriod 8
    #set offsetsGradient "0 1 2 3 4 5"
    #set offsetsNoGradient "6 7"
    #set numberOfGradientImages 6
    #set numberOfNoGradientImages 2
    set count 0
    for {set i $DTMRI(convert,firstGradientImage)} \
            {$i  <= $DTMRI(convert,lastGradientImage) } \
            {incr i} {
        # 0-based offsets, so subtract 1
        lappend offsetsGradient [expr $i -1]
        incr count
    }
    puts $offsetsGradient
    set numberOfGradientImages $count
    set count 0
    for {set i $DTMRI(convert,firstNoGradientImage)} \
            {$i  <= $DTMRI(convert,lastNoGradientImage) } \
            {incr i} {
        # 0-based offsets, so subtract 1
        lappend offsetsNoGradient [expr $i -1]
        incr count
    }
    puts $offsetsNoGradient
    set numberOfNoGradientImages $count

    set slicePeriod \
    [expr $numberOfGradientImages+$numberOfNoGradientImages]
    
    set numberOfGradientImages $DTMRI(convert,numberOfGradients) 
    DTMRI SetNumberOfGradients $numberOfGradientImages

    #puts $offsetsGradient 
    #puts $offsetsNoGradient

    for {set i 0} {$i < $DTMRI(convert,numberOfGradients)} {incr i} {
    #    eval {DTMRI SetDiffusionGradient $i} [lindex DTMRI(convert,gradients) $i]
        eval {DTMRI SetDiffusionGradient $i} [lindex $DTMRI(convert,gradients) $i]
    }

    # volume we use for input
    set input [Volume($v,vol) GetOutput]

    # transform gradient directions to make DTMRIs in ijk
    vtkTransform trans    
    puts "If not phase-freq flipped, swapping x and y in gradient directions"
    set swap [Volume($v,node) GetFrequencyPhaseSwap]
    set scanorder [Volume($v,node) GetScanOrder]
    
      
    if {$swap == 0} {    
        # Gunnar Farneback, April 6, 2004
        #
        # Apparently nobody understands all the involved coordinate
        # systems well enough to actually know how the gradient
        # directions should be transformed. This piece of code is
        # based on the hypothesis that the transformation matrices
        # only need to depend on the scan order and that the values
        # can be determined experimentally. It is perfectly possible
        # that this may break from changes elsewhere.
        #
        # If somebody reading this does know how to properly do these
        # transforms, please replace this code with something better.
        #
        # So far IS and PA have been experimentally verified.
        # SI is hypothesized to be the same as IS.
        # AP is hypothesized to be the same as PA.

        puts $scanorder
        switch $scanorder {
            "SI" -
            "IS" {
            set elements "\
                                    {0 1 0 0}  \
                                    {1 0 0 0}  \
                                    {0 0 -1 0}  \
                                    {0 0 0 1}  "
            }
            "AP" -
            "PA" {
            set elements "\
                                    {0 1 0 0}  \
                                    {-1 0 0 0}  \
                                    {0 0 -1 0}  \
                                    {0 0 0 1}  "
            }
            default {
            set elements "\
                                    {0 1 0 0}  \
                                    {1 0 0 0}  \
                                    {0 0 1 0}  \
                                    {0 0 0 1}  "
            }
        }

        set rows {0 1 2 3}
        set cols {0 1 2 3}    
        foreach row $rows {
            foreach col $cols {
                [trans GetMatrix] SetElement $row $col \
                    [lindex [lindex $elements $row] $col]
            }
        }    
    } else { 
        puts "Creating DTMRIs with -y for vtk compliance"
        trans Scale 1 -1 1
    }

    #Hardcode specific parameters for MOSAIC. Experimental.
    if {$DTMRI(convert,order) == "MOSAIC"} {
      DTMRI SetInputScaleFactor 1
      DTMRI SetAlpha 50
      set scanorder "IS"
      trans Identity
      trans Scale 1 1 -1
      foreach plane {0 1 2} {
        DTMRI(vtk,glyphs$plane) SetScaleFactor 2000
      }
    }
    
    DTMRI SetTransform trans
    trans Delete

    #check if input correct

    set dimz [lindex [$input GetDimensions] 2]
    set rest [expr $dimz%$slicePeriod]
   
   if {$rest != 0 && [lindex $DTMRI($DTMRI(selectedpattern),parameters) 7] == "VOLUME"} {
       DevErrorWindow "Check your Input Data.\n Not enough number of slices"
       DTMRI Delete
       return
   }

  if {$DTMRI(convert,order) == "MOSAIC"} {
    #Build list of DICOM files
    set numFiles [Volume($v,node) GetNumberOfDICOMFiles]
    for {set k 0} {$k < $numFiles} {incr k} {
      lappend filesList [Volume($v,node) GetDICOMFileName $k]
    }
    set sortList [lsort -dictionary $filesList]
    
    set numElements [expr $numberOfNoGradientImages + $numberOfGradientImages]
    
    for {set k 0} {$k < $numElements} {incr k} {
      lappend mosaicIndx [lsearch -dictionary $filesList [lindex $sortList $k ]]
    }
    
    puts "$numberOfNoGradientImages"
    puts "$numberOfNoGradientImages"
    puts "Num Elements: $numElements"
    puts "Mosaic Indx: $mosaicIndx"
    
    
  }

        

    # produce input vols for DTMRI creation
    set inputNum 0
    set DTMRI(recalculate,gradientVolumes) ""
    foreach slice $offsetsGradient {
        vtkImageExtractSlices extract$slice
        extract$slice SetInput $input
        extract$slice SetModeTo$DTMRI(convert,order)
        extract$slice SetSliceOffset $slice
        extract$slice SetSlicePeriod $slicePeriod
        
        if {$DTMRI(convert,order) == "MOSAIC"} {
          extract$slice SetSliceOffset [lindex $mosaicIndx $slice]   
          extract$slice SetMosaicTiles $DTMRI(convert,mosaicTiles)
          extract$slice SetMosaicSlices $DTMRI(convert,mosaicSlices)
        }

        #puts "----------- slice $slice update --------"    
        extract$slice Update
        #puts [[extract$slice GetOutput] Print]

        # pass along in pipeline
        DTMRI SetDiffusionImage \
            $inputNum [extract$slice GetOutput]
        incr inputNum
        
        # put the filter output into a slicer volume
        # Lauren this should be optional
        # make a MRMLVolume for this output
        if {[expr $slice % 5] == 0 && $DTMRI(convert,makeDWIasVolume)==1} {
          set name [Volume($v,node) GetName]
          set description "$slice gradient volume derived from volume $name"
          set name gradient${slice}_$name
          if {$DTMRI(convert,order) == "MOSAIC"} {
            set id [DTMRICreateNewVolume [extract$slice GetOutput] $name $description $scanorder]
          } else {
            set id [DevCreateNewCopiedVolume $v $description $name]
            Volume($id,vol) SetImageData [extract$slice GetOutput]
          }
        
          # save id in case we recalculate the DTMRIs
          lappend DTMRI(recalculate,gradientVolumes) $id
          puts "created volume $id"
          # fix the image range in the node (less slices than the original)
          set extent [[Volume($id,vol) GetOutput] GetExtent]
          set range "[expr [lindex $extent 4] +1] [expr [lindex $extent 5] +1]"
          eval {Volume($id,node) SetImageRange} $range
          # recompute the matrices using this offset to center vol in the cube
          # for some reason this uses the wrong node spacing!
          # Lauren test 
          eval {Volume($id,node) SetSpacing} [Volume($id,node) GetSpacing]

          set order [Volume($id,node) GetScanOrder]
          puts "-------computing ras to ijk from scan order----"
          Volume($id,node) ComputeRasToIjkFromScanOrder $order

          # update slicer internals
          MainVolumesUpdate $id

          # Registration
          # put the new volume inside the same transform as the Original volume
          # by inserting it right after that volume in the mrml file
          set nitems [Mrml(dataTree) GetNumberOfItems]
          for {set widx 0} {$widx < $nitems} {incr widx} {
            if { [Mrml(dataTree) GetNthItem $widx] == "Volume($id,node)" } {
                break
            }
          }
          if { $widx < $nitems } {
            Mrml(dataTree) RemoveItem $widx
            Mrml(dataTree) InsertAfterItem Volume($v,node) Volume($id,node)
            MainUpdateMRML
         }
        
       }
        
    }
    # save ids in case we recalculate the DTMRIs
    set DTMRI(recalculate,noGradientVolumes) ""
    foreach slice $offsetsNoGradient {
        vtkImageExtractSlices extract$slice
        extract$slice SetInput $input
        extract$slice SetModeTo$DTMRI(convert,order)
        extract$slice SetSliceOffset $slice
        extract$slice SetSlicePeriod $slicePeriod
        
        if {$DTMRI(convert,order) == "MOSAIC"} {
          puts "[lindex $mosaicIndx $slice]"
          eval "extract$slice SetSliceOffset" [lindex $mosaicIndx $slice]     
          extract$slice SetMosaicTiles $DTMRI(convert,mosaicTiles)
          extract$slice SetMosaicSlices $DTMRI(convert,mosaicSlices)
        }
        #puts "----------- slice $slice update --------"    
        extract$slice Update


        # put the filter output into a slicer volume
        # Lauren this should be optional
        # make a MRMLVolume for this output
        if {[expr $slice % 2] == 0 && $DTMRI(convert,makeDWIasVolume)==1} {
          set name [Volume($v,node) GetName]
          set name noGradient${slice}_$name
          set description "$slice no gradient volume derived from volume $name"
          if {$DTMRI(convert,order) == "MOSAIC"} {
            set id [DTMRICreateNewVolume [extract$slice GetOutput] $name $description $scanorder]
          } else {
            set id [DevCreateNewCopiedVolume $v $description $name]
            Volume($id,vol) SetImageData [extract$slice GetOutput]
          }
        
          # save id in case we recalculate the DTMRIs
          lappend DTMRI(recalculate,noGradientVolumes) $id
          puts "created volume $id"
          # fix the image range in the node (less slices than the original)
          set extent [[Volume($id,vol) GetOutput] GetExtent]
          set range "[expr [lindex $extent 4] +1] [expr [lindex $extent 5] +1]"
          eval {Volume($id,node) SetImageRange} $range
          # recompute the matrices using this offset to center vol in the cube
          set order [Volume($id,node) GetScanOrder]
          Volume($id,node) ComputeRasToIjkFromScanOrder $order

          # update slicer internals
          MainVolumesUpdate $id

          # Registration
          # put the new volume inside the same transform as the Original volume
          # by inserting it right after that volume in the mrml file
          set nitems [Mrml(dataTree) GetNumberOfItems]
          for {set widx 0} {$widx < $nitems} {incr widx} {
            if { [Mrml(dataTree) GetNthItem $widx] == "Volume($id,node)" } {
                break
            }
          }
          if { $widx < $nitems } {
            Mrml(dataTree) RemoveItem $widx
            Mrml(dataTree) InsertAfterItem Volume($v,node) Volume($id,node)
            MainUpdateMRML
          }

          # display this volume so the user knows something happened
          MainSlicesSetVolumeAll Back $id
        }
    }

    # average the two slices of no gradient 
    # NOTE THIS WILL NOT WORK WITH MORE THAN 2
    if {$numberOfNoGradientImages > 1} {
      vtkImageMathematics math
      math SetOperationToAdd

      vtkImageData slicebase 
      slicebase DeepCopy [extract[lindex $offsetsNoGradient 0] GetOutput]
      
      for {set k 1} {$k < $numberOfNoGradientImages} {incr k} {
        set slicechange [extract[lindex $offsetsNoGradient $k] GetOutput]
        math SetInput 0 slicebase
        math SetInput 1 $slicechange
        math Update
        slicebase DeepCopy [math GetOutput]
      }
      slicebase Delete
      vtkImageMathematics math2
      math2 SetOperationToMultiplyByK
      math2 SetConstantK [expr 1.0 / $numberOfNoGradientImages]
      math2 SetInput 0 [math GetOutput]
      math2 Update
      
      # set the no diffusion input
      #DTMRI SetNoDiffusionImage [extract6 GetOutput]
      DTMRI SetNoDiffusionImage [math2 GetOutput]
      set baseline [math2 GetOutput]
            
      
    } else {
      set slice [lindex $offsetsNoGradient 0]
      DTMRI SetNoDiffusionImage [extract$slice GetOutput]
      set baseline [extract$slice GetOutput]
    }
    
    #Make a MRML node with BaseLine
     set name [Volume($v,node) GetName]
     set description "Baseline from volume $name"
     set name ${name}_Baseline
     if {$DTMRI(convert,order) == "MOSAIC"} {
        set id [DTMRICreateNewVolume $baseline $name $description $scanorder]
     } else {
        set id [DevCreateNewCopiedVolume $v $description $name]
        Volume($id,vol) SetImageData $baseline
     }
        
     puts "created volume $id"
     # fix the image range in the node (less slices than the original)
     set extent [[Volume($id,vol) GetOutput] GetExtent]
     set range "[expr [lindex $extent 4] +1] [expr [lindex $extent 5] +1]"
     eval {Volume($id,node) SetImageRange} $range
     # recompute the matrices using this offset to center vol in the cube
     # for some reason this uses the wrong node spacing!
     # Lauren test 
      eval {Volume($id,node) SetSpacing} [Volume($id,node) GetSpacing]
      set order [Volume($id,node) GetScanOrder]
      puts "-------computing ras to ijk from scan order----"
      Volume($id,node) ComputeRasToIjkFromScanOrder $order

      # update slicer internals
      MainVolumesUpdate $id

      # Registration
      # put the new volume inside the same transform as the Original volume
      # by inserting it right after that volume in the mrml file
      set nitems [Mrml(dataTree) GetNumberOfItems]
       for {set widx 0} {$widx < $nitems} {incr widx} {
         if { [Mrml(dataTree) GetNthItem $widx] == "Volume($id,node)" } {
             break
         }
       }
       if { $widx < $nitems } {
         Mrml(dataTree) RemoveItem $widx
         Mrml(dataTree) InsertAfterItem Volume($v,node) Volume($id,node)
         MainUpdateMRML
      }


    # average gradient images for display and checking mechanism. 
    # NOTE THIS WILL NOT WORK WITH MORE THAN 2
      vtkImageMathematics math_g
      math_g SetOperationToAdd

      vtkImageData slicebase
      slicebase DeepCopy [extract[lindex $offsetsGradient 0] GetOutput]
      for {set k 1} {$k < $numberOfGradientImages} {incr k} {
        set slicechange [extract[lindex $offsetsGradient $k] GetOutput]
        math_g SetInput 0 slicebase
        math_g SetInput 1 $slicechange
        math_g Update
        slicebase DeepCopy [math_g GetOutput]
      }
      slicebase Delete
      vtkImageMathematics math2_g
      math2_g SetOperationToMultiplyByK
      math2_g SetConstantK [expr 1.0 / $numberOfGradientImages]
      math2_g SetInput 0 [math_g GetOutput]
      math2_g Update
      
      set baseline [math2_g GetOutput]
 
    #Make a MRML node with BaseLine
     set name [Volume($v,node) GetName]
     set description "Average gradient from volume $name"
     set name ${name}_AvGradient
     if {$DTMRI(convert,order) == "MOSAIC"} {
        set id [DTMRICreateNewVolume $baseline $name $description $scanorder]
     } else {
        set id [DevCreateNewCopiedVolume $v $description $name]
        Volume($id,vol) SetImageData $baseline
     }
        
     puts "created volume $id"
     # fix the image range in the node (less slices than the original)
     set extent [[Volume($id,vol) GetOutput] GetExtent]
     set range "[expr [lindex $extent 4] +1] [expr [lindex $extent 5] +1]"
     eval {Volume($id,node) SetImageRange} $range
     # recompute the matrices using this offset to center vol in the cube
     # for some reason this uses the wrong node spacing!
     # Lauren test 
      eval {Volume($id,node) SetSpacing} [Volume($id,node) GetSpacing]
      set order [Volume($id,node) GetScanOrder]
      puts "-------computing ras to ijk from scan order----"
      Volume($id,node) ComputeRasToIjkFromScanOrder $order

      # update slicer internals
      MainVolumesUpdate $id

      # Registration
      # put the new volume inside the same transform as the Original volume
      # by inserting it right after that volume in the mrml file
      set nitems [Mrml(dataTree) GetNumberOfItems]
       for {set widx 0} {$widx < $nitems} {incr widx} {
         if { [Mrml(dataTree) GetNthItem $widx] == "Volume($id,node)" } {
             break
         }
       }
       if { $widx < $nitems } {
         Mrml(dataTree) RemoveItem $widx
         Mrml(dataTree) InsertAfterItem Volume($v,node) Volume($id,node)
         MainUpdateMRML
      }



    puts "3----------- DTMRI update --------"
    DTMRI DebugOn
    DTMRI Update
    puts "----------- after DTMRI update --------"


    # put output into a Tensor volume
    # Lauren if volumes and tensos are the same
    # this should be done like the above
    # Create the node (vtkMrmlVolumeNode class)
    set newvol [MainMrmlAddNode Volume Tensor]
    #Take the baseline as node to copy
    $newvol Copy Volume($id,node)
    $newvol SetDescription "DTMRI volume"
    $newvol SetName "[Volume($v,node) GetName]_Tensor"
    set n [$newvol GetID]

    puts "SPACING [$newvol GetSpacing] DIMS [$newvol GetDimensions] MAT [$newvol GetRasToIjkMatrix]"
    # fix the image range in the node (less slices than the original)
    set extent [[Volume($id,vol) GetOutput] GetExtent]
    set range "[expr [lindex $extent 4] +1] [expr [lindex $extent 5] +1]"
    eval {$newvol SetImageRange} $range
    # recompute the matrices using this offset to center vol in the cube
    set order [$newvol GetScanOrder]
    
    $newvol ComputeRasToIjkFromScanOrder $order
    
    puts "SPACING [$newvol GetSpacing] DIMS [$newvol GetDimensions] MAT [$newvol GetRasToIjkMatrix]"
    MainDataCreate Tensor $n Volume
    
    # Set the slicer object's image data to what we created
    DTMRI Update
    #Tensor($n,data) SetData [DTMRI GetOutput]
    Tensor($n,data) SetImageData [DTMRI GetOutput]

    # Registration
    # put the new tensor volume inside the same transform as the Original volume
    # by inserting it right after that volume in the mrml file
    set nitems [Mrml(dataTree) GetNumberOfItems]
    for {set widx 0} {$widx < $nitems} {incr widx} {
        if { [Mrml(dataTree) GetNthItem $widx] == "Tensor($n,node)" } {
            break
        }
    }
    if { $widx < $nitems } {
        Mrml(dataTree) RemoveItem $widx
        Mrml(dataTree) InsertAfterItem Volume($v,node) Tensor($n,node)
        MainUpdateMRML
    }
    
    # This updates all the buttons to say that the
    # Volume List has changed.
    MainUpdateMRML
    # If failed, then it's no longer in the idList
    if {[lsearch $Tensor(idList) $n] == -1} {
        puts "Lauren node doesn't exist, should unfreeze and fix volumes.tcltoo"
    } else {
        # Activate the new data object
        DTMRISetActive $n
    }


    # kill objects
    foreach slice $offsetsGradient {
        extract$slice SetOutput ""
        extract$slice Delete
    }
    foreach slice $offsetsNoGradient {
        extract$slice SetOutput ""
        extract$slice Delete
    }

    if {$numberOfNoGradientImages > 1} {
        math SetOutput ""
        math2 SetOutput ""
        math Delete
        math2 Delete
    }
    
    math_g SetOutput ""
    math2_g SetOutput ""
    math_g Delete
    math2_g Delete
    
    DTMRI SetOutput ""
    DTMRI Delete

    # display volume so the user knows something happened
    MainSlicesSetVolumeAll Back $id

    # display the new volume in the slices
    RenderSlices
}


proc DTMRICreateNewVolume {volume name desc scanOrder} {
  global Volume View
  
  set n [MainMrmlAddNode Volume]
  set id [$n GetID]
  MainVolumesCreate $id
  $n SetScanOrder $scanOrder     
  $n SetName $name
  $n SetDescription $desc
  set dim [$volume GetDimensions]
  eval "$n SetDimensions" [lindex $dim 0] [lindex $dim 1]
  eval "$n SetSpacing" [$volume GetSpacing]
  set extent [$volume GetExtent]
  set range "[expr [lindex $extent 4] +1] [expr [lindex $extent 5] +1]"
  eval {$n SetImageRange} $range
  $n ComputeRasToIjkFromScanOrder $scanOrder
  
  # get the pixel size, etc. from the data and set it in the node
  #[Volume($id,vol) GetOutput] DeepCopy $volume
  Volume($id,vol) SetImageData $volume
  MainUpdateMRML
  MainVolumesSetActive $id
  
  
  set fov 0
  for {set i 0} {$i < 2} {incr i} {
    set dim     [lindex [Volume($id,node) GetDimensions] $i]
    set spacing [lindex [Volume($id,node) GetSpacing] $i]
    set newfov     [expr $dim * $spacing]
    if { $newfov > $fov } {
       set fov $newfov
     }
  }
  set View(fov) $fov
  MainViewSetFov
  
  return $id

}



################################################################
# procedures for saving DTMRIs, streamlines, etc.
# TODO: some of this should happen automatically and be in MRML
################################################################

#-------------------------------------------------------------------------------
# .PROC DTMRIWriteStructuredPoints
# Dump DTMRIs to structured points file.  this ignores
# world to RAS, DTMRIs are just written in scaled ijk coordinate system.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRIWriteStructuredPoints {filename} {
    global DTMRI Tensor

    set t $Tensor(activeID)

    set filename [tk_getSaveFile -defaultextension ".vtk" -title "Save tensor as vtkstructurepoints"]
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


#-------------------------------------------------------------------------------
# .PROC DTMRISaveStreamlinesAsIJKPoints
# Save all points from the streamline paths as text files
# .ARGS
# int verbose default is 1 
# .END
#-------------------------------------------------------------------------------
proc DTMRISaveStreamlinesAsIJKPoints {{verbose "1"}} {
    
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

    # save the tracts
    DTMRI(vtk,streamlineControl) SaveStreamlinesAsTextFiles \
        $filename 

    # let user know something happened
    if {$verbose == "1"} {
        set msg "Finished writing tracts. The filenames are: $filename*.txt"
        tk_messageBox -message $msg
    }

} 


#-------------------------------------------------------------------------------
# .PROC DTMRISaveStreamlinesAsPolyLines
# Save all points from the streamline paths as polyline in a vtkfile
# .ARGS
# path subdir subdirectory to save the models in
# string name the filename prefix of each model
# int verbose default is 1 
# .END
#-------------------------------------------------------------------------------
proc DTMRISaveStreamlinesAsPolyLines {subdir name {verbose "1"}} {
    global DTMRI

    set thelist $DTMRI(vtk,streamline,idList)
    set thePoints ""
    set filename "NONE"
    
    set filename [tk_getSaveFile -defaultextension ".vtk" -title "Save Streamlines as polyline"]
    if { $filename == "" } {
        return
    }
    
    
    #Write streamlines to a vtkPolyData file with lines
    
    #1. Count total number of points
    set numpts 0
    foreach id $thelist {
        set streamln streamln,$id
        
        foreach dir {0 1} {
            set numpts [expr $numpts + [[DTMRI(vtk,$streamln) GetHyperStreamline$dir] GetNumberOfPoints]]
        }
    }
    
    #2. Fill point data and cell data
    vtkPolyData p
    vtkCellArray c
    vtkPoints pt
    
    pt SetNumberOfPoints $numpts
    
    #global id for cell
    set idcell 0
    #global id for points
    set idp 0
    foreach id $thelist {
        set streamln streamln,$id
        
        foreach dir {0 1} {
            set cellnumpts [[DTMRI(vtk,$streamln) GetHyperStreamline$dir] GetNumberOfPoints]
            c InsertNextCell $cellnumpts
            #Get transformation matrix: IJK -> RAS
            set matrix [DTMRI(vtk,$streamln,actor) GetUserMatrix]
            
            for {set i 0} {$i < $cellnumpts} {incr i} {
                set ijkpoint [[DTMRI(vtk,$streamln) GetHyperStreamline$dir] GetPoint $i]
                set raspoint [$matrix MultiplyPoint [lindex $ijkpoint 0] [lindex $ijkpoint 1] [lindex $ijkpoint 2] 1]
                #If we want to save points in ijk
                #eval "pt SetPoint $idp" [[DTMRI(vtk,$streamln) GetHyperStreamline$dir] GetPoint $i]
                
                #If we want to save points in ras
                pt SetPoint $idp [lindex $raspoint 0] [lindex $raspoint 1] [lindex $raspoint 2]
                
                c InsertCellPoint $idp
                incr idp
            
            }   
            incr idcell
        }
    }
    
    #3. Build polydata
    p SetLines c
    p SetPoints pt
    p Update
    
    
    #4. Write PolyData
    vtkPolyDataWriter w
    w SetFileName [file join $subdir $filename]  
    w SetInput p
    w SetFileTypeToASCII
    w Write 

    #5. Delete Objects
    w Delete
    p Delete
    c Delete
    pt Delete

    # let user know something happened
    if {$verbose == "1"} {
        set msg "Wrote streamlines as vtk files, last file was $filename"
        tk_messageBox -message $msg
    }


}

#-------------------------------------------------------------------------------
# .PROC DTMRISaveStreamlinesAsModel
# Save all streamlines as a vtk model(s).
# Each color is written as a separate model.
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRISaveStreamlinesAsModel {{verbose "1"}} {
    
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

    # save the models as well as a MRML file with their colors
    DTMRI(vtk,streamlineControl) SaveStreamlinesAsPolyData \
        $filename $modelname Mrml(colorTree)

    # let user know something happened
    if {$verbose == "1"} {
        set msg "Finished writing tracts and scene file. The filename is: $filename.xml"
        tk_messageBox -message $msg
    }

}



################################################################
#  Procedures that deal with coordinate systems
################################################################

#-------------------------------------------------------------------------------
# .PROC DTMRIGetScaledIjkCoordinatesFromWorldCoordinates
#
# Use our world to ijk matrix information to correct x,y,z.
# The streamline class doesn't know about the
# DTMRI actor's "UserMatrix" (actually implemented with two matrices
# in the glyph class).  We need to transform xyz by
# the inverse of this matrix (almost) so the streamline will start 
# from the right place in the DTMRIs.  The "almost" is because the 
# DTMRIs know about their spacing (vtkImageData) and so we must
# remove the spacing from this matrix.
#
#
# .ARGS
# int x x-coordinate of input world coordinates point 
# int y y-coord
# int z z-coord
# .END
#-------------------------------------------------------------------------------
proc DTMRIGetScaledIjkCoordinatesFromWorldCoordinates {x y z} {
    global DTMRI Tensor

    set t $Tensor(activeID)

    vtkTransform transform
    DTMRICalculateActorMatrix transform $t    
    transform Inverse
    set point [transform TransformPoint $x $y $z]
    transform Delete

    # check point is in bounds of the dataset
    set dims [[Tensor($t,data) GetOutput] GetDimensions]
    set space [[Tensor($t,data) GetOutput] GetSpacing]
    # return "-1 -1 -1" if out of bounds error 
    foreach d $dims s $space p $point {
        if {$p < 0} {
            set point "-1 -1 -1"
        } elseif {$p > [expr $d*$s]} {
            set point "-1 -1 -1"
        }
    }

    return $point
}

#-------------------------------------------------------------------------------
# .PROC DTMRICalculateActorMatrix
# Place the entire Tensor volume in world coordinates
# using this transform.  Uses world to IJk matrix but
# removes the spacing since the data/actor know about this.
# .ARGS
# vtkTransform transform the transform to modify
# int t the id of the DTMRI volume to calculate the matrix for
# .END
#-------------------------------------------------------------------------------
proc DTMRICalculateActorMatrix {transform t} {
    global Tensor
    # Grab the node whose data we want to position 
    set node Tensor($t,node)

    # the user matrix is either the reformat matrix
    # to place the slice, OR it needs to place the entire 
    # DTMRI volume.

    # In this procedure we calculate the second kind of matrix,
    # to place the whole volume.
    $transform Identity
    $transform PreMultiply

    # Get positioning information from the MRML node
    # world space (what you see in the viewer) to ijk (array) space
    $transform SetMatrix [$node GetWldToIjk]

    # now it's ijk to world
    $transform Inverse

    # the data knows its spacing already so remove it
    # (otherwise the actor would be stretched, ouch)
    scan [$node GetSpacing] "%g %g %g" res_x res_y res_z

    $transform Scale [expr 1.0 / $res_x] [expr 1.0 / $res_y] \
        [expr 1.0 / $res_z]
}


#-------------------------------------------------------------------------------
# .PROC DTMRICalculateIJKtoRASRotationMatrix
# 
#  The IJK to RAS matrix has two actions on the DTMRIs.
#  <p>
#  1.  Each DTMRI glyph must be placed at the (x,y,z) location
#  determined by the matrix.  This is analogous to setting the
#  reformat matrix as the actor's user matrix when placing 
#  scalar data.  However, actor matrices do not work here because
#  of number 2, next.
#  <p>
#  2.  Each DTMRI itself must be rotated from ijk to ras.  This
#  uses the ijk to ras matrix, but without any scaling or translation.
#  The DTMRIs are created in the ijk coordinate system so that 
#  diffusion-simulation filters and hyperstreamlines, which do not 
#  know about RAS or actor placement, can correctly handle the data.
#
#
#  <p> This procedure removes translation and scaling 
#  from a volume's ijk to ras matrix, and it returns
#  a rotation matrix that can act on each DTMRI.
#
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRICalculateIJKtoRASRotationMatrix {transform t} {
    global Volume Tensor

    # --------------------------------------------------------
    # Rotate DTMRIs to RAS  (actually to World space)
    # --------------------------------------------------------
    # We want the DTMRIs to be displayed in the RAS coordinate system

    # The upper left 3x3 part of this matrix is the rotation.
    # (It also has voxel scaling which we will remove.)
    # -------------------------------------
    #$transform SetMatrix [Tensor($t,node)  GetRasToIjk]
    $transform SetMatrix [Tensor($t,node)  GetWldToIjk]
    # Now it's ijk to ras
    $transform Inverse

    # Remove the voxel scaling from the matrix.
    # -------------------------------------
    scan [Tensor($t,node) GetSpacing] "%g %g %g" res_x res_y res_z

    # We want -y since vtk flips the y axis
    #puts "Not flipping y"
    #set res_y [expr -$res_y]
    $transform Scale [expr 1.0 / $res_x] [expr 1.0 / $res_y] \
    [expr 1.0 / $res_z]

    # Remove the translation part from the last column.
    # (This was in there to center the volume in the cube.)
    # -------------------------------------
    [$transform GetMatrix] SetElement 0 3 0
    [$transform GetMatrix] SetElement 1 3 0
    [$transform GetMatrix] SetElement 2 3 0
    # Set element (4,4) to 1: homogeneous point
    [$transform GetMatrix] SetElement 3 3 1

    # Now this matrix JUST does the rotation needed for ijk->ras.
    # -------------------------------------
    puts "-----------------------------------"
    puts [$transform Print]
    puts "-----------------------------------"

}


#-------------------------------------------------------------------------------
# .PROC DTMRI SetActive
# Set the active tensor on the menus, and make it input to the 
# tractography pipeline. (The glyph pipeline input is set up when 
# the glyph button is pressed, in the procedure DTMRIUpdate. It could
# be faster to set it up here also.)
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc DTMRISetActive {n} {
    global Tensor DTMRI

    # Call the procedure that puts this tensor on the menus
    MainDataSetActive Tensor $n

    # Make sure this tensor is the input to the glyph pipeline
    DTMRIUpdate

    # get the active ID (index into tensor list)
    set t $Tensor(activeID)

    # set up the tractography pipeline with both data and location
    # information from the active tensor dataset
    DTMRI(vtk,streamline,merge) SetTensors [Tensor($t,data) GetOutput]
    DTMRI(vtk,streamline,merge) SetGeometry [Tensor($t,data) GetOutput]
    DTMRI(vtk,streamline,merge) SetScalars [Tensor($t,data) GetOutput]
    DTMRI(vtk,streamline,merge) SetVectors [Tensor($t,data) GetOutput]
    DTMRI(vtk,streamline,merge) SetNormals [Tensor($t,data) GetOutput]
    DTMRI(vtk,streamline,merge) SetTCoords [Tensor($t,data) GetOutput]
    DTMRI(vtk,streamline,merge) Update
    DTMRI(vtk,streamlineControl) SetInputTensorField \
        [DTMRI(vtk,streamline,merge) GetOutput] 
 
    # set correct transformation from World coords to scaledIJK of the tensors
    vtkTransform transform
    DTMRICalculateActorMatrix transform $t    
    transform Inverse
    DTMRI(vtk,streamlineControl) SetWorldToTensorScaledIJK transform
    transform Delete    

    # start with solid colors since we can't be sure selected volume
    # is okay to color tracts with (i.e. may not have same size).
    # this also sets up the correct color for the first tract.
    DTMRIUpdateTractColorToSolid

    # initial setup of the streamline control object for the
    # type of streamline to create.
    DTMRIUpdateStreamlineSettings

#     # set up the BSpline tractography pipeline
#     set DTMRI(vtk,BSpline,data) 1
#     set DTMRI(vtk,BSpline,init) 1;
#     DTMRI(vtk,itf) SetDataBounds [Tensor($t,data) GetOutput]
#     #DTMRI(vtk,itf) SetDataBounds [DTMRI(vtk,streamline,merge) GetOutput]
#     for {set i 0} {$i < 6} {incr i} {
#         DTMRI(vtk,extractor($i)) SetInput [Tensor($t,data) GetOutput]
#         #DTMRI(vtk,extractor($i)) SetInput \
#         #    [DTMRI(vtk,streamline,merge) GetOutput]
#     }
#     for {set i 0} {$i < 6} {incr i} {
#         #DTMRI(vtk,extractor($i)) Update
#         DTMRI(vtk,bspline($i)) SetInput [DTMRI(vtk,extractor($i)) GetOutput]
#     }          
#     DTMRIUpdateBSplineOrder $DTMRI(stream,BSplineOrder)
#     for {set i 0} {$i < 6} {incr i} {
#         #DTMRI(vtk,bspline($i)) Update
#         DTMRI(vtk,impComp($i)) SetInput [DTMRI(vtk,bspline($i)) GetOutput]
#     }
}

