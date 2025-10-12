#!/bin/sh

daemon=dbd
PATH=$PATH:/sbin

die() {
	echo $@
	exit 1
}

showUsage() {
	die "$0 {start|stop|restart|status|setDefaultDB} [prefix]"
}


setDefaultDB() {
	[ "$(tdb get Host CameraName_ms)" ] || { 
		echo -n "set default..."
#		model=$([ "$(pibinfo Wireless)" -eq 1 ] && tdb get System ModelW_ss || tdb get System Model_ss)
		model=$(tdb get System Model_ss)
		power_freq=$(pibinfo PowerFrequency)
		tdb set Host CameraName_ms=$model
		tdb set OSD Text_ss=$model
		tdb set TargetSnapFTP Prefix_ss=$model
		tdb set TargetClipFTP Prefix_ss=$model
		tdb set TargetSamba ShareFolder_ss=$model
		tdb set Scopes Name_ls=$model
		tdb set Image Frequency_num=$power_freq
		mac_addr=$(pibinfo MacAddress)
		mac_b5=$(echo $mac_addr | cut -d':' -f5)
		mac_b6=$(echo $mac_addr | cut -d':' -f6)
		echo "ok."

		echo "set the date to default:"
		OEM=$(tdb get System OEM_ms)
		if [ "$OEM" = 'Trendnet' ]; then
			tdb set HTTPAccount AdminPasswd_ss=$(pibinfo FactoryPassword)
			date 010108002016
		elif [ "$OEM" = 'D-Link' ]; then
			tdb set Wireless AP_SSID_ms=${model}-${mac_b5}${mac_b6}
			tdb set Wireless AP_PW_ls=$(pibinfo ApKey)
		fi
		hwclock -w -u
	}
}


start() {
	[ -d /tmp/db ] || mkdir /tmp/db
	[ -f /tmp/db/default.xml ] || cp /etc/db/default.xml /tmp/db/default.xml
	! pids=$(pidof $daemon) || die "$daemon($pids) is already running."
	echo -n "Startting $daemon... "
	[ -x $binary ] || die "$binary is not a valid application"
	export LD_LIBRARY_PATH=$prefix/lib
	$binary > /dev/null 2> /dev/null &
	sleep 1
	[ -e /bin/console_secure ] && /bin/console_secure
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

reload() {
	/bin/send_cmd "$daemon" 100 || die "$daemon is not running."
}

action=$1
prefix=$2
end=$3

[ "$end" = "" ] && [ "$action" != "" ] || showUsage
[ "$prefix" = "" ] || [ -d "$prefix" ] || die "$prefix is not a valid directory"

conf=$prefix/etc/$daemon.conf
binary=$prefix/sbin/$daemon

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
	reload)
		reload
	;;
	status)
		status
	;;
	setDefaultDB)
		setDefaultDB
	;;
	*)
		showUsage
	;;
esac

exit 0
