#!/bin/sh

daemon=myDlinkEvent
PATH=$PATH:/sbin

die() {
	echo $@
	exit 1
}

showUsage() {
	die "$0 {start|stop|restart} [prefix]"
}

start() {
	if [ ! -d /tmp/cert ] ; then
		mkdir /tmp/cert
		mount -t tmpfs -o size=8k,rw tmpfs /tmp/cert/
		base64 de `pibinfo MyDlinkPublicKey` > /mydlink/cert/client.crt.pem
		base64 de `pibinfo MyDlinkPrivateKey` > /mydlink/cert/client.crt.key
		mount -o remount,ro /tmp/cert/ 
	fi
	! pids=$(pidof $daemon) || die "$daemon($pids) is already running."
	echo -n "Startting $daemon... "
	[ -x $binary ] || die "$binary is not a valid application"
	export LD_LIBRARY_PATH=$prefix/lib
	
	$binary --port 3011 > /dev/null 2> /dev/null &
	
	echo "ok."
}

stop() {
	pids=$(pidof $daemon) || { echo "$daemon is not running." && return 1; }
	kill $(echo $pids)
}

action=$1
prefix=$2
end=$3

[ "$end" = "" ] && [ "$action" != "" ] || showUsage
[ "$prefix" = "" ] || [ -d "$prefix" ] || die "$prefix is not a valid directory"

binary=$prefix/sbin/$daemon

case $action in
	start)
		start
	;;
	stop)
		stop || exit 1
	;;
	restart)
		stop
		start
	;;
	*)
		showUsage
	;;
esac

exit 0

