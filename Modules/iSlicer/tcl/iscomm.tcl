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
# FILE:        iscomm.tcl
# PROCEDURES:  
#==========================================================================auto=



#########################################################
#
if {0} { ;# comment

iscomm - a class for sending vtk objects between slicer instances

note: this isn't a widget

# TODO : 

}
#
#########################################################


#
# The class definition - define if needed (not when re-sourcing)
#
if { [itcl::find class iscomm] == "" } {

    itcl::class iscomm {

      constructor {args} {}
      destructor {}

      # configure options
      public variable port 18943  ;# an arbitrary, but "well known" (to iscomm) starting port
      public variable local 1  ;# do (0) or don't (1) accept remote connections

      variable _name
      variable _channel ""

      # client methods
      method send { imagedata } {}

      # server methods
      method accept {chan fid addr remport} {}
    }
}


# ------------------------------------------------------------------
#                        CONSTRUCTOR/DESTRUCTOR
# ------------------------------------------------------------------
itcl::body iscomm::constructor {args} {

    # uses the comm package that is part of the tcllib
    if { [catch "package require comm"] } {
        error "iscomm doesn't work without the tcllib comm package"
    }

    # make a unique name associated with this object
    set _name [namespace tail $this]

    if { [lindex $args 0] == "server" } {
        set _channel [::comm::comm new ::channel_$_name -port $port -local $local -listen 1]
        ::comm::comm hook incoming "$this accept \$chan \$fid \$addr \$remport"
    }
}


itcl::body iscomm::destructor {} {
    
    if { $_channel != "" } {
        $_channel destroy
    }
}

# ------------------------------------------------------------------
#                             OPTIONS
# ------------------------------------------------------------------

#-------------------------------------------------------------------------------
# OPTION: -port
#
# DESCRIPTION: set the port for this connection
#-------------------------------------------------------------------------------
itcl::configbody iscomm::port {
}

# ------------------------------------------------------------------
#                             METHODS
# ------------------------------------------------------------------


itcl::body iscomm::send { imagedata } {

    set spw ::spw_${_name}
    catch "$spw Delete"
    vtkStructuredPointsWriter $spw
    $spw SetInput $imagedata
    $spw SetWriteToOutputString 1
    $spw SetFileTypeToBinary

    # TODO - it appears we can't get the full binary string in tcl!

    ::comm::comm send $port "puts hoot"
} 

itcl::body iscomm::accept { chan fid addr remport } {
    
    puts "accept $chan $fid $addr $remport"
}

proc iscomm_demo { {mode "server"} } {

    catch {rename c ""}
    iscomm c $mode

    switch $mode {
        "server" {
        }
        "client" {
            catch "es Delete"
            vtkImageEllipsoidSource es
            [es GetOutput] Update
            c send [es GetOutput]
        }
    }
} 


