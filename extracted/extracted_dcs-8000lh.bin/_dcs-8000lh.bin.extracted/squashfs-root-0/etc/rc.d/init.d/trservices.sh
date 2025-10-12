#!/bin/sh

die() {
	echo $@
	exit 1
}

showUsage() {
	die "$0 {start|stop|restart|status} [prefix]"
}

# start order
# recorderd, snapshotd -> eventd -> watchDog, motiond
# recorderd, snapshotd, watchDog, motiond -> scheduled
start() {
	echo "Do nothing in this platform"
}

status() {
	echo "Do nothing in this platform"
}

stop() {
	echo "Do nothing in this platform"
}

existRestart() {
	echo "Do nothing in this platform"
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
	existRestart)
		existRestart	
	;;
	*)
		showUsage
	;;
esac

exit 0
