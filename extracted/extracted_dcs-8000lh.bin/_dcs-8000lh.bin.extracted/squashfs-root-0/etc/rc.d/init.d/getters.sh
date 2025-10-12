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
	$prefix/etc/rc.d/init.d/rtpd.sh start $prefix
	$prefix/etc/rc.d/init.d/rtspd.sh start $prefix
	$prefix/etc/rc.d/init.d/Ruler.sh start $prefix
}

status() {
	echo status of services, ...
	$prefix/etc/rc.d/init.d/rtpd.sh status $prefix
	$prefix/etc/rc.d/init.d/rtspd.sh status $prefix
	$prefix/etc/rc.d/init.d/Ruler.sh status $prefix
}

stop() {
	echo stop services, ...
	killall ACVS-H264.cgi MP4V-ES.cgi asfmp4.cgi ts-mp4.cgi ACVS.cgi asf-mp4.cgi mjpg.cgi mp4ts.cgi

	#Evan refine for speed-up stop shell scripts
	local daemons=""
	local test_count=0
	
	[ -x $prefix/etc/rc.d/init.d/Ruler.sh ] && daemons="Ruler $daemons"
	[ -x $prefix/etc/rc.d/init.d/rtspd.sh ] && daemons="rtspd $daemons"
	[ -x $prefix/etc/rc.d/init.d/rtpd.sh ] && daemons="rtpd $daemons"

	echo Daemons are killed: $daemons ...
	killall $daemons
	sleep 1
	while true; do 
	    pids=$(pidof $daemons) || return 0  
	    echo $daemons is not stop clearly
	    killall $daemons
	    sleep 1
	    let test_count=test_count+1
	    if [ $test_count -ge 2 ]; then
		killall -9 $daemons
		return 0
	    fi
	done


#	$prefix/etc/rc.d/init.d/Ruler.sh stop $prefix
#	$prefix/etc/rc.d/init.d/rtspd.sh stop $prefix
#	$prefix/etc/rc.d/init.d/rtpd.sh stop $prefix
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
