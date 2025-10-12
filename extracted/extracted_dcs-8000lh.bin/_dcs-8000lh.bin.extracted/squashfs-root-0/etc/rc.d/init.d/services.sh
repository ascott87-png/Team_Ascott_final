#!/bin/sh

die() {
	echo $@
	exit 1
}

showUsage() {
	die "$0 {start|stop|restart|status} [prefix]"
}

start() {
	echo start services, ...
	[ -x $prefix/etc/rc.d/init.d/vcd.sh ] && $prefix/etc/rc.d/init.d/vcd.sh start $prefix
	[ -x $prefix/etc/rc.d/init.d/acd.sh ] && $prefix/etc/rc.d/init.d/acd.sh start $prefix
	[ -x $prefix/etc/rc.d/init.d/avcd.sh ] && $prefix/etc/rc.d/init.d/avcd.sh start $prefix
	sleep 4;
	[ -x $prefix/etc/rc.d/init.d/db_analysis.sh ] && $prefix/etc/rc.d/init.d/db_analysis.sh start $prefix
	[ -x $prefix/etc/rc.d/init.d/rtpd.sh ] && $prefix/etc/rc.d/init.d/rtpd.sh start $prefix
	[ -x $prefix/etc/rc.d/init.d/rtspd.sh ] && $prefix/etc/rc.d/init.d/rtspd.sh start $prefix
	[ -x $prefix/etc/rc.d/init.d/Onvif_mcast.sh ] && $prefix/etc/rc.d/init.d/Onvif_mcast.sh start $prefix
	[ -x $prefix/etc/rc.d/init.d/Ruler.sh ] && $prefix/etc/rc.d/init.d/Ruler.sh start $prefix
	[ -x $prefix/etc/rc.d/init.d/bluetoothd.sh ] && $prefix/etc/rc.d/init.d/bluetoothd.sh start $prefix
	[ -x $prefix/etc/rc.d/init.d/dbus-daemon.sh ] && $prefix/etc/rc.d/init.d/dbus-daemon.sh start $prefix

	[ -x $prefix/etc/rc.d/init.d/finderd.sh ] && $prefix/etc/rc.d/init.d/finderd.sh start $prefix
	[ -x $prefix/etc/rc.d/init.d/mDNSResponder.sh ] && $prefix/etc/rc.d/init.d/mDNSResponder.sh start $prefix
	[ -x $prefix/etc/rc.d/init.d/upnp_av.sh ] && $prefix/etc/rc.d/init.d/upnp_av.sh start $prefix
	[ -x $prefix/etc/rc.d/init.d/upnp_av_ipv6.sh ] && $prefix/etc/rc.d/init.d/upnp_av_ipv6.sh start $prefix
	[ -x $prefix/etc/rc.d/init.d/discovery.sh ] && $prefix/etc/rc.d/init.d/discovery.sh start $prefix
	[ -x $prefix/etc/rc.d/init.d/ddnsUpdater.sh ] && $prefix/etc/rc.d/init.d/ddnsUpdater.sh start $prefix
	[ -x $prefix/etc/rc.d/init.d/lld2d.sh ] && $prefix/etc/rc.d/init.d/lld2d.sh start $prefix
	[ -x $prefix/etc/rc.d/init.d/ntpd.sh ] && $prefix/etc/rc.d/init.d/ntpd.sh start $prefix


}

status() {
	echo status of services, ...
	[ -x $prefix/etc/rc.d/init.d/vcd.sh ] && $prefix/etc/rc.d/init.d/vcd.sh status $prefix
	[ -x $prefix/etc/rc.d/init.d/acd.sh ] && $prefix/etc/rc.d/init.d/acd.sh status $prefix
	[ -x $prefix/etc/rc.d/init.d/avcd.sh ] && $prefix/etc/rc.d/init.d/avcd.sh status $prefix
	[ -x $prefix/etc/rc.d/init.d/db_analysis.sh ] && $prefix/etc/rc.d/init.d/db_analysis.sh status $prefix
	[ -x $prefix/etc/rc.d/init.d/rtpd.sh ] && $prefix/etc/rc.d/init.d/rtpd.sh status $prefix
	[ -x $prefix/etc/rc.d/init.d/rtspd.sh ] && $prefix/etc/rc.d/init.d/rtspd.sh status $prefix
	[ -x $prefix/etc/rc.d/init.d/Onvif_mcast.sh ] && $prefix/etc/rc.d/init.d/Onvif_mcast.sh status $prefix
	[ -x $prefix/etc/rc.d/init.d/Ruler.sh ] && $prefix/etc/rc.d/init.d/Ruler.sh status $prefix
	[ -x $prefix/etc/rc.d/init.d/bluetoothd.sh ] && $prefix/etc/rc.d/init.d/bluetoothd.sh status $prefix
	[ -x $prefix/etc/rc.d/init.d/dbus-daemon.sh ] && $prefix/etc/rc.d/init.d/dbus-daemon.sh status $prefix

	[ -x $prefix/etc/rc.d/init.d/finderd.sh ] && $prefix/etc/rc.d/init.d/finderd.sh status $prefix
	[ -x $prefix/etc/rc.d/init.d/mDNSResponder.sh ] && $prefix/etc/rc.d/init.d/mDNSResponder.sh status $prefix
	[ -x $prefix/etc/rc.d/init.d/upnp_av.sh ] && $prefix/etc/rc.d/init.d/upnp_av.sh status $prefix
	[ -x $prefix/etc/rc.d/init.d/upnp_av_ipv6.sh ] && $prefix/etc/rc.d/init.d/upnp_av_ipv6.sh status $prefix
	[ -x $prefix/etc/rc.d/init.d/discovery.sh ] && $prefix/etc/rc.d/init.d/discovery.sh status $prefix
	[ -x $prefix/etc/rc.d/init.d/ddnsUpdater.sh ] && $prefix/etc/rc.d/init.d/ddnsUpdater.sh status $prefix
	[ -x $prefix/etc/rc.d/init.d/lld2d.sh ] && $prefix/etc/rc.d/init.d/lld2d.sh status $prefix
	[ -x $prefix/etc/rc.d/init.d/ntpd.sh ] && $prefix/etc/rc.d/init.d/ntpd.sh status $prefix


}

stop() {
	echo stop services, ...

        #Evan refine for speed-up stop shell scripts
        local daemons=""
        local test_count=0
	
	[ -x $prefix/etc/rc.d/init.d/finderd.sh ] && daemons="finderd $daemons"
	[ -x $prefix/etc/rc.d/init.d/mDNSResponder.sh ] && daemons="mDNSResponder $daemons"
	[ -x $prefix/etc/rc.d/init.d/upnp_av.sh ] && daemons="orthrus $daemons"
	[ -x $prefix/etc/rc.d/init.d/upnp_av_ipv6.sh ] && daemons="orthrusipv6 $daemons"
	[ -x $prefix/etc/rc.d/init.d/ddnsUpdater.sh ] && daemons="ddnsUpdater $daemons"
	[ -x $prefix/etc/rc.d/init.d/ntpd.sh ] && daemons="ntpd $daemons"

	[ -x $prefix/etc/rc.d/init.d/Ruler.sh ] && daemons="Ruler $daemons"
	[ -x $prefix/etc/rc.d/init.d/Onvif_mcast.sh ] && daemons="Onvif_mcast $daemons"
	[ -x $prefix/etc/rc.d/init.d/rtspd.sh ] && daemons="rtspd $daemons"
	[ -x $prefix/etc/rc.d/init.d/rtpd.sh ] && daemons="rtpd $daemons"
	[ -x $prefix/etc/rc.d/init.d/db_analysis.sh ] && daemons="db_analysis $daemons"
	[ -x $prefix/etc/rc.d/init.d/avcd.sh ] && daemons="avcd $daemons"
	[ -x $prefix/etc/rc.d/init.d/acd.sh ] && daemons="acd aacd $daemons"
	[ -x $prefix/etc/rc.d/init.d/vcd.sh ] && daemons="vcd $daemons"

	[ -x $prefix/etc/rc.d/init.d/lld2d.sh ] && $prefix/etc/rc.d/init.d/lld2d.sh stop $prefix
	[ -x $prefix/etc/rc.d/init.d/discovery.sh ] && $prefix/etc/rc.d/init.d/discovery.sh stop $prefix
	[ -x $prefix/etc/rc.d/init.d/bluetoothd.sh ] && $prefix/etc/rc.d/init.d/bluetoothd.sh stop $prefix
	[ -x $prefix/etc/rc.d/init.d/dbus-daemon.sh ] && $prefix/etc/rc.d/init.d/dbus-daemon.sh stop $prefix

	echo Daemons are killed: $daemons ...
        killall $daemons                                          
        sleep 1
	while true; do 
	    pids=$(pidof $daemons) || return 0
	    echo $daemons is not stop clear 	
	    killall $daemons
	    sleep 1
	    let test_count=test_count+1
	    if [ $test_count -ge 2 ]; then
		killall -9 $daemons
		return 0
	    fi
	done
}

action=$1
prefix=$2
end=$3

[ "$end" = "" ] && [ "$action" != "" ] || showUsage
[ "$prefix" = "" ] || [ -d "$prefix" ] || die "$prefix is not a valid directory"

case $action in
	start)
		start
	;;
	stop)
		# stop may call return, instead of exit
		stop || exit 1
	;;
	restart)
		stop
		start
	;;
	status)
		status
	;;
	*)
		showUsage
	;;
esac

exit 0
