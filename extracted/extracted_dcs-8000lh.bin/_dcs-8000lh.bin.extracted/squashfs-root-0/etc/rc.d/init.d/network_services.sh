#!/bin/sh

die() {
	echo $@
	exit 1
}

showUsage() {
	die "$0 {start|stop|restart|status} [prefix]"
}

setWlanInterface() {
	median=$(tdb get Wireless STA_DEV_ms)
	[ -z $median ] && median=apcli0
}            

IPv6keys() {
	IPv6type=$(tdb get IPv6 Enable_byte)
	if [ $IPv6type -ne 0 ]
	then
		return 1
	else
		return 0
	fi
}

conf_ipv6() {
	echo 0 > /proc/sys/net/ipv6/conf/$median/autoconf
	echo 0 >/proc/sys/net/ipv6/conf/$median/accept_ra
	/sbin/ipv6_release

	[ -f "/tmp/ipv6_invalid" ] && rm -f /var/lib/dibbler/*
	[ -f "/tmp/ipv6_invalid" ] && rm -f /tmp/ipv6_invalid

	ipv6_autoip=$(tdb get IPv6 AutoIP_byte)
	ipv6_manualip=$(tdb get IPv6 ManualIP_byte)
	if [ "$ipv6_autoip" = "1" ] && [ "$ipv6_manualip" = "0" ]; then
		echo 1 > /proc/sys/net/ipv6/conf/$median/autoconf
		echo 1 >/proc/sys/net/ipv6/conf/$median/accept_ra
		[ -e /etc/dibbler/client.conf ] && sed -i -r -e "s@iface .*@iface $median@" /etc/dibbler/client.conf
#		[ -x /sbin/dibbler-client ] && /sbin/dibbler-client start || return 1
		/etc/rc.d/init.d/dibbler.sh start 
		return 0
	elif [ "$ipv6_autoip" = "0" ] && [ "$ipv6_manualip" = "1" ]; then
		echo 0 > /proc/sys/net/ipv6/conf/$median/autoconf	
		ipv6_address=$(tdb get IPv6 Address_ls)
		ipv6_prefix=$(tdb get IPv6 Prefix_byte)
		ipv6_gateway=$(tdb get IPv6 Gateway_ls)
		ipv6_dns1=$(tdb get IPv6 PrimaryDNS_ls)
		ipv6_dns2=$(tdb get IPv6 SecondDNS_ls)
		ip addr add $ipv6_address/$ipv6_prefix dev $median || return 1

		#If ipv6 gateway doesn't begin with "fe80", then it have to add network ID before default route.
		ipv6_gateway_network_id=$(/sbin/ipv6_get_network_id $ipv6_gateway $ipv6_prefix $ipv6_gateway)
                ipv6_gateway_network_id_prefix=$(echo $ipv6_gateway_network_id | cut -d ":" -f1)
                if [ $ipv6_gateway_network_id_prefix != 'fe80' ]; then
                        ip -6 route add $ipv6_gateway/$ipv6_prefix dev $ipv6_interface
                fi 

		#other way to do routing settings
		#ip -6 route del ::/0 via fe80::248:54ff:fe5b:cb9d dev eth0
		#ip -6 route add ::/0 via fe80::248:54ff:fe5b:cb99 dev eth0
		route -A inet6 add ::/0 gw $ipv6_gateway dev $median
		if [ "$?" = "0" ]; then
			[ "$ipv6_dns1" != "" ] && echo "nameserver $ipv6_dns1" >> /etc/resolv.conf
			[ "$ipv6_dns2" != "" ] && echo "nameserver $ipv6_dns2" >> /etc/resolv.conf
		else
			ip addr del $ipv6_address/$ipv6_prefix dev $median && return 1
		fi
		return 0
	else
		return 1
	fi
}

start() {
	echo start network services, ...
	/etc/rc.d/init.d/firewall.sh stop
	IPv6keys
	IPv6=$?
	if [ $IPv6 -eq 1 ]
	then
		/etc/rc.d/init.d/dibbler.sh stop
		conf_ipv6
	fi
	[ -x "/etc/rc.d/init.d/finderd.sh" ] && /etc/rc.d/init.d/finderd.sh start
	[ -x "/etc/rc.d/init.d/portForwarder.sh" ] && /etc/rc.d/init.d/portForwarder.sh reload
	[ -x "/etc/rc.d/init.d/godev.sh" ] && /etc/rc.d/init.d/godev.sh start
	[ -x "/etc/rc.d/init.d/mDNSResponder.sh" ] && /etc/rc.d/init.d/mDNSResponder.sh start
	[ -x "/etc/rc.d/init.d/upnp_av.sh" ] && /etc/rc.d/init.d/upnp_av.sh start
	[ -x "/etc/rc.d/init.d/upnp_av_ipv6.sh" ] && /etc/rc.d/init.d/upnp_av_ipv6.sh start
	[ -x "/etc/rc.d/init.d/upnp_dev.sh" ] && /etc/rc.d/init.d/upnp_dev.sh start
	[ -x "/etc/rc.d/init.d/discovery.sh" ] && /etc/rc.d/init.d/discovery.sh start
	[ -x "/etc/rc.d/init.d/transpeer.sh" ] && /etc/rc.d/init.d/transpeer.sh start
	[ -x "/etc/rc.d/init.d/lld2d.sh" ] && /etc/rc.d/init.d/lld2d.sh start 
	[ -x "/etc/rc.d/init.d/rtpd.sh" ] && /etc/rc.d/init.d/rtpd.sh start
	[ -x "/etc/rc.d/init.d/rtspd.sh" ] && /etc/rc.d/init.d/rtspd.sh start
	[ -x "/etc/rc.d/init.d/lighttpd.sh" ] && /etc/rc.d/init.d/lighttpd.sh start
	[ -x "/etc/rc.d/init.d/ddnsUpdater.sh" ] && /etc/rc.d/init.d/ddnsUpdater.sh reload
	[ -x "/etc/rc.d/init.d/ntpd.sh" ] && /etc/rc.d/init.d/ntpd.sh start
	[ -x "/opt/opt.local" ] && /opt/opt.local start > /dev/null 2> /dev/null 
	/etc/rc.d/init.d/firewall.sh start
}

status() {
	echo status of network services, ...
	[ -x "/etc/rc.d/init.d/finderd.sh" ] && /etc/rc.d/init.d/finderd.sh status
	[ -x "/etc/rc.d/init.d/portForwarder.sh" ] && /etc/rc.d/init.d/portForwarder.sh status
	[ -x "/etc/rc.d/init.d/godev.sh" ] && /etc/rc.d/init.d/godev.sh status
	[ -x "/etc/rc.d/init.d/mDNSResponder.sh" ] && /etc/rc.d/init.d/mDNSResponder.sh status
	[ -x "/etc/rc.d/init.d/upnp_av.sh" ] && /etc/rc.d/init.d/upnp_av.sh status
	[ -x "/etc/rc.d/init.d/upnp_av_ipv6.sh" ] && /etc/rc.d/init.d/upnp_av_ipv6.sh status
	[ -x "/etc/rc.d/init.d/upnp_dev.sh" ] && /etc/rc.d/init.d/upnp_dev.sh status
	[ -x "/etc/rc.d/init.d/transpeer.sh" ] && /etc/rc.d/init.d/transpeer.sh status
	[ -x "/etc/rc.d/init.d/discovery.sh" ] && /etc/rc.d/init.d/discovery.sh status
	[ -x "/etc/rc.d/init.d/lld2d.sh" ] && /etc/rc.d/init.d/lld2d.sh status
	[ -x "/etc/rc.d/init.d/rtpd.sh" ] && /etc/rc.d/init.d/rtpd.sh status
	[ -x "/etc/rc.d/init.d/rtspd.sh" ] && /etc/rc.d/init.d/rtspd.sh status
	[ -x "/etc/rc.d/init.d/lighttpd.sh" ] && /etc/rc.d/init.d/lighttpd.sh status
	[ -x "/etc/rc.d/init.d/ddnsUpdater.sh" ] && /etc/rc.d/init.d/ddnsUpdater.sh status
	[ -x "/etc/rc.d/init.d/ntpd.sh" ] && /etc/rc.d/init.d/ntpd.sh status
}

stop() {
	local daemons=""
	local test_count=0
	IPv6keys
	IPv6=$?
	if [ $IPv6 -eq 1 ]
	then
		[ -x "/etc/rc.d/init.d/dibbler.sh" ] && piddibbler=$(pidof dibbler-client)
	fi
	[ -x "/etc/rc.d/init.d/finderd.sh" ] && pidfinderd=$(pidof finderd)
	[ -x "/etc/rc.d/init.d/mDNSResponder.sh" ] && pidmDNSResponder=$(pidof mDNSResponder)
	[ -x "/etc/rc.d/init.d/upnp_av.sh" ] && pidorthrus=$(pidof orthrus)
	[ -x "/etc/rc.d/init.d/upnp_av_ipv6.sh" ] && pidorthrusipv6=$(pidof orthrusipv6)
	[ -x "/etc/rc.d/init.d/discovery.sh" ] && piddiscovery=$(pidof discovery)
	[ -x "/etc/rc.d/init.d/lld2d.sh" ] && pidlld2d=$(pidof lld2d)
	[ -x "/etc/rc.d/init.d/rtpd.sh" ] && pidrtpd=$(pidof rtpd)
	[ -x "/etc/rc.d/init.d/rtspd.sh" ] && pidrtspd=$(pidof rtspd)
	[ -x "/etc/rc.d/init.d/lighttpd.sh" ] && pidlighttpd=$(pidof lighttpd)
	[ -x "/etc/rc.d/init.d/lighttpd_ssl.sh" ] && pidlighttpdssl=$(pidof lighttpd_ssl)
	[ -x "/etc/rc.d/init.d/ntpd.sh" ] && pidntpd=$(pidof ntpd)

	[ "$piddibbler" != "" ] && daemons="dibbler-client $daemons"
	[ "$pidfinderd" != "" ] && daemons="finderd $daemons"
	[ "$pidorthrus" != "" ] && daemons="orthrus $daemons"
	[ "$pidorthrusipv6" != "" ] && daemons="orthrusipv6 $daemons"
	[ "$piddiscovery" != "" ] && daemons="discovery $daemons"
	[ "$pidlld2d" != "" ] && daemons="lld2d $daemons"
	[ "$pidrtpd" != "" ] && daemons="rtpd $daemons"
	[ "$pidrtspd" != "" ] && daemons="rtspd $daemons"
	[ "$pidlighttpd" != "" ] && daemons="lighttpd $daemons"
	[ "$pidlighttpdssl" != "" ] && daemons="lighttpd_ssl $daemons"
	[ "$pidntpd" != "" ] && daemons="ntpd $daemons"

	[ -x "/opt/opt.local" ] && /opt/opt.local stop > /dev/null 2> /dev/null 
	[ -x "/etc/rc.d/init.d/godev.sh" ] && /etc/rc.d/init.d/godev.sh stop > /dev/null 2> /dev/null
	[ -x "/etc/rc.d/init.d/transpeer.sh" ] && /etc/rc.d/init.d/transpeer.sh stop > /dev/null 2> /dev/null
	[ "$piddibbler" != "" ] && kill -s SIGUSR2 $piddibbler > /dev/null 2> /dev/null
	[ "$pidlighttpd" != "" ] && send_cmd watchdog 777 0 0 > /dev/null 2> /dev/null
	[ "$pidmDNSResponder" != "" ] && kill -s SIGQUIT $pidmDNSResponder > /dev/null 2> /dev/null

	killall -9 $daemons > /dev/null 2> /dev/null
	sleep 1
	while true; do
		pids=$(pidof $daemons) || return 0
		echo $daemons is not stop clearly
		killall $daemons > /dev/null 2> /dev/null
		sleep 1
		let test_count=test_count+1
		if [ $test_count -ge 2 ]; then
			killall -9 $daemons > /dev/null 2> /dev/null
			return 0
		fi
	done
}



action=$1
prefix=$2
end=$3

[ "$end" = "" ] && [ "$action" != "" ] || showUsage
[ "$prefix" = "" ] || [ -d "$prefix" ] || die "$prefix is not a valid directory"

setWlanInterface

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
