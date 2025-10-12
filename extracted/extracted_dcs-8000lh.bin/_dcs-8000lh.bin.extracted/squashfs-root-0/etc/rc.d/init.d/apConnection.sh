#!/bin/sh

start ()
{
	ap_enable=`tdb get Wireless AP_Enable_byte`
	if [ $ap_enable -eq 1 ]
	then
		echo "AP Connection enabled"
		/sbin/wifi-tool start_ap
	fi
}

stop ()
{
	echo "Stopping AP"
	/sbin/wifi-tool stop_ap
}

action=$1

case "$action" in
start)
	start
	;;
stop)
	stop
	;;
restart)
	start
	;;
*)
	echo "Usage: $0 {start|stop|restart}"
	exit 1
	;;
esac
