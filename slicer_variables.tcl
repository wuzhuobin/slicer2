
#
# Note: this local vars file overrides the default values in the
# launch.tcl and Scripts/cmaker.tcl scripts
# - use it to set your local environment and then your change won't 
#   be overwritten when those files are updated through CVS
# - ensure that you set your SLICER_HOME value 
#

# set up variables for the OS Builds, to facilitate the move to solaris9
# - solaris can be solaris8 or solaris9
set solaris "solaris8"
set linux "redhat7.3"
set darwin "Darwin"
set windows "Win32VC7"

## variables that are the same for all systems
set SLICER_DATA_ROOT ""

## set the SLICER_HOME directory to the one in which this script resides
set SLICER_HOME [file dirname [info script]]
puts "Set SLICER_HOME to $SLICER_HOME"

## system dependent variables
switch $tcl_platform(os) {
    "SunOS" {
        set env(BUILD) $solaris
        set VTK_DIR  $SLICER_HOME/Lib/$env(BUILD)/vtk/VTK-build-4.2.2
        set ITK_BINARY_PATH /projects/birn/itk/itk-1.2/itk-build
        # used for compilation
        set VTKSLICERBASE_BUILD_LIB $SLICER_HOME/Base/builds/$env(BUILD)/bin/vtkSlicerBase.so
        set VTKSLICERBASE_BUILD_TCL_LIB $SLICER_HOME/Base/builds/$env(BUILD)/bin/vtkSlicerBaseTCL.so
        set GENERATOR "Unix Makefiles"
        set COMPILER_PATH "/local/os/bin"
        set COMPILER "g++"
        set CMAKE cmake
        set MAKE "gmake -j15"
        # needed in launch.tcl
        set TCL_BIN_DIR $SLICER_HOME/Lib/$env(BUILD)/ActiveTcl8.4.2.0-solaris-sparc/bin
        set TCL_LIB_DIR $SLICER_HOME/Lib/$env(BUILD)/ActiveTcl8.4.2.0-solaris-sparc/lib
    }
    "Linux" {
        set env(BUILD) $linux
        set VTK_BINARY_PATH $SLICER_HOME/Lib/$env(BUILD)/vtk/VTK-build
        set VTK_DIR $VTK_BINARY_PATH
        set ITK_BINARY_PATH /home/pieper/downloads/itk/itk-build
        set VTKSLICERBASE_BUILD_LIB $SLICER_HOME/Base/builds/$env(BUILD)/bin/vtkSlicerBase.so
        set VTKSLICERBASE_BUILD_TCL_LIB $SLICER_HOME/Base/builds/$env(BUILD)/bin/vtkSlicerBaseTCL.so
        set GENERATOR "Unix Makefiles" 
        set COMPILER_PATH "/usr/bin"
        set COMPILER "g++"
        set CMAKE cmake
        set MAKE make
        # needed in launch.tcl
        set TCL_BIN_DIR $SLICER_HOME/Lib/$env(BUILD)/ActiveTcl/bin
        set TCL_LIB_DIR $SLICER_HOME/Lib/$env(BUILD)/ActiveTcl/lib
    }
    "Darwin" {
        set env(BUILD) $darwin
        set ITK_BINARY_PATH /Users/pieper/downloads/itk/itk-build
        set VTK_SRC_PATH /Users/pieper/downloads/vtk/vtk4.2/VTK-4.2.1
        set VTKSLICERBASE_BUILD_LIB $SLICER_HOME/Base/builds/$env(BUILD)/bin/vtkSlicerBase.dylib
        set VTKSLICERBASE_BUILD_TCL_LIB $SLICER_HOME/Base/builds/$env(BUILD)/bin/vtkSlicerBaseTCL.dylib
        set GENERATOR "Unix Makefiles" 
        set COMPILER_PATH "/usr/bin"
        set COMPILER "c++"
        set CMAKE cmake
        set MAKE make
        # needed in launch.tcl
        set TCL_BIN_DIR $SLICER_HOME/Lib/$env(BUILD)/ActiveTcl/bin
        set TCL_LIB_DIR $SLICER_HOME/Lib/$env(BUILD)/ActiveTcl/lib
    }
    default {
        # different windows machines say different things, so assume
        # that if it doesn't match above it must be windows
        # (VC7 is Visual C++ 7.0, also known as the .NET version)

        set env(BUILD) $windows
        set VTK_BINARY_PATH c:/downloads/vtk/VTK-4.2.5-build
        set VTK_DIR $VTK_BINARY_PATH
        set ITK_BINARY_PATH "c:/downloads/itk/InsightToolkit-1.4.0-build"
        set VTKSLICERBASE_BUILD_LIB $SLICER_HOME/Base/builds/$env(BUILD)/bin/debug/vtkSlicerBase.lib
        set VTKSLICERBASE_BUILD_TCL_LIB $SLICER_HOME/Base/builds/$env(BUILD)/bin/debug/vtkSlicerBaseTCL.lib
        set GENERATOR "Visual Studio 7" 
        set COMPILER_PATH "C:/Program Files/Microsoft Visual Studio .NET/Vc7/bin"
        set COMPILER "cl"
        set CMAKE "c:/Program Files/CMake/bin/cmake.exe"
        set MAKE make
        # needed in launch.tcl
        set TCL_BIN_DIR $SLICER_HOME/Lib/$env(BUILD)/ActiveTcl/bin
        set TCL_LIB_DIR $SLICER_HOME/Lib/$env(BUILD)/ActiveTcl/lib
    }
}
