#!/bin/sh
# the next line restarts using tclsh \
exec tclsh "$0" "$@"

################################################################################
#
# genlib.tcl
#
# generate the Lib directory with the needed components for slicer
# to build
#
# Steps:
# - pull code from anonymous cvs
# - configure (or cmake) with needed options
# - build for this platform
#
# Packages: cmake, tcl, itcl, ITK, VTK, blt, gsl
# 
# Usage:
#   genlib [options] [target]
#
# run genlib from the slicer directory where you want the packages to be build
# E.g. if you run /home/pieper/slicer2/Scripts/genlib.tcl on a redhat7.3
# machine it will create /home/pieper/slicer2/Lib/redhat7.3
#
# - sp - 2004-06-20
#

# set up the versions to check out
set cmakeTag "CMake-2-0-1"
set vtkTag "Slicer-2-4"
set itkTag "Slicer-2-4"
set tclTag "core-8-4-6"
set tkTag "core-8-4-6"
set itclTag "itcl-3-2-1"
set iwidgetsTag "iwidgets-4-0-1"
set bltTag "blt24z"
set gslTag "release-1-4"

# when using this on window, some things will have to be run from the cygwin terminal
set winMsg "Sorry, this isn't all automated for windows. Open a cygwin terminal and do the following:\n"



################################################################################
#
# simple command line argument parsing
#

proc Usage { {msg ""} } {
    global SLICER
    
    set msg "$msg\nusage: genlib \[options\] \[target\]"
    set msg "$msg\n  \[target\] is determined automatically if not specified"
    set msg "$msg\n  \[options\] is one of the following:"
    set msg "$msg\n   --help : prints this message and exits"
    set msg "$msg\n   --clean : delete the target first"
    puts stderr $msg
}

set GENLIB(clean) "false"
set strippedargs ""
set argc [llength $argv]
for {set i 0} {$i < $argc} {incr i} {
    set a [lindex $argv $i]
    switch -glob -- $a {
        "--clean" -
        "-f" {
            set GENLIB(clean) "true"
        }
        "--help" -
        "-h" {
            Usage
            exit 1
        }
        "-*" {
            Usage "unknown option $a\n"
            exit 1
        }
        default {
            lappend strippedargs $a
        }
    }
}
set argv $strippedargs
set argc [llength $argv]

if {$argc > 1 } {
    Usage
    exit 1
}


################################################################################
#
# Utilities:

proc runcmd {args} {
    puts "running: $args"

    # print the results line by line to provide feedback during long builds
    set fp [open "| $args |& cat" "r"]
    while { ![eof $fp] } {
        gets $fp line
        puts $line
    }
    set ret [catch "close $fp" res] 
    if { $ret } {
        puts stderr $res
        error $ret
    } 
}

################################################################################
# First, set up the directory
# - determine the location
# - determine the build
# 

# hack to work around lack of normalize option in older tcl
# set SLICER_HOME [file dirname [file dirname [file normalize [info script]]]]
set cwd [pwd]
cd [file dirname [info script]]
cd ..
set SLICER_HOME [pwd]
cd $cwd

#######
#
# Note: the local vars file, slicer2/slicer_variables.tcl, overrides the default values in this script
# - use it to set your local environment and then your change won't 
#   be overwritten when this file is updated
#
set localvarsfile $SLICER_HOME/slicer_variables.tcl
catch {set localvarsfile [file normalize $localvarsfile]}
if { [file exists $localvarsfile] } {
    puts "Sourcing $localvarsfile"
    source $localvarsfile
} else {
    puts "stderr: $localvarsfile not found - use this file to set up your build"
    exit 1
}


if { $GENLIB(clean) } {
    file delete -force $SLICER_LIB
}

if { ![file exists $SLICER_LIB] } {
    file mkdir $SLICER_LIB
}

# set up cross platform files to check for existence
switch $tcl_platform(os) {
    "SunOS" -
    "Linux" -
    "Darwin" {
        set isWindows 0
        set tclTestFile $TCL_BIN_DIR/tclsh8.4
        set tkTestFile  $TCL_BIN_DIR/wish8.4
        set itclTestFile $TCL_LIB_DIR/libitclstub3.2.a
        set iwidgetsTestFile $TCL_LIB_DIR/iwidgets4.0.1/iwidgets.tcl
        set bltTestFile $TCL_BIN_DIR/bltwish
        set gslTestFile $GSL_LIB_DIR/libgsl.so
        set vtkTestFile $VTK_DIR/bin/vtk
        set vtkTclLib $TCL_LIB_DIR/libtcl8.4.so 
        set vtkTkLib $TCL_LIB_DIR/libtk8.4.so
        set vtkTclsh $TCL_BIN_DIR/tclsh8.4
        set itkTestFile $ITK_BINARY_PATH/bin/libITKCommon.so
    }
    default {
        # different windows machines return different values, assume if none of the above, windows
        set isWindows 1
        set tclTestFile $TCL_BIN_DIR/tclsh84.exe
        set tkTestFile  $TCL_BIN_DIR/wish84.exe
        set itclTestFile $TCL_LIB_DIR/itcl3.2/itcl32.dll
        set iwidgetsTestFile $TCL_LIB_DIR/iwidgets4.0.2/iwidgets.tcl
        set bltTestFile $TCL_BIN_DIR/BLT24.dll
        #set gslTestFile $GSL_LIB_DIR/gsl.dll
        set gslTestFile $GSL_LIB_DIR/gsl.lib
        set vtkTestFile $VTK_DIR/bin/$VTK_BUILD_TYPE/vtk.exe
        set vtkTclLib $TCL_LIB_DIR/tcl84.lib
        set vtkTkLib $TCL_LIB_DIR/tk84.lib
        set vtkTclsh $TCL_BIN_DIR/tclsh84.exe
        set itkTestFile $ITK_BINARY_PATH/bin/$VTK_BUILD_TYPE/ITKCommon.dll
    }
}

################################################################################
# Get and build CMake
#

# set in slicer_vars
if { ![file exists $CMAKE] } {
    file mkdir $CMAKE_PATH
    cd $SLICER_LIB


    if {$isWindows} {
        puts stderr "-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --"
        puts stderr "-- genlib.tcl cannot generate the certain binaries for windows --"
        puts stderr ""
        puts stderr "You can download a precompiled set of binaries here:"
        puts stderr ""
        puts stderr "http://www.na-mic.org/Wiki/images/8/88/Slicer2.4-Lib-win32.zip"
        puts stderr ""
        puts stderr "Place the contents of the archive in your slicer2 directory."
        puts stderr ""
        puts stderr "With these pieces in place, genlib can build VTK and ITK"
        puts stderr "-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --"
        exit

    } else {
        runcmd cvs -d :pserver:anonymous:cmake@www.cmake.org:/cvsroot/CMake login
        runcmd cvs -z3 -d :pserver:anonymous@www.cmake.org:/cvsroot/CMake checkout -r $cmakeTag CMake

        cd $CMAKE_PATH
        runcmd $SLICER_LIB/CMake/bootstrap
        runcmd make
    }
}


################################################################################
# Get and build tcl, tk, itcl, widgets
#

# on windows, tcl won't build right, as can't configure, so save commands have to run
if { ![file exists $tclTestFile] } {

    if {$isWindows} {
        puts stderr "-- genlib.tcl cannot generate the tcl binaries for windows --"
        puts stderr "1) Get a copy of Tcl 8.4 from tcl.activestate.com."
        puts stderr "2) Set the TCL_BIN_DIR, TCL_LIB_DIR and TCL_INCLUDE_DIR in slicer_variables.tcl."
        puts stderr "3) Get BLT from http://prdownloads.sourceforge.net/blt/blt24z-for-tcl84.exe?download"
        puts stderr "4) Install BLT to a *different* directory than where you installed activetcl"
        puts stderr "5) copy BLT24.dll and BLT24lite24.dll to TCL_BIN_DIR"
        puts stderr "6) copy blt2.4 to TCL_LIB_DIR"
        puts stderr "With these pieces in place, genlib can build VTK and ITK"
        exit
    }

    file mkdir $SLICER_LIB/tcl
    cd $SLICER_LIB/tcl

    runcmd cvs -d :pserver:anonymous:@cvs.sourceforge.net:/cvsroot/tcl login
    runcmd cvs -z3 -d :pserver:anonymous@cvs.sourceforge.net:/cvsroot/tcl checkout -r $tclTag tcl

    if {$isWindows} {
        # can't do windows
    } else {
        cd $SLICER_LIB/tcl/tcl/unix

        runcmd ./configure --enable-threads --prefix=$SLICER_LIB/tcl-build
        runcmd make
        runcmd make install
    }
}

if { ![file exists $tkTestFile] } {
    cd $SLICER_LIB/tcl

    runcmd cvs -d :pserver:anonymous:@cvs.sourceforge.net:/cvsroot/tktoolkit login
    runcmd cvs -z3 -d :pserver:anonymous@cvs.sourceforge.net:/cvsroot/tktoolkit checkout -r $tkTag tk

    if {$isWindows} {
        # can't do windows
    } else {
        cd $SLICER_LIB/tcl/tk/unix

        runcmd ./configure --with-tcl=$SLICER_LIB/tcl-build/lib --prefix=$SLICER_LIB/tcl-build
        runcmd make
        runcmd make install
    }
}

if { ![file exists $itclTestFile] } {
    cd $SLICER_LIB/tcl

    runcmd cvs -d :pserver:anonymous:@cvs.sourceforge.net:/cvsroot/incrtcl login
    runcmd cvs -z3 -d :pserver:anonymous@cvs.sourceforge.net:/cvsroot/incrtcl checkout -r $itclTag incrTcl

    cd $SLICER_LIB/tcl/incrTcl

    exec chmod +x ../incrTcl/configure 
    if {$isWindows} {
        # can't do windows
    } else {
        runcmd ../incrTcl/configure --with-tcl=$SLICER_LIB/tcl-build/lib --with-tk=$SLICER_LIB/tcl-build/lib --prefix=$SLICER_LIB/tcl-build
        runcmd make all
        runcmd make install
    }
}

if { ![file exists $iwidgetsTestFile] } {
    cd $SLICER_LIB/tcl

    runcmd cvs -d :pserver:anonymous:@cvs.sourceforge.net:/cvsroot/incrtcl login
    runcmd cvs -z3 -d :pserver:anonymous@cvs.sourceforge.net:/cvsroot/incrtcl checkout -r $iwidgetsTag iwidgets


    if {$isWindows} {
        # can't do windows
    } else {
        cd $SLICER_LIB/tcl/iwidgets
        runcmd ../iwidgets/configure --with-tcl=$SLICER_LIB/tcl-build/lib --with-tk=$SLICER_LIB/tcl-build/lib --with-itcl=$SLICER_LIB/tcl/incrTcl --prefix=$SLICER_LIB/tcl-build
        # make all doesn't do anything... 
        runcmd make all
        runcmd make install
    }
}


################################################################################
# Get and build blt
#

if { ![file exists $bltTestFile] } {
    cd $SLICER_LIB/tcl
    
    runcmd cvs -d:pserver:anonymous:@cvs.sourceforge.net:/cvsroot/blt login
    runcmd cvs -z3 -d:pserver:anonymous:@cvs.sourceforge.net:/cvsroot/blt co -r $bltTag blt

    if {$isWindows} {
        # can't do windows
    } else {
        cd $SLICER_LIB/tcl/blt
        runcmd ./configure --with-tcl=$SLICER_LIB/tcl-build --with-tk=$SLICER_LIB/tcl-build --prefix=$SLICER_LIB/tcl-build 
        runcmd make
        runcmd make install
    }

}

################################################################################
# Get and build gsl
#

if { ![file exists $gslTestFile] } {
    file mkdir $SLICER_LIB/gsl-build
    file mkdir $SLICER_LIB/gsl

    cd $SLICER_LIB/gsl-build
    
    runcmd cvs -d:pserver:anoncvs:anoncvs@sources.redhat.com:/cvs/gsl login
    runcmd cvs -z3 -d:pserver:anoncvs:anoncvs@sources.redhat.com:/cvs/gsl co -r $gslTag gsl

    if {$isWindows} {
        # can't do windows
    } else {
        cd $SLICER_LIB/gsl-build/gsl
        runcmd ./autogen.sh
        runcmd ./configure --prefix=$SLICER_LIB/gsl
        runcmd touch doc/version-ref.texi
        runcmd make
        runcmd make install
    }

}

################################################################################
# Get and build vtk
#

if { ![file exists $vtkTestFile] } {
    cd $SLICER_LIB

    runcmd cvs -d :pserver:anonymous:vtk@public.kitware.com:/cvsroot/VTK login
    runcmd cvs -z3 -d :pserver:anonymous@public.kitware.com:/cvsroot/VTK checkout -r $vtkTag VTK

    # Andy's temporary hack to get around wrong permissions in VTK cvs repository
    file attributes $SLICER_LIB/VTK/VTKConfig.cmake.in -permissions a+rw

    file mkdir $SLICER_LIB/VTK-build
    cd $SLICER_LIB/VTK-build

    runcmd $CMAKE \
        -G$GENERATOR \
        -DCMAKE_BUILD_TYPE:STRING=$::VTK_BUILD_TYPE \
        -DBUILD_SHARED_LIBS:BOOL=ON \
        -DCMAKE_CXX_COMPILER:STRING=$COMPILER_PATH/$COMPILER \
        -DCMAKE_CXX_COMPILER_FULLPATH:FILEPATH=$COMPILER_PATH/$COMPILER \
        -DBUILD_TESTING:BOOL=OFF \
        -DVTK_USE_CARBON:BOOL=OFF \
        -DVTK_USE_X:BOOL=ON \
        -DVTK_WRAP_TCL:BOOL=ON \
        -DVTK_USE_HYBRID:BOOL=ON \
        -DVTK_USE_PATENTED:BOOL=ON \
        -DTCL_INCLUDE_PATH:PATH=$TCL_INCLUDE_DIR \
        -DTK_INCLUDE_PATH:PATH=$TCL_INCLUDE_DIR \
        -DTCL_LIBRARY:FILEPATH=$vtkTclLib \
        -DTK_LIBRARY:FILEPATH=$vtkTkLib \
        -DTCL_TCLSH:FILEPATH=$vtkTclsh \
        ../VTK

    if {$isWindows} {
        runcmd devenv VTK.SLN /build  $::VTK_BUILD_TYPE
    } else {
        runcmd gmake -j4
    }

}

################################################################################
# Get and build itk
#

if { ![file exists $itkTestFile] } {
    cd $SLICER_LIB

    runcmd cvs -d :pserver:anoncvs:@www.itk.org:/cvsroot/Insight login
    runcmd cvs -z3 -d :pserver:anoncvs@www.itk.org:/cvsroot/Insight checkout -r $itkTag Insight

    file mkdir $SLICER_LIB/Insight-build
    cd $SLICER_LIB/Insight-build


    runcmd $CMAKE \
        -G$GENERATOR \
        -DCMAKE_CXX_COMPILER:STRING=$COMPILER_PATH/$COMPILER \
        -DCMAKE_CXX_COMPILER_FULLPATH:FILEPATH=$COMPILER_PATH/$COMPILER \
        -DBUILD_SHARED_LIBS:BOOL=ON \
        -DBUILD_EXAMPLES:BOOL=OFF \
        -DBUILD_TESTING:BOOL=OFF \
        -DCMAKE_BUILD_TYPE:STRING=$::VTK_BUILD_TYPE \
        ../Insight

    if {$isWindows} {
        runcmd devenv ITK.SLN /build  $::VTK_BUILD_TYPE
    } else {
        runcmd gmake -j4
    }
}

