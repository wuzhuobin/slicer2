#!/bin/sh
# the next line restarts using tclsh \
exec tclsh "$0" "$@"

proc echo {args} {puts "$args"}


proc init { {job_limit 200} } {

    switch $::env(HOSTNAME) { 
        "C226.2532.sc03.org" {
            set ::ids [exec ls -1 /home/pieper/data/MIRIAD/Project_0002]
            set racks {0 2}
            set rows {0 31}
            set ::archive  "/home/pieper/data/MIRIAD/Project_0002"
        }
        "crayon.rocksclusters.org" {
            set ::ids [exec ls -1 /home/pieper/data/MIRIAD/Project_0002]
            set racks {0 0}
            set rows {2 15}
            set ::archive  "/home/pieper/data/MIRIAD/Project_0002"
        }
        "rockstar.rocksclusters.org" {
            set ::ids [exec ssh gpop.bwh.harvard.edu \
                ls -1 /nas/nas0/pieper/data/MIRIAD/Project_0002]
            set racks {0 3}
            set rows {0 31}
            set ::archive  "gpop.bwh.harvard.edu:/nas/nas0/pieper/data/MIRIAD/Project_0002"

        }
    }

    set ::computes(all) ""
    for {set rack [lindex $racks 0]} {$rack <= [lindex $racks 1]} {incr rack} {
        for {set row [lindex $rows 0]} {$row <= [lindex $rows 1]} {incr row} {
            lappend ::computes(all) compute-$rack-$row
            lappend ::free_computes compute-$rack-$row
        }
    }

    puts "collecting jobs"
    set ::jobs ""
    foreach birnid $::ids {
        foreach visit {001 002} {
            set job [list $birnid $visit]
            lappend ::jobs $job
            set ::jobs_to_do($job) 1

            if { [llength $::jobs] >= $job_limit } {
                puts "only doing $job_limit jobs..."
                return 
            }

        }
    }

}


proc load {compute} {
puts -nonewline " fake load "
    return .1

    if { [catch "exec ssh $compute uptime" res] } {
        return 100.00
    } else {
        # return the 1 min average load
        return [lindex $res end-2]
    }
}

proc find_compute {} {

    #
    # pop the first free compute from the list if there is one
    #
    if { [llength $::free_computes] == 0 } {
        return ""
    } else {
        set compute [lindex $::free_computes 0]
        set ::free_computes [lrange $::free_computes 1 end]
        return $compute 
    }

    if { 0 } { 
    # older, load-based calculation - now assume it is loaded
    # if we are running a job on it, or free otherwise

        if { [llength $::free_computes] == 0 } {
            puts "searching for free computes"
            foreach compute $::computes(all) {
                puts -nonewline "." ; flush stdout
                if { [load $compute] < 0.5 } {
                    lappend ::free_computes $compute
                }
            }
            if { [llength $::free_computes] == 0 } {
                puts "sorry, all nodes busy"
                return ""
            }
        }
        set compute [lindex $::free_computes 0]
        set ::free_computes [lrange $::free_computes 1 end]
        return $compute 
    }
}

proc is_running {pid} {
    if { [catch "exec kill -18 $pid"] } {
        return 0
    } else {
        return 1
    }
}

proc run_job {compute job} {

    set birnid [lindex $job 0]
    set visit [lindex $job 1]

    set slicercmd "MIRIADSegmentProcessStudy $::archive $birnid $visit"
    set slicercmd "puts hoot"
    set slicercmd "MIRIADSegmentLoadStudy $::archive 000300742113 001 none"

    set fp [open "| csh -c \"ssh $compute ~/birn/bin/runvnc \
                --wm /home/pieper/bin/xterm -- \
                /home/pieper/birn/slicer2/slicer2-linux-x86 --no-tkcon \
                    --exec $slicercmd ., exit \
              \" |& cat" "r"]
    return $fp
}



proc file_event {fp job} {
    global END
    if {[eof $fp]} {
        catch "close $fp"
        set END 1
    } else {
        gets $fp line
        lappend ::logs($job) "\n\t$line"
        #puts $line
    }
}

proc dump_logs {} {
    set fp [open "cluster-logs" "w"]
    foreach log [array names ::logs] {
        puts $fp "\{ $::logs($log) \}\n"
    }
    close $fp
} 

proc run_jobs {} {

    init 


    set all_finished 0
    set iter 0

    while { !$all_finished } {

        foreach job [array names ::jobs_to_do] {
            set compute [find_compute]
            if { $compute == "" } {
                break; # no free computers... go down to check status
            } else {
                puts "launching $job on $compute"
                set ::computes($job) $compute
                set fps($job) [run_job $compute $job]
                fileevent $fps($job) readable "file_event $fps($job) \"$job\""
                set pids($job) [pid $fps($job)]
                set ::logs($job) "launching $job on $compute at [clock format [clock seconds]]"
                set ::launch_time($job) [clock seconds]
                unset ::jobs_to_do($job)
            }
        }

        after 1000

        if { [array names pids] == "" } {
            set all_finished 1
        } else {
            update
            foreach job [array names pids] {
                if { ![is_running $pids($job)] } {
                    puts "finished: $job on $::computes($job)"
                    set elapsed [expr ([clock seconds] - $::launch_time($job)) / 60.]
                    lappend ::logs($job) "finished $job on $compute at [clock format [clock seconds]] - elapsed time $elapsed minutes"
                    unset pids($job)
                    lappend ::free_computes $::computes($job)
                    unset ::computes($job)
                }
            }
        }
        incr iter
        puts -nonewline "\r$iter: [llength [array names pids]] running, [llength [array names ::jobs_to_do]] waiting..."
        flush stdout
        dump_logs

    }

    puts "done"
    return
}

run_jobs
