#!/bin/sh

#script to check if we should disable AP started by the WPS button

singleProbeLink() {
	ethtool eth0 2> /dev/null | grep -q "Link detected: yes"
}

probeWireLink() {
	one=unknown
	other=unknown
	while true; do
		one=$( singleProbeLink && echo -n "0" || echo -n "1" )
		[ "$other" == "$one" ] && return "$one"
		sleep 1
		other=$( singleProbeLink && echo -n "0" || echo -n "1" )
		[ "$other" == "$one" ] && return "$one"
		sleep 1
	done
}

probeWireLink && wire_link=1 || wire_link=0
[ $wire_link -eq 1 ] && exit 1

sleep 600

[ -f "/tmp/udhcpd.pid" ] && udhcpd_pid=`cat /tmp/udhcpd.pid` || exit 1

if [ -f "/tmp/udhcpd.leases" ]
then
	kill -SIGUSR1 $udhcpd_pid
	ip_mask=`tdb get Network LeaseStart_ss | cut -d'.' -f1-3`
	lease_str=`/usr/bin/dumpleases -f /tmp/udhcpd.leases | grep $ip_mask`
else
	exit 1
fi

if [ -z "$lease_str" ]
then
	tdb set Wireless AP_Enable_byte=0
	/sbin/wifi-tool stop_ap &
fi
