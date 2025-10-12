#!/bin/sh

PATH=$PATH:/sbin
daemon=wifiAutoReconnect

die() {
        echo $@
        exit 1
}

start() {
	! pids=$(pidof $daemon) || die "$daemon($pids) is already running."
        echo -n "Startting $daemon... "
        [ -x $binary ] || die "$binary is not a valid application"
        export LD_LIBRARY_PATH=$prefix/lib
        $binary  > /dev/null 2> /dev/null &
        echo "ok."
}

status() {
        echo -n "$daemon"
        pids=$(pidof $daemon) && echo "($pids) is running." || echo " is stop."
}

stop() {
        pids=$(pidof $daemon) || { echo "$daemon is not running." && return 1; }
        echo -n "Stopping $daemon... "
        for i in 1 2 3 4 5; do
                kill $(echo $pids | cut -d' ' -f1)
                sleep 1
                pids=$(pidof $daemon) || break
        done
        pids=$(pidof $daemon) && killall -9 $daemon && sleep 1 && pids=$(pidof $daemon) && die "ng." || echo "ok."
}

action=$1
prefix=$2
end=$3

[ "$end" = "" ] && [ "$action" != "" ] || showUsage
[ "$prefix" = "" ] || [ -d "$prefix" ] || die "$prefix is not a valid directory"

binary=$prefix/sbin/$daemon

case "$action" in
start)
	start
	;;
stop)
	# FIXME should probably save and use daemon's PID
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
	echo "Usage: $0 {start|stop|status|restart}"
	exit 1
	;;
esac
