#!/bin/sh

daemon=ntpd
PATH=$PATH:/sbin

die() {
	echo $@
	exit 1
}

showUsage() {
	die "$0 {start|stop|restart|status} [prefix]"
}

setupConf() {
	eval $(echo "Enable_byte DHCPNTPEnable_byte Server_ms Retry_byte" | tdb get NTPClient)
	enable=$Enable_byte
	echo > $shadow
	echo "servers $Server_ms" >> $shadow
}

checkExited() {
	pids=$(pidof $daemon) && return 1 || return 0
}

start() {
	checkExited || die "$daemon($pids) is already running."
	echo -n "Startting $daemon... "
	[ -x $binary ] || die "$binary is not a valid application"
	export LD_LIBRARY_PATH=$prefix/lib
	
	setupConf

	# start...
	if [ $enable -eq 0 ]; then
		echo "disabled."
	else
		rm -f /tmp/ntp_sync_log
		ntp_from_dhcp=/tmp/NTPFromDHCP.conf
		if [ "$DHCPNTPEnable_byte" -eq "0" ] && [ -f "$ntp_from_dhcp" ]; then
			$binary -s -r $Retry_byte -f $ntp_from_dhcp &
		else
			$binary -s -r $Retry_byte -f $conf &
		fi
		sleep 1
		if [ -f "/tmp/ntp_sync_log" ]; then
			echo "ok."
		else 
			echo "ng"
		fi
	fi
}

status() {
	echo -n "$daemon"
	checkExited && echo " is stop." || echo "($pids) is running."
}

stop() {
	if checkExited; then 
		echo "$daemon is not running." 
		return 0
	fi

	echo -n "Stopping $daemon... "
	kill $(echo $pids | cut -d' ' -f1)
	sleep 1
	if checkExited; then
		echo "ok."
		return 0
	fi

	killall $daemon
	sleep 2
	if checkExited; then
		echo "ok."
		return 0
	fi

	killall -9 $daemon
	sleep 3
	checkExited && echo "ok." || die "ng."
}

action=$1
prefix=$2
end=$3

[ "$end" = "" ] && [ "$action" != "" ] || showUsage
[ "$prefix" = "" ] || [ -d "$prefix" ] || die "$prefix is not a valid directory"

# conf is symbolic link to shadow
conf=/etc/$daemon.conf
shadow=/tmp/$daemon.conf
binary=$prefix/sbin/$daemon

case $action in
	start)
		start
	;;
	stop)
		stop
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
