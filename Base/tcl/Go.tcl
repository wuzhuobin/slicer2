#=auto==========================================================================
# Copyright (c) 1999 Surgical Planning Lab, Brigham and Women's Hospital
#  
# Direct all questions regarding this copyright to slicer@ai.mit.edu.
# The following terms apply to all files associated with the software unless
# explicitly disclaimed in individual files.   
# 
# The authors hereby grant permission to use, copy, (but NOT distribute) this
# software and its documentation for any NON-COMMERCIAL purpose, provided
# that existing copyright notices are retained verbatim in all copies.
# The authors grant permission to modify this software and its documentation 
# for any NON-COMMERCIAL purpose, provided that such modifications are not 
# distributed without the explicit consent of the authors and that existing
# copyright notices are retained in all copies. Some of the algorithms
# implemented by this software are patented, observe all applicable patent law.
# 
# IN NO EVENT SHALL THE AUTHORS OR DISTRIBUTORS BE LIABLE TO ANY PARTY FOR
# DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
# OF THE USE OF THIS SOFTWARE, ITS DOCUMENTATION, OR ANY DERIVATIVES THEREOF,
# EVEN IF THE AUTHORS HAVE BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# 
# THE AUTHORS AND DISTRIBUTORS SPECIFICALLY DISCLAIM ANY WARRANTIES, INCLUDING,
# BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
# PARTICULAR PURPOSE, AND NON-INFRINGEMENT.  THIS SOFTWARE IS PROVIDED ON AN
# 'AS IS' BASIS, AND THE AUTHORS AND DISTRIBUTORS HAVE NO OBLIGATION TO PROVIDE
# MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
#===============================================================================
# FILE:        Go.tcl
# DATE:        01/18/2000 12:11
# LAST EDITOR: gering
# PROCEDURES:  
#   ReadModuleNames
#   FindNames
#   ReadModuleNamesLocalOrCentral
#   GetFullPath
#==========================================================================auto=

# Load vtktcl.dll on PCs
catch {load vtktcl}

if {$argc > 1} {
    puts "Usage: vtk Go.tcl <MRML file name without .mrml>"
    exit
}

# verbose
set verbose 0

# Determine Slicer's home directory where the program is installed
# If the SLICER_HOME environment is not defined, then use the 
# root directory of this script ($argv0).
#
if {[info exists env(SLICER_HOME)] == 0} {
	set prog [file dirname $argv0]
} elseif {$env(SLICER_HOME) == ""} {
	set prog [file dirname $argv0]
} else {
	set prog [file join $env(SLICER_HOME) program]
}
# Don't use "."
if {$prog == "."} {
	set prog [pwd]
}
# Ensure the program directory exists
if {[file exists $prog] == 0} {
	tk_messageBox -message "The directory '$prog' does not exist."
	exit
}
if {[file isdirectory $prog] == 0} {
	tk_messageBox -message "'$prog' is not a directory."
	exit
}
set Path(program) $prog

# Source Tcl scripts
# Source optional local copies of files with programming changes


#-------------------------------------------------------------------------------
# .PROC ReadModuleNames
# Reads Options.xml 
# Returns ordered and suppressed modules
# .END
#-------------------------------------------------------------------------------
proc ReadModuleNames {filename} {

    if {$filename == ""} {
	return [list "" ""]
    }

    set tags [MainMrmlReadVersion2.0 $filename 0]
    if {$tags == 0} {
	return [list "" ""]
    }

    foreach pair $tags {
	set tag  [lindex $pair 0]
	set attr [lreplace $pair 0 0]
	
	switch $tag {
	    
	    "Options" {
		foreach a $attr {
		    set key [lindex $a 0]
		    set val [lreplace $a 0 0]
		    set node($key) $val
		}
		if {$node(program) == "slicer" && $node(contents) == "modules"} {
		    return [list $node(ordered) $node(suppressed)]
		}
	    }
	}
    }
    return [list "" ""]
}

#-------------------------------------------------------------------------------
# .PROC FindNames
#
# Looks for all the modules.
# For example, for a non-essential module, looks first for ./tcl-modules/*.tcl
# Then looks for $SLICER_HOME/program/tcl-modules/*.tcl
#
# .END
#-------------------------------------------------------------------------------
proc FindNames {dir} {
	global prog
	set names ""

	# Form a full path by appending the name (ie: Volumes) to
        # a local, and then central, directory.
	set local   $dir
	set central [file join $prog $dir]

	# Look locally
	foreach fullname [glob -nocomplain $local/*] {
		if {[regexp "$local/(\.*).tcl$" $fullname match name] == 1} {
			lappend names $name
		}
	}
	# Look centrally
	foreach fullname [glob -nocomplain $central/*] {
		if {[regexp "$central/(\.*).tcl$" $fullname match name] == 1} {
			if {[lsearch $names $name] == -1} {
				lappend names $name
			}
		}
	}
	return $names
}

#-------------------------------------------------------------------------------
# .PROC ReadModuleNamesLocalOrCentral
# .END
#-------------------------------------------------------------------------------
proc ReadModuleNamesLocalOrCentral {name ext} {
	global prog verbose

    set path [GetFullPath $name $ext "" 0]
    set names [ReadModuleNames $path]
    return $names
}

#-------------------------------------------------------------------------------
# .PROC GetFullPath
# .END
#-------------------------------------------------------------------------------
proc GetFullPath {name ext {dir "" } {verbose 1}} {
	global prog

	# Form a full path by appending the name (ie: Volumes) to
	# a local, and then central, directory.
	set local   [file join $dir $name].$ext
	set central [file join [file join $prog $dir] $name].$ext

	if {[file exists $local] == 1} {
		return $local
	} elseif {[file exists $central] == 1} {
		return $central
	} else {
	        if {$verbose == 1} {
		    set msg "File '$name.$ext' cannot be found"
		    puts $msg
		    tk_messageBox -message $msg
		}
		return ""
	}
}

# Steps to sourcing files:
# 1.) Get an ordered list of module names (ie: Volumes, not Volumes.tcl).
# 2.) Append names of other existing modules to this list.
# 3.) Remove names from the list that are in the "suppressed" list.
#

# Source Parse.tcl to read the XML
set path [GetFullPath Parse tcl]
source $path

# Look for an Options.xml file locally and then centrally
set moduleNames [ReadModuleNamesLocalOrCentral Options xml]
set ordered [lindex $moduleNames 0]
set suppressed [lindex $moduleNames 1]

# Find all module names
set found [FindNames tcl-modules]

if {$verbose == 1} {
    puts "found=$found"
    puts "ordered=$ordered"
    puts "suppressed=$suppressed"
}

# Append found names to ordered names
foreach name $found {
	if {[lsearch $ordered $name] == -1} {
		lappend ordered $name
	}
}

# Suppress unwanted (need a more PC term for this) modules
foreach name $suppressed {
	set i [lsearch $ordered $name]
	if {$i != -1} {
		set ordered [lreplace $ordered $i $i]
	}
}

# Source the modules
set foundOrdered ""
foreach name $ordered {
	set path [GetFullPath $name tcl tcl-modules]
	if {$path != ""} {
		if {$verbose == 1} {puts "source $path"}
		source $path
		lappend foundOrdered $name
	} 
}
# Ordered list only contains modules that exist
set ordered $foundOrdered

# Source shared stuff either locally or globally
# For example for a module MyModule, we looks for
# ./tcl-modules/MyModule.tcl and then for $SLICER_HOME/program/tcl-modules/MyModule.tcl
# Similar for tcl-shared and tcl-main

set shared [FindNames tcl-shared]
foreach name $shared {
	set path [GetFullPath $name tcl tcl-shared]
	if {$path != ""} {
		if {$verbose == 1} {puts "source $path"}
		source $path
	}
}

# Source main stuff either locally or globally
set main [FindNames tcl-main]
foreach name $main {
	set path [GetFullPath $name tcl tcl-main]
	if {$path != ""} {
		if {$verbose == 1} {puts "source $path"}
		source $path
	}
}

# Set global variables
set Module(idList)     $ordered
set Module(mainList)   $main
set Module(sharedList) $shared
set Module(supList)    $suppressed
set Module(allList)    [concat $ordered $suppressed]

if {$verbose == 1} {
	puts "ordered=$ordered"
	puts "main=$main"
	puts "shared=$shared"
}

# Bootup
MainBoot [lindex $argv 0]

