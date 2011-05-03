# demo.tcl - Copyright (C) 2011 Pat Thoyts <patthoyts@users.sourceforge.net>
#
# Demo the imgscale algorithms.
#
# usage: demo ?-crimp? imagefile ?factor?
#    eg: demo frog.png 1.75

package require Tk
if {[package vsatisfies [package provide Tk] 8.5]} {
    if {[catch {package require img::jpeg}]} {
        lappend auto_path \
            /opt/tcl/lib/teapot/package/win32-ix86/lib \
            /opt/tcl/lib/teapot/package/tcl/lib
    }
    if {![package vsatisfies [package provide Tk] 8.6]} {
        package require img::png
    }
    package require img::jpeg
    package require img::gif
    package require img::bmp
}

lappend auto_path [file dirname [info script]]
package require imgscale

proc bgerror {s} {
    tk_messageBox -icon error -title "ImgScale Demo Error" \
        -message $s
}

proc main {filename {scale 2.5}} {
    variable uid
    if {![info exists uid]} { variable uid 0 }

    set img [image create photo -file $filename]
    set width [expr {int([image width $img] * $scale)}]
    set height [expr {int([image height $img] * $scale)}]
    set scale1 [image create photo -height $height -width $width]
    set scale2 [image create photo -height $height -width $width]
    set scale3 [image create photo -height $height -width $width]

    if {[info command crimp] ne {}} {
        set data [crimp read tk $img]
        foreach {name algo} [list $scale1 nneighbour $scale2 bilinear $scale3 bicubic] {
            set t [lindex [time {crimp write 2tk $name \
                                     [crimp resize -interpolate $algo $data $width $height]}] 0]
            lappend result $algo $name $t
        }
    } else {
        foreach {name algo} [list $scale1 nearest $scale2 average $scale3 bilinear] {
            set t [lindex [time {imgscale::$algo $img $width $height $name 1}] 0]
            lappend result $algo $name $t
        }
    }

    set dlg [toplevel .demo[incr uid]]
    wm title $dlg "[file tail $filename] - Imgscale Demo 1"
    wm withdraw $dlg
    
    set canvas [canvas $dlg.c -background SystemWindow]
    if {[image width $img] < 200} {
        $canvas create image 5 5 -image $img -anchor nw -tag ORIG
        set x [expr {[image width $img] + (2 * 5)}]
    } else {
        set x 5
    }

    foreach {title name time} $result {
        $canvas create image $x 5 -image $name -anchor nw
        set bot [expr {5 + [image height $name]}]
        $canvas create rectangle $x 5 [expr {$x + [image width $name]}] $bot
        incr bot 2
        $canvas create text $x $bot -anchor nw  -text "$title ${time}ns"
        incr x [image width $name]
        incr x 5
    }
    
    $canvas configure -width $x
    pack $canvas -fill both -expand 1
    bind $dlg <Control-F2> {console show}
    wm deiconify $dlg
    tkwait window $dlg
    return
}

if {!$tcl_interactive} {
    if {![info exists initialized]} {
        set initialized 1
        wm withdraw .
        if {[string match -crimp [lindex $argv 0]]} {
            set argv [lrange $argv 1 end]
            catch {package require crimp}
        }
        set r [catch [linsert $argv 0 main] err]
        if {$r} {
            tk_messageBox -icon error -title "ImgScale Demo Error" \
                -message $err
        }
        exit $r
    }
}
