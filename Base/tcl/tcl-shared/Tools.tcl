#=auto==========================================================================
# (c) Copyright 2003 Massachusetts Institute of Technology (MIT) All Rights Reserved.
#
# This software ("3D Slicer") is provided by The Brigham and Women's 
# Hospital, Inc. on behalf of the copyright holders and contributors. 
# Permission is hereby granted, without payment, to copy, modify, display 
# and distribute this software and its documentation, if any, for internal 
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
# FILE:        Tools.tcl
# PROCEDURES:  
#   ToolUpdate
#   ToolStub
#==========================================================================auto=
# Tools.tcl
# 11/30/98 Peter C. Everett peverett@bwh.harvard.edu: Created

#-------------------------------------------------------------------------------
# ToolsInit
# Initializes global variables used in creating/managing tool bars
#-------------------------------------------------------------------------------
proc ToolsInit {} {

# Modified by Attila Tanacs 11/01/2000
# In order to run on NT

    global env prog
    set home $prog 
    set homebitmaps [file join $home gui bitmaps]
    
    set pwd [pwd]
    cd [file join $home gui bitmaps]
    foreach foo [glob -nocomplain *.bmp] {
        if {![file isdirectory $foo]} {
            # image create bitmap $foo -file [file join $homebitmaps $foo]
            image create bitmap $foo -file $foo
            #tk_messageBox -type ok -message $foo -icon info
        }
    }
    
    cd $pwd
}

#-------------------------------------------------------------------------------
# ToolBar
# each element of args has the form {toolname toolimage toolenter toolexit}
# where the global variable "name(tool)" is set to "toolname" when the tool
# is selected, the bitmap image "toolimage" is used in the toolbar, and
# the routines "toolenter" and "toolexit" are called on entering and exiting
# each tool in the toolbar, respectively.
#-------------------------------------------------------------------------------
proc ToolBar { frame barname args } {
    global $barname Gui

    set f [frame $frame -bg $Gui(activeWorkspace) -cursor hand2]
    set ${barname}(frame) $f
    foreach tool $args {
        set toolname [lindex $tool 0]
        set toolimage [lindex $tool 1]
        set toolenter [lindex $tool 2]
        set toolexit [lindex $tool 3]
        set tooltip [lindex $tool 4]
        if { $toolenter == "" } {
            set toolenter ToolStub
            }
        if { $toolexit == "" } {
            set toolexit ToolStub
            }
        if { $tooltip == "" } {
            set tooltip $toolname
            }

        if { $toolimage == "" } {
            set c {radiobutton $f.rb$toolname -indicatoron 0 \
                -command "ToolUpdate $barname $toolenter $toolexit" \
                -text $toolname $Gui(WRA) \
                -variable ${barname}(tool) \
                -value $toolname }
            eval [subst $c]
        } else {
            set c {radiobutton $f.rb$toolname -indicatoron 0 \
                -command "ToolUpdate $barname $toolenter $toolexit" \
                -image $toolimage $Gui(WRA) \
                -variable ${barname}(tool) \
                -value $toolname }
            eval [subst $c]
            }
        pack $f.rb$toolname -side left
        TooltipAdd $f.rb$toolname $tooltip
        }

    set ${barname}(prevtool) ""
    set ${barname}(toolexit) ""
    pack $f

    return $f
}

#-------------------------------------------------------------------------------
# .PROC ToolUpdate
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ToolUpdate { barname toolenter toolexit } {
    global $barname

    # For debugging:
    # puts "ToolUpdate $barname $toolenter $toolexit"

    set toolname [subst $${barname}(tool)]
    set prevtool [subst $${barname}(prevtool)]
    if { $prevtool != $toolname } {
        set prevexit [subst $${barname}(toolexit)]
        if { $prevexit != "" } {
            $prevexit $prevtool
            }
        set ${barname}(toolexit) $toolexit
        set ${barname}(prevtool) $toolname
        if { $toolenter != "" } {
            $toolenter $toolname
            }
        }
    }

#-------------------------------------------------------------------------------
# .PROC ToolStub
# 
# .ARGS
# .END
#-------------------------------------------------------------------------------
proc ToolStub { args } {
    }
