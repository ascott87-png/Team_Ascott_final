#!/bin/sh

# udhcpc script edited by Tim Riker <Tim@Rikers.org>
dumpNetworkKeys() {
	echo -n "\
DHCPIPEnable_byte
DHCPDNSEnable_byte
LinkLocalIP_byte
Address_ss
Netmask_ss
Gateway_ss
DNS1_ms
DNS2_ms
SearchDomain_ls
"
}

getNTPClientKeys() {
  ntpEnable=$(tdb get NTPClient Enable_byte)
  dhcpNtpType=$(tdb get NTPClient DHCPNTPEnable_byte)
}

[ -z "$1" ] && echo "Error: should be called from udhcpc" && exit 1

RESOLV_CONF="/etc/resolv.conf"
[ -n "$broadcast" ] && BROADCAST="broadcast $broadcast"
[ -n "$subnet" ] && NETMASK="netmask $subnet"

case "$1" in
    deconfig)
		eval $(dumpNetworkKeys | tdb get Network)
        /sbin/ifconfig $interface 0.0.0.0
		if [ "$LinkLocalIP_byte" -eq 1 ]
		then
			median=$interface /etc/rc.d/init.d/zcip.sh restart
		else
			/sbin/ifconfig $interface $Address_ss netmask $Netmask_ss
			route add default gw $Gateway_ss $interface
		fi	
        ;;

    renew|bound)
    	[ $interface = "wlan0" ] && wlan stop_ap

	eval $(dumpNetworkKeys | tdb get Network)

	if [ "$DHCPIPEnable_byte" -ne 0 ]; then
		# from DHCP
        /sbin/ifconfig $interface $ip $BROADCAST $NETMASK

	kill -USR1 `cat /tmp/wifi-led.pid`

        echo $ip > /tmp/dhcptemp.log.new
        echo $interface >> /tmp/dhcptemp.log.new
        echo $broadcast >> /tmp/dhcptemp.log.new
        echo $subnet >> /tmp/dhcptemp.log.new
        echo $router >> /tmp/dhcptemp.log.new
        echo $metric >> /tmp/dhcptemp.log.new
        echo $domain >> /tmp/dhcptemp.log.new
        echo $dns >> /tmp/dhcptemp.log.new

	[ -f /tmp/dhcptemp.log ] && ret=`diff -q /tmp/dhcptemp.log.new /tmp/dhcptemp.log` || ret=255
	mv /tmp/dhcptemp.log.new /tmp/dhcptemp.log

        if [ -n "$router" ] ; then
            echo "deleting routers"
            while route del default gw 0.0.0.0 dev $interface ; do
                :
            done

            metric=0
            for i in $router ; do
                metric=`expr $metric + 1`
                route add default gw $i dev $interface metric $metric
            done
        fi
	else
		if [ "$LinkLocalIP_byte" -ne 0 ]; then
			# link local
			median=$interface /etc/rc.d/init.d/zcip.sh restart
		else
			# static
			/sbin/ifconfig $interface $Address_ss netmask $Netmask_ss up
			while route del default gw 0.0.0.0 dev $interface ; do
				:
			done
			route add default gw $Gateway_ss dev $interface
		fi
	fi
    echo -n > $RESOLV_CONF
	if [ "$DHCPDNSEnable_byte" -ne 0 ]; then
		# from DHCP
		[ -n "$domain" ] && echo search $domain >> $RESOLV_CONF
		for i in $dns ; do
		    echo adding dns $i
		    echo nameserver $i >> $RESOLV_CONF
		done
	else
		# manual
		[ "$SearchDomain_ls" ] && echo "search $SearchDomain_ls" >> $RESOLV_CONF
		[ "$DNS1_ms" ] && echo "nameserver $DNS1_ms" >> $RESOLV_CONF
		[ "$DNS2_ms" ] && echo "nameserver $DNS2_ms" >> $RESOLV_CONF
	fi

	[ $interface = "wlan0" ] && touch /tmp/wifiConnected
	[ $interface = "wlan0" ] && kill -USR1 `cat /tmp/wifiAutoReconnect.pid`
	#send link up cmd
	send_cmd watchdog 636 > /dev/null 2> /dev/null

	# Restart daemons which need to restart when IP/interface change. 
	if [ $ret -ne 0 ] && [ -x "/etc/rc.d/init.d/network_services.sh" ]; then
		/etc/rc.d/init.d/network_services.sh restart
	fi

	# notify goahead when the WAN IP has been acquired. --yy
	#killall -SIGUSR2 goahead

	# restart igmpproxy daemon
	#config-igmpproxy.sh

        ;;
esac

exit 0

