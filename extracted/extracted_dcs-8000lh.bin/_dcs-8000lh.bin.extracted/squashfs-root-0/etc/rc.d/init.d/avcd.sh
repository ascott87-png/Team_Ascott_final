#!/bin/sh

daemon_vcd=vcd
daemon_acd=acd
PATH=$PATH:/sbin

die() {
	echo $@
	exit 1
}

showUsage() {
	die "$0 {start|stop|restart|status|reload_acd|mdreload} [prefix]"
}

dumpKeys() {
	echo "Enable_byte Volume_byte"
}

mdreload() {
	pids=$(pidof $daemon_vcd) || { echo "$daemon_vcd is not running." && return 1; }
	echo -n "Motion Reload $daemon_vcd... "
	kill -s SIGUSR2 $(echo $pids | cut -d' ' -f1)
	echo "ok."
}

setupMixer() {
	eval $(dumpKeys | tdb get Microphone)
	micEnable=$Enable_byte
	micVolume=$Volume_byte
	eval $(dumpKeys | tdb get Speaker)
	speakerEnable=$Enable_byte
	speakerVolume=$Volume_byte

	mixer=$prefix/bin/mixer
	if [ "$micEnable" != "0" ]; then
		$mixer igain $micVolume
	else
		$mixer igain 0	
	fi

	if [ "$speakerEnable" != 0 ]; then
		$mixer vol $speakerVolume
	else
		$mixer vol 0
	fi
}

start_vcd() {

	! pids=$(pidof $daemon_vcd) || die "$daemon_vcd($pids) is already running."
	echo "Startting $daemon_vcd... "
	[ -x $binary_vcd ] || die "$binary_vcd is not a valid application"

	export LD_LIBRARY_PATH=$prefix/lib
	$binary_vcd > /dev/null 2> /dev/null &
	echo "vcd ok."

}

start_acd(){

	! pids=$(pidof $daemon_acd) || die "$daemon_acd($pids) is already running."
	echo "Startting $daemon_acd... "
	[ -x $binary_acd ] || die "$binary_acd is not a valid application"

	export LD_LIBRARY_PATH=$prefix/lib
	setupMixer
	$binary_acd > /dev/null 2> /dev/null &
	echo "acd ok."
}

reload_acd() {
	echo -n "Reloading acd... "
	export LD_LIBRARY_PATH=$prefix/lib
	setupMixer
	echo "ok."
}

status() {
	echo -n "$daemon_vcd"
	pids=$(pidof $daemon_vcd) && echo "($pids) is running." || echo " is stop."

	echo -n "$daemon_acd"
	pids=$(pidof $daemon_acd) && echo "($pids) is running." || echo " is stop."

}

stop() {
	pids=$(pidof $daemon_vcd)  &&
	{
		echo -n "Stopping $daemon_vcd... "
		pids=$(pidof $daemon_vcd) && killall -USR1 $daemon_vcd && sleep 1 && pids=$(pidof $daemon_vcd) && die "ng." || echo "ok."
	} || 
	{ echo "$daemon_vcd is not running."; }

	pids=$(pidof $daemon_acd) &&
	{
		echo -n "Stopping $daemon_acd... "
		pids=$(pidof $daemon_acd) && killall -USR1 $daemon_acd && sleep 1 && pids=$(pidof $daemon_acd) && die "ng." || echo "ok."
	} || 
	{ echo "$daemon_acd is not running."; }
}

set_debug() {
	if [ "$1" == "on" ]; then
		touch /tmp/vcd_debug_on
		#killall -s SIGUSR2 avcd
	elif [ "$1" == "off" ]; then
		touch /tmp/vcd_debug_off
		#killall -s SIGUSR2 avcd
	fi
}

action=$1
prefix=$2
end=$3

[ "$end" = "" ] && [ "$action" != "" ] || showUsage
[ "$prefix" = "" ] || [ -d "$prefix" ] || die "$prefix is not a valid directory"

binary_vcd=$prefix/sbin/$daemon_vcd
binary_acd=$prefix/sbin/$daemon_acd

case $action in
	start)
		start_vcd
		start_acd
	;;
	mdreload)
		mdreload	
	;;
	stop)
		# stop may call return, instead of exit
		stop || exit 1
	;;
	restart)
		stop
		start_vcd
		start_acd
	;;
	status)
		status
	;;
	reload_acd)
		reload_acd
	;;
	debug_on)
		set_debug "on"
	;;
	debug_off)
		set_debug "off"
	;;
	*)
		showUsage
	;;
esac

exit 0
