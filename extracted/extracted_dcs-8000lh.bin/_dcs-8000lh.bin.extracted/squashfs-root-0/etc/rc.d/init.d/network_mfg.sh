#!/bin/sh

network_setup

exit 0

daemon=network
PATH=$PATH:/sbin
interfaces=/etc/network/interfaces
resolv=/etc/resolv.conf
extraScriptPath="/mnt/usb"
export hwboard=`pibinfo HWBoard`

die() {
	echo $@
	exit 1
}

showUsage() {
	die "$0 {start|stop|plugin|plugout|restart|status} [prefix]"
}

probeMTDongle() {
	cat /proc/bus/usb/devices | grep -q 'Vendor=148f'
}

setWlanInterface() {
	median=$(tdb get Wireless STA_DEV_ms)
	[ -z $median ] && median=apcli0
}            

setEdcca()
{
	if probeMTDongle; then
		iwpriv ra0 set ed_false_cca_th=3000
		iwpriv ra0 set ed_chk=1
	else
		iwpriv wlan0 set ed_false_cca_th=400
		iwpriv wlan0 set ed_chk=1
	fi
}

probeWireless() {
#	[ "$(pibinfo Wireless)" -eq 1 ]
	return 0
}

singleProbeLink() {
	ethtool eth0 2> /dev/null | grep -q "Link detected: yes"
}

probeLink() {
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

dumpNetworkKeys() {
	echo -n "\
DHCPIPEnable_byte
DHCPDNSEnable_byte
LinkLocalIP_byte
Address_ss
Netmask_ss
Gateway_ss
DNS1_ss
DNS2_ss
SearchDomain_ls
"
}

getNTPClientKeys() {
ntpEnable=$(tdb get NTPClient Enable_byte)
dhcpNtpType=$(tdb get NTPClient DHCPNTPEnable_byte)
if [ "$ntpEnable" -eq "0" ]; then
	NTPFromDHCP=0
elif [ "$ntpEnable" -eq "1" ] && [ "$dhcpNtpType" -eq "1" ]; then
	NTPFromDHCP=0
else
	NTPFromDHCP=1
fi
}

dumpPPPoEKeys() {
	echo -n "\
Enable_byte
User_ms
Password_ms
"
}

dumpWirelessKeys() {
	echo -n "\
Enable_byte
Mode_byte
Channel_num
AuthMode_byte
SecMethod_byte
ESSID_ms
Key_ls
WepKeyIndex_byte
extAntenna_byte
AP_CH_ms
AP_Enable_byte
"
}

dumpHost() {
	echo -n "\
CameraName_ms
"
}

dumpSystem() {
	echo -n "\
Model_ss
OEMVersion_ss
"
}

dumpDNS() {
	[ "$SearchDomain_ls" ] && echo "search $SearchDomain_ls"
	[ "$DNS1_ss" ] && echo nameserver $DNS1_ss
	[ "$DNS2_ss" ] && echo nameserver $DNS2_ss
}

dumpLinkLocalIP() {
	echo -n "\
iface $1 inet static
	address $Address_ss
	netmask $Netmask_ss
	gateway $Gateway_ss
	up ( median=$median /etc/rc.d/init.d/zcip.sh restart )
"
}

dumpStatic() {
	echo -n "\
iface $1 inet static
	address $Address_ss
	netmask $Netmask_ss
	gateway $Gateway_ss
"
}

dumpDHCP() {
	echo -n "\
iface $1 inet dhcp
	hostname $(quote encode "$CameraName_ms")
"
}

makeupStatic() {
	dumpStatic $1 >> $interfaces
	dumpDNS >> $resolv
	return 0
}

makeupLinkLocalIP() {
	dumpLinkLocalIP $1 >> $interfaces
	dumpDNS >> $resolv
	return 0
}

makeupDHCP() {
	dumpDHCP $1 >> $interfaces
	return 0
}

makeupFallback() {
	dumpStatic fallback >> $interfaces
	return 0
}

dumpOpen_APCLI() {
	[ "$SecMethod_byte" -eq 0 ] && dumpNoEncry_APCLI || dumpWEP_APCLI
}

dumpNoEncry_APCLI() {
	echo -n "\
	pre-up iwpriv apcli0 set ApCliEnable=0
	pre-up iwpriv apcli0 set ApCliAuthMode=OPEN
	pre-up iwpriv apcli0 set ApCliEncrypType=NONE
	pre-up iwpriv apcli0 set ApCliSsid=$(quote encode "$ESSID_ms")
	pre-up iwpriv apcli0 set ApCliEnable=1
"
}

dumpWEPAUTO_APCLI() {
	echo -n "\
	pre-up iwpriv apcli0 set ApCliEnable=0
	pre-up iwpriv apcli0 set ApCliAuthMode=WEPAUTO
	pre-up iwpriv apcli0 set ApCliEncrypType=WEP
	pre-up iwpriv apcli0 set ApCliDefaultKeyID="$WepKeyIndex_byte"
	pre-up iwpriv apcli0 set ApCliKey"$WepKeyIndex_byte"=$(quote encode "$Key_ls") || true
	pre-up iwpriv apcli0 set ApCliSsid=$(quote encode "$ESSID_ms")
	pre-up iwpriv apcli0 set ApCliEnable=1
"
}

dumpWEP_APCLI() {
	echo -n "\
	pre-up iwpriv apcli0 set ApCliEnable=0
	pre-up iwpriv apcli0 set ApCliAuthMode=WEPAUTO
	pre-up iwpriv apcli0 set ApCliEncrypType=WEP
	pre-up iwpriv apcli0 set ApCliDefaultKeyID="$WepKeyIndex_byte"
	pre-up iwpriv apcli0 set ApCliKey"$WepKeyIndex_byte"=$(quote encode "$Key_ls") || true
	pre-up iwpriv apcli0 set ApCliSsid=$(quote encode "$ESSID_ms")
	pre-up iwpriv apcli0 set ApCliEnable=1
"
}

dumpShared_APCLI() {
	echo -n "\
	pre-up iwpriv apcli0 set ApCliEnable=0
	pre-up iwpriv apcli0 set ApCliAuthMode=WEPAUTO
	pre-up iwpriv apcli0 set ApCliEncrypType=WEP
	pre-up iwpriv apcli0 set ApCliDefaultKeyID="$WepKeyIndex_byte"
	pre-up iwpriv apcli0 set ApCliKey"$WepKeyIndex_byte"=$(quote encode "$Key_ls") || true
	pre-up iwpriv apcli0 set ApCliSsid=$(quote encode "$ESSID_ms")
	pre-up iwpriv apcli0 set ApCliEnable=1
"
}

dumpWPSPSK_APCLI() {
	echo -n "\
	pre-up iwpriv apcli0 set ApCliEnable=0
	pre-up iwpriv apcli0 set ApCliAuthMode=WPAPSK
	pre-up iwpriv apcli0 set ApCliEncrypType=$(dumpEncryMethod)
	pre-up iwpriv apcli0 set ApCliSsid=$(quote encode "$ESSID_ms")
	pre-up iwpriv apcli0 set ApCliWPAPSK=$(quote encode "$Key_ls") || true
	pre-up iwpriv apcli0 set ApCliSsid=$(quote encode "$ESSID_ms")
	pre-up iwpriv apcli0 set ApCliEnable=1
"
}

dumpWPS2PSK_APCLI() {
	echo -n "\
	pre-up iwpriv apcli0 set ApCliEnable=0
	pre-up iwpriv apcli0 set ApCliAuthMode=WPA2PSK
	pre-up iwpriv apcli0 set ApCliEncrypType=$(dumpEncryMethod)
	pre-up iwpriv apcli0 set ApCliSsid=$(quote encode "$ESSID_ms")
	pre-up iwpriv apcli0 set ApCliWPAPSK=$(quote encode "$Key_ls") || true
	pre-up iwpriv apcli0 set ApCliSsid=$(quote encode "$ESSID_ms")
	pre-up iwpriv apcli0 set ApCliEnable=1
"
}

dumpKey_APCLI() {
	echo -n "\
	pre-up ifconfig apcli0 0.0.0.0 up  || true
	pre-up iwpriv ra0 set CountryRegion=$Region
	pre-up iwpriv ra0 set RadioOn=1
	pre-up /sbin/wifi-tool channel_update
	pre-up wlan infra
	pre-up iwpriv ra0 set SiteSurvey=1
" >> $interfaces
}

makeupWireless_APCLI() {
	wireless_enable=$(tdb get Wireless Enable_byte)
	[ "$wireless_enable" = "0" ] && return 0
	echo auto apcli0 >> $interfaces
	if [ "$DHCPEnable_byte" -eq 1 ]; then
		makeupDHCP apcli0
	elif [ "$LinkLocalIP_byte" -eq 1 ]; then
		makeupLinkLocalIP apcli0
	else
		makeupStatic apcli0
	fi
	dumpKey_APCLI
}

dumpOpen_STA() {
	[ "$SecMethod_byte" -eq 0 ] && dumpNoEncry_STA || dumpWEP_STA
}

dumpNoEncry_STA() {
	echo -n "\
	pre-up iwpriv ra0 set NetworkType=Infra
	pre-up iwpriv ra0 set AuthMode=OPEN
	pre-up iwpriv ra0 set EncrypType=NONE
	pre-up iwpriv ra0 set SSID=$(quote encode "$ESSID_ms")
"
}

dumpWEPAUTO_STA() {
	echo -n "\
	pre-up iwpriv ra0 set NetworkType=Infra
	pre-up iwpriv ra0 set AuthMode=WEPAUTO
	pre-up iwpriv ra0 set EncrypType=WEP
	pre-up iwpriv ra0 set DefaultKeyID="$WepKeyIndex_byte"
	pre-up iwpriv ra0 set Key"$WepKeyIndex_byte"=$(quote encode "$Key_ls") || true
	pre-up iwpriv ra0 set SSID=$(quote encode "$ESSID_ms")
"
}

dumpWEP_STA() {
	echo -n "\
	pre-up iwpriv ra0 set NetworkType=Infra
	pre-up iwpriv ra0 set AuthMode=WEPAUTO
	pre-up iwpriv ra0 set EncrypType=WEP
	pre-up iwpriv ra0 set DefaultKeyID="$WepKeyIndex_byte"
	pre-up iwpriv ra0 set Key"$WepKeyIndex_byte"=$(quote encode "$Key_ls") || true
	pre-up iwpriv ra0 set SSID=$(quote encode "$ESSID_ms")
"
}

dumpShared_STA() {
	echo -n "\
	pre-up iwpriv ra0 set NetworkType=Infra
	pre-up iwpriv ra0 set AuthMode=WEPAUTO
	pre-up iwpriv ra0 set EncrypType=WEP
	pre-up iwpriv ra0 set DefaultKeyID="$WepKeyIndex_byte"
	pre-up iwpriv ra0 set Key"$WepKeyIndex_byte"=$(quote encode "$Key_ls") || true
	pre-up iwpriv ra0 set SSID=$(quote encode "$ESSID_ms")
"
}

dumpWPSPSK_STA() {
	echo -n "\
	pre-up iwpriv ra0 set NetworkType=Infra
	pre-up iwpriv ra0 set AuthMode=WPAPSK
	pre-up iwpriv ra0 set EncrypType=$(dumpEncryMethod)
	pre-up iwpriv ra0 set SSID=$(quote encode "$ESSID_ms")
	pre-up iwpriv ra0 set WPAPSK=$(quote encode "$Key_ls") || true
	pre-up iwpriv ra0 set SSID=$(quote encode "$ESSID_ms")
"
}

dumpWPS2PSK_STA() {
	echo -n "\
	pre-up iwpriv ra0 set NetworkType=Infra
	pre-up iwpriv ra0 set AuthMode=WPA2PSK
	pre-up iwpriv ra0 set EncrypType=$(dumpEncryMethod)
	pre-up iwpriv ra0 set SSID=$(quote encode "$ESSID_ms")
	pre-up iwpriv ra0 set WPAPSK=$(quote encode "$Key_ls") || true
	pre-up iwpriv ra0 set SSID=$(quote encode "$ESSID_ms")
"
}

dumpKey_STA() {
	echo -n "\
	pre-up ifconfig ra0 0.0.0.0 up  || true
	pre-up iwpriv ra0 set CountryRegion=$Region
	pre-up iwpriv ra0 set RadioOn=1
	pre-up /sbin/wifi-tool channel_update
" >> $interfaces
		case $AuthMode_byte in
		0)
			dumpOpen_STA
			;;
		1)
			dumpShared_STA
			;;
		2)
			dumpWPSPSK_STA
			;;
		5)
			dumpWPS2PSK_STA
			;;
		6)
			dumpWEPAUTO_STA
			;;
		*)
			dumpNoEncry_STA
			;;
		esac >> $interfaces
}

makeupWireless_STA() {
	wireless_enable=$(tdb get Wireless Enable_byte)
	[ "$wireless_enable" = "0" ] && return 0
	echo auto ra0 >> $interfaces
	if [ "$DHCPEnable_byte" -eq 1 ]; then
		makeupDHCP ra0
	elif [ "$LinkLocalIP_byte" -eq 1 ]; then
		makeupLinkLocalIP ra0
	else
		makeupStatic ra0
	fi
	dumpKey_STA
}

dumpAdhoc() {
	echo -n "\
	pre-up iwpriv wlan0 set NetworkType=Adhoc
	pre-up iwpriv wlan0 set AuthMode=OPEN
	pre-up iwpriv wlan0 set EncrypType=NONE
	$([ "$Channel_num" -ne 0 ] && echo -n "pre-up iwpriv wlan0 set Channel=$Channel_num")
	pre-up iwpriv wlan0 set SSID=$(quote encode "$ESSID_ms")
"
}

dumpAdhocWEP() {
	echo -n "\
	pre-up iwpriv wlan0 set NetworkType=Adhoc
	pre-up iwpriv wlan0 set AuthMode=WEPAUTO
	pre-up iwpriv wlan0 set EncrypType=WEP
	pre-up iwpriv wlan0 set DefaultKeyID="$WepKeyIndex_byte"
	$([ "$Channel_num" -ne 0 ] && echo -n "pre-up iwpriv wlan0 set Channel=$Channel_num")
	pre-up iwpriv wlan0 set SSID=$(quote encode "$ESSID_ms")
	pre-up iwpriv wlan0 set Key"$WepKeyIndex_byte"=$(quote encode "$Key_ls") || true
"
}

dumpOpen() {
	[ "$SecMethod_byte" -eq 0 ] && dumpNoEncry || dumpWEP
}

dumpNoEncry() {
	echo -n "\
	pre-up wpa_cli disconnect
	pre-up wpa_cli remove_network 0
	pre-up wpa_cli add_network 
	pre-up wpa_cli set_network 0 auth_alg OPEN
	pre-up wpa_cli set_network 0 key_mgmt NONE
	pre-up wpa_cli set_network 0 mode 0 
	pre-up wpa_cli set_network 0 ssid '$(quote encode "$ESSID_ms")'
	pre-up wpa_cli select_network 0 
	pre-up wpa_cli enable_network 0
	pre-up wpa_cli reassociate
"
}

dumpWEPAUTO() {
	echo -n "\
	pre-up wpa_cli disconnect
	pre-up wpa_cli remove_network 0
	pre-up wpa_cli add_network 
	pre-up wpa_cli set_network 0 auth_alg OPEN
	pre-up wpa_cli set_network 0 key_mgmt NONE
	pre-up wpa_cli set_network 0 wep_key$WepKeyIndex '$(quote wep_key "$Key_ls")'
	pre-up wpa_cli set_network 0 wep_tx_keyidx $WepKeyIndex 
	pre-up wpa_cli set_network 0 mode 0 
	pre-up wpa_cli set_network 0 ssid '$(quote encode "$ESSID_ms")'
	pre-up wpa_cli select_network 0 
	pre-up wpa_cli enable_network 0
	pre-up wpa_cli reassociate
"
}

dumpWEP() {
	echo -n "\
	pre-up wpa_cli disconnect
	pre-up wpa_cli remove_network 0
	pre-up wpa_cli add_network 
	pre-up wpa_cli set_network 0 auth_alg OPEN
	pre-up wpa_cli set_network 0 key_mgmt NONE
	pre-up wpa_cli set_network 0 wep_key$WepKeyIndex '$(quote wep_key "$Key_ls")'
	pre-up wpa_cli set_network 0 wep_tx_keyidx $WepKeyIndex
	pre-up wpa_cli set_network 0 mode 0 
	pre-up wpa_cli set_network 0 ssid '$(quote encode "$ESSID_ms")'
	pre-up wpa_cli select_network 0 
	pre-up wpa_cli enable_network 0
	pre-up wpa_cli reassociate
"
}

dumpShared() {
	echo -n "\
	pre-up wpa_cli disconnect
	pre-up wpa_cli remove_network 0
	pre-up wpa_cli add_network 
	pre-up wpa_cli set_network 0 auth_alg SHARED
	pre-up wpa_cli set_network 0 key_mgmt NONE
	pre-up wpa_cli set_network 0 wep_key$WepKeyIndex '$(quote wep_key "$Key_ls")'
	pre-up wpa_cli set_network 0 wep_tx_keyidx $WepKeyIndex
	pre-up wpa_cli set_network 0 mode 0 
	pre-up wpa_cli set_network 0 ssid '$(quote encode "$ESSID_ms")'
	pre-up wpa_cli select_network 0 
	pre-up wpa_cli enable_network 0
	pre-up wpa_cli reassociate
"
}

dumpEncryMethod() {
	case $SecMethod_byte in
	0)
		echo NONE
		;;
	1)
		echo WEP
		;;
	2)
		echo TKIP
		;;
	3)
		if probeMTDongle; then
			echo AES
		else
			echo CCMP
		fi
		;;
	*)
		echo NONE
		;;
	esac
}

dumpWPSPSK() {
	echo -n "\
	pre-up wpa_cli disconnect
	pre-up wpa_cli remove_network 0
	pre-up wpa_cli add_network 
	pre-up wpa_cli set_network 0 auth_alg OPEN
	pre-up wpa_cli set_network 0 key_mgmt WPA-PSK
	pre-up wpa_cli set_network 0 psk '$(quote wpapsk "$Key_ls")'
	pre-up wpa_cli set_network 0 pairwise $(dumpEncryMethod)
	pre-up wpa_cli set_network 0 group $(dumpEncryMethod)
	pre-up wpa_cli set_network 0 proto WPA
	pre-up wpa_cli set_network 0 mode 0 
	pre-up wpa_cli set_network 0 ssid '$(quote encode "$ESSID_ms")'
	pre-up wpa_cli select_network 0 
	pre-up wpa_cli enable_network 0
	pre-up wpa_cli reassociate
"
}

dumpWPS2PSK() {
	echo -n "\
	pre-up wpa_cli disconnect
	pre-up wpa_cli remove_network 0
	pre-up wpa_cli add_network 
	pre-up wpa_cli set_network 0 auth_alg OPEN
	pre-up wpa_cli set_network 0 key_mgmt WPA-PSK
	pre-up wpa_cli set_network 0 psk '$(quote wpapsk "$Key_ls")'
	pre-up wpa_cli set_network 0 pairwise $(dumpEncryMethod)
	pre-up wpa_cli set_network 0 group $(dumpEncryMethod)
	pre-up wpa_cli set_network 0 proto RSN
	pre-up wpa_cli set_network 0 mode 0 
	pre-up wpa_cli set_network 0 ssid '$(quote encode "$ESSID_ms")'
	pre-up wpa_cli select_network 0 
	pre-up wpa_cli enable_network 0
	pre-up wpa_cli reassociate
"
}

# TODO: if WirelessMode is used, add it back before set CountryRegion
#	pre-up iwpriv wlan0 set WirelessMode=$WirelessMode

dumpKey() {
	# WLAN
	if probeMTDongle; then
		if [ $median = "apcli0" ]; then
			dumpKey_APCLI
		else
			dumpKey_STA
		fi
		return 0
	fi
	echo -n "\
	pre-up ifconfig wlan0 0.0.0.0 up  || true
" >> $interfaces

	# ad-hoc
	if [ "$Mode_byte" -eq 1 ]; then
		case $SecMethod_byte in
		1)
			dumpAdhocWEP
			;;
		*)
			dumpAdhoc
			;;
		esac
	else
		# infrastructure
		case $AuthMode_byte in
		0)
			dumpOpen
			;;
		1)
			dumpShared
			;;
		2)
			dumpWPSPSK
			;;
		5)
			dumpWPS2PSK
			;;
		6)
			dumpWEPAUTO
			;;
		*)
			dumpNoEncry
			;;
		esac
	fi >> $interfaces
}

makeupWireless() {
#	echo makeupWireless >> /tmp/debug
	if probeMTDongle; then
		if [ $median = "apcli0" ]; then
			makeupWireless_APCLI
		else
			makeupWireless_STA
		fi
		return 0
	fi
	wireless_enable=$(tdb get Wireless Enable_byte)
	[ "$wireless_enable" = "0" ] && return 0
	echo auto wlan0 >> $interfaces
	if [ "$DHCPEnable_byte" -eq 1 ]; then
		makeupDHCP wlan0
	elif [ "$LinkLocalIP_byte" -eq 1 ]; then
		makeupLinkLocalIP wlan0
	else
		makeupStatic wlan0
	fi
	dumpKey
}

makeupPPPoE() {
	echo -n "\
iface $1:1 inet ppp
    provider dsl-provider
" >> $interfaces

	cat > /etc/ppp/options << EOM
lock
plugin /lib/rp-pppoe.so $median
EOM

	cat > /etc/ppp/pap-secrets << EOM
"$User_ms" * "$Password_ms"
EOM

	cat > /etc/ppp/chap-secrets << EOM
"$User_ms" * "$Password_ms"
EOM

	cat > /etc/ppp/peers/dsl-provider << EOM
noipdefault
defaultroute 
hide-password
noauth
persist
usepeerdns
user "$User_ms"
lcp-echo-interval 20
lcp-echo-failure 6
EOM

	cat > /etc/ppp/resolv.conf << EOM
EOM
}

makeupWired() {
#	echo makeupWired >> /tmp/debug
	echo auto eth0 >> $interfaces
	if [ "$DHCPEnable_byte" -eq 1 ]; then
		makeupDHCP eth0
	elif [ "$LinkLocalIP_byte" -eq 1 ]; then
		makeupLinkLocalIP eth0
	else
		makeupStatic eth0
	fi
}

makeupNoLink() {
#	echo makeupNoLink >> /tmp/debug
	makeupStatic eth0
}

makeupConfs() {
	if [ ! probeMTDongle ]; then
		killall wpa_supplicant
		echo "ctrl_interface=/var/run/wpa_supplicant" > /tmp/wpa_supplicant.conf
		echo "device_type=4-0050F204-3" >> /tmp/wpa_supplicant.conf
		echo "model_name=$ModelName" >> /tmp/wpa_supplicant.conf
		wpa_supplicant -B -c /tmp/wpa_supplicant.conf -i wlan0 -P /tmp/wpa_supplicant.pid
	fi
	# clean
	echo -n > $interfaces
	echo -n > $resolv

#fix WEP AUTO
	[ "$SecMethod_byte" -eq 1 ] && { tdb set Wireless AuthMode_byte=6; AuthMode_byte=6; }

#makeupLoopback
	if [ "$senario" = 'wired' ]; then
		makeupWired
		if probeWireless; then
			# For setting up the country region, in case we need to do the site survey
			if probeMTDongle; then
				iwpriv ra0 set CountryRegion=$Region
				if [ "$WLANEnable_byte" -eq 1 ]; then
					dumpKey
					iwpriv ra0 set RadioOn=1 > /dev/null 2> /dev/null
					/sbin/wifi-tool channel_update
				else
					iwpriv ra0 set RadioOn=0 > /dev/null 2> /dev/null
				fi
			else
#				iwpriv wlan0 set CountryRegion=$Region
				if [ "$WLANEnable_byte" -eq 1 ]; then
					dumpKey
					ifconfig wlan0 up > /dev/null 2> /dev/null
				else
					ifconfig wlan0 down > /dev/null 2> /dev/null
				fi
			fi
		fi
		makeupWireless
	elif [ "$senario" = 'wireless' ]; then
		if [ "$WLANEnable_byte" -eq 1 ]; then
			makeupWireless
		fi
	else
		makeupNoLink
	fi
	if [ "$PPPoEEnable_byte" -eq 1 ]; then
		makeupPPPoE $median
	fi
	makeupFallback
}

linkLocalIPOK() {
	# check if failover to Link-Local IP or not
	[ "$LinkLocalIP_byte" -eq 0 ] && return 1
	echo "zcip action"
	median=$1 /etc/rc.d/init.d/zcip.sh restart
	return 0
}

dhcpOK() {
	# static and link-local cannot be failed
	[ "$DHCPEnable_byte" -eq 0 ] && return 0
	ifconfig "$1" | grep -q 'inet addr:' && return 0 || rm -f /tmp/dhcptemp.log
	return 1
}

confAutoconf() {
	ipv6_interface=eth0
	ipv6_autoip=$(tdb get IPv6 AutoIP_byte)
	ipv6_manualip=$(tdb get IPv6 ManualIP_byte)
	if [ "$ipv6_autoip" = "1" ] && [ "$ipv6_manualip" = "0" ]; then
		echo 1 > /proc/sys/net/ipv6/conf/$ipv6_interface/autoconf
		return 0
	elif [ "$ipv6_autoip" = "0" ] && [ "$ipv6_manualip" = "1" ]; then
		echo 0 > /proc/sys/net/ipv6/conf/$ipv6_interface/autoconf	
		return 0
	else
		return 1
	fi
}

confIPv6() {
	ipv6_interface=$median
	ipv6_autoip=$(tdb get IPv6 AutoIP_byte)
	ipv6_manualip=$(tdb get IPv6 ManualIP_byte)

	echo 0 > /proc/sys/net/ipv6/conf/$ipv6_interface/autoconf
	echo 0 > /proc/sys/net/ipv6/conf/$ipv6_interface/accept_ra
	/sbin/ipv6_release

	[ -f "/tmp/ipv6_invalid" ] && rm -f /var/lib/dibbler/*
	[ -f "/tmp/ipv6_invalid" ] && rm -f /tmp/ipv6_invalid

	if [ "$ipv6_autoip" = "1" ] && [ "$ipv6_manualip" = "0" ]; then
		echo 1 > /proc/sys/net/ipv6/conf/$ipv6_interface/autoconf
		echo 1 > /proc/sys/net/ipv6/conf/$ipv6_interface/accept_ra

		[ -e /etc/dibbler/client.conf ] && sed -i -r -e "s@iface .*@iface $ipv6_interface@" /etc/dibbler/client.conf
#		[ -x /sbin/dibbler-client ] && /sbin/dibbler-client start || return 1
		/etc/rc.d/init.d/dibbler.sh start 
		return 0
	elif [ "$ipv6_autoip" = "0" ] && [ "$ipv6_manualip" = "1" ]; then
		ipv6_address=$(tdb get IPv6 Address_ls)
		ipv6_prefix=$(tdb get IPv6 Prefix_byte)
		ipv6_gateway=$(tdb get IPv6 Gateway_ls)
		ipv6_dns1=$(tdb get IPv6 PrimaryDNS_ls)
		ipv6_dns2=$(tdb get IPv6 SecondDNS_ls)
		echo 0 > /proc/sys/net/ipv6/conf/$ipv6_interface/autoconf	
		ip addr add $ipv6_address/$ipv6_prefix dev $ipv6_interface || return 1

		#If ipv6 gateway doesn't begin with "fe80", then it have to add network ID before default route.
		ipv6_gateway_network_id=$(/sbin/ipv6_get_network_id $ipv6_gateway $ipv6_prefix $ipv6_gateway)
                ipv6_gateway_network_id_prefix=$(echo $ipv6_gateway_network_id | cut -d ":" -f1)
                if [ $ipv6_gateway_network_id_prefix != 'fe80' ]; then
                        ip -6 route add $ipv6_gateway/$ipv6_prefix dev $ipv6_interface
                fi 

		#other way to do routing settings
		#ip -6 route del ::/0 via fe80::248:54ff:fe5b:cb9d dev eth0
		#ip -6 route add ::/0 via fe80::248:54ff:fe5b:cb99 dev eth0
		route -A inet6 add ::/0 gw $ipv6_gateway dev $ipv6_interface
		if [ "$?" = "0" ]; then
			[ "$ipv6_dns1" != "" ] && echo "nameserver $ipv6_dns1" >> /etc/resolv.conf
			[ "$ipv6_dns2" != "" ] && echo "nameserver $ipv6_dns2" >> /etc/resolv.conf
		else
			ip addr del $ipv6_address/$ipv6_prefix dev $ipv6_interface && return 1
		fi
	else
		return 1 
	fi	
	return 0
}

detectLinkage() {
	old_setup=$median_senario
	# do some detection
	if probeLink || [ "$linkage" = "up" ]; then
		senario=wired
		median=eth0
		median_senario=eth0_wired
	elif [ "$WLANEnable_byte" -eq 1 ] && probeWireless; then
		senario=wireless
		if [ "$median" = "ra0" ]; then
			median_senario=ra0_wireless
		elif [ "$median" = "apcli0" ]; then
			median_senario=apcli0_wireless
		elif [ "$median" = "wlan0" ]; then
			median_senario=wlan0_wireless
		else
			median_senario=unknown_wireless
		fi
	else
		senario=nolink
		median=eth0
		median_senario=eth0_nolink
	fi
	echo -ne "\n$old_setup --> $median_senario\n" > /dev/console
}

start() {
	echo "==== Startting $daemon ===="

	eval $(dumpNetworkKeys | tdb get Network)
	getNTPClientKeys
	DHCPEnable_byte=1
	[ "$DHCPIPEnable_byte" -eq 0 ] && [ "$DHCPDNSEnable_byte" -eq 0 ] && [ "$NTPFromDHCP" -eq 0 ] && DHCPEnable_byte=0
	eval $(dumpPPPoEKeys | tdb get PPPoE)
	PPPoEEnable_byte=$Enable_byte
	eval $(dumpWirelessKeys | tdb get Wireless)
	WLANEnable_byte=$Enable_byte
	ESSID_ms=`tdb get Wireless ESSID_ms`
	Key_ls=`tdb get Wireless Key_ls`
	WepKeyIndex=`expr $WepKeyIndex_byte - 1`
	hadConnect_byte=`tdb get Wireless hadConnect_byte`
	eval $(pibinfo all)
	eval $(dumpHost | tdb get Host)
	eval $(dumpSystem | tdb get System)

	# enable/disable external antenna.
	[ "$extAntenna_byte" -eq "1" ] && light exAntenna on || light exAntenna off

	export median_senario=unknown
	export median
	export senario
	export old_setup

	detectLinkage
	while [ $median_senario != $old_setup ]; do
#{
	while [ $median_senario != $old_setup ]; do
##{

	# send linkup or linkdown to watchdog
	[ $senario = 'wired' ] &&
		{ send_cmd watchdog 636 > /dev/null 2> /dev/null; } || 
		{ send_cmd watchdog 637 > /dev/null 2> /dev/null; }
	
	if probeMTDongle; then
		if [ $senario = 'wired' ]; then
			/sbin/wifi-tool stop_ap
		elif [ "$hadConnect_byte" = "1" ]; then
			/sbin/wifi-tool stop_ap
		else
			ap_status=`/sbin/wifi-tool get ap_status | grep "wifi-tool ap_status : 1"`
			#[ $AP_Enable_byte -eq 1 ] && [ -z "$ap_status" ] && /sbin/wifi-tool start_ap
			[ -z "$ap_status" ] && /sbin/wifi-tool start_ap
		fi
	fi
	
	# Detect wireless associate status and send ASSOCIATED or DEASSOCIATED to watchdog
#	[ $senario = 'wireless' ] && /etc/rc.d/init.d/wirelessDectd.sh restart 

	# prepare interfaces and resolv.conf
	makeupConfs

	echo "== $median =="
	ifdown $median # ifdown interface before ifup
	confAutoconf $median
	ifup $median &
	dhcpOK $median || linkLocalIPOK $median || ifup -f $median=fallback
	/etc/rc.d/init.d/firewall.sh stop
	/etc/rc.d/init.d/dibbler.sh stop
	confIPv6 $median && echo "IPv6 is done." || echo "IPv6 is failed."
	hostname $CameraName_ms

	detectLinkage
	done
##}

	# Detect wireless associate status and send ASSOCIATED or DEASSOCIATED to watchdog
	[ probeMTDongle -a -x "/etc/rc.d/init.d/wifiAutoReconnect.sh" ] && /etc/rc.d/init.d/wifiAutoReconnect.sh restart 

	SD_CAP=$(pibinfo Peripheral | grep LocalStorage | cut -d "=" -f 2)       
	if [ $SD_CAP = '"1"' ]; then
		CNT=0
		# extra-network : If extra network scripts exist, run extra network setting.
		while [ ! -x "$extraScriptPath/extraNetwork.sh" ] && [ $CNT -le 600 ]; do echo "Count=$CNT" ; CNT=$(($CNT+1)) ; sleep 1; done
		[ -x "$extraScriptPath/extraNetwork.sh" ] && sh $extraScriptPath/extraNetwork.sh
		# end of extra network setting.
	fi


	[ -x "/etc/rc.d/init.d/portForwarder.sh" ] && /etc/rc.d/init.d/portForwarder.sh reload
	[ -x "/etc/rc.d/init.d/godev.sh" ] && /etc/rc.d/init.d/godev.sh reload
	# avoid default.script restart upnp_av/orthrus twice
	[ -x "/etc/rc.d/init.d/mDNSResponder.sh" ] && /etc/rc.d/init.d/mDNSResponder.sh start
	[ -x "/etc/rc.d/init.d/upnp_av.sh" ] && /etc/rc.d/init.d/upnp_av.sh start
	[ -x "/etc/rc.d/init.d/upnp_dev.sh" ] && /etc/rc.d/init.d/upnp_dev.sh restart

	if [ "$PPPoEEnable_byte" -eq 1 ]; then
		echo "== $median:1 =="
		ifdown $median:1 # ifdown interface before ifup
		ifup $median:1
		pidof pppd > /tmp/pppd.pid
	else
		[ -x "/etc/rc.d/init.d/ddnsUpdater.sh" ] && /etc/rc.d/init.d/ddnsUpdater.sh reload
	fi

	[ -x "/etc/rc.d/init.d/lld2d.sh" ] && /etc/rc.d/init.d/lld2d.sh start
	[ -x "/etc/rc.d/init.d/upnp_av_ipv6.sh" ] && /etc/rc.d/init.d/upnp_av_ipv6.sh start
	[ -x "/opt/opt.local" ] && /opt/opt.local stop > /dev/null 2> /dev/null
	[ -x "/opt/opt.local" ] && /opt/opt.local start > /dev/null 2> /dev/null 

	detectLinkage
	done
#}
	#Enable edcca in CE.
	if [ $Region -eq 1 ] 
	then
		setEdcca
	fi

	#Workaround of AP Enable/Disable mech
	if probeMTDongle; then
		[ "$hadConnect_byte" = "1" ] && ifconfig ra0 down

		#Pre site survey at back ground to speed up site survey result.
		$(iwpriv ra0 set SiteSurvey=1 ; sleep 4; iwpriv ra0 get_site_survey > /dev/null) &
	fi

	echo "==== start ok ===="
}

restart_lite() {
	# finally kill udhcpc, just in case
	killall udhcpc > /dev/null 2> /dev/null &
	# finally kill pppd
	killall pppd > /dev/null 2> /dev/null &
	rm -f /tmp/dhcpresult.log &
	rm -f /tmp/pppd.pid &
	senario=$1
	median=$2
	eval $(dumpNetworkKeys | tdb get Network)
	getNTPClientKeys
	DHCPEnable_byte=1
	[ "$DHCPIPEnable_byte" -eq 0 ] && [ "$DHCPDNSEnable_byte" -eq 0 ] && [ "$NTPFromDHCP" -eq 0 ] && DHCPEnable_byte=0 && /etc/rc.d/init.d/ntpd.sh restart > /dev/null 2>&1
	eval $(dumpPPPoEKeys | tdb get PPPoE)
	PPPoEEnable_byte=$Enable_byte
	eval $(dumpWirelessKeys | tdb get Wireless)
	WLANEnable_byte=$Enable_byte
	ESSID_ms=`tdb get Wireless ESSID_ms`
	Key_ls=`tdb get Wireless Key_ls`
	WepKeyIndex=`expr $WepKeyIndex_byte - 1`
	hadConnect_byte=`tdb get Wireless hadConnect_byte`
	eval $(pibinfo all)
	eval $(dumpHost | tdb get Host)
	eval $(dumpSystem | tdb get System)

	# enable/disable external antenna.
	[ "$extAntenna_byte" -eq "1" ] && light exAntenna on || light exAntenna off

	# send linkup or linkdown to watchdog
	[ $senario = 'wired' ] &&
		{ send_cmd watchdog 636 > /dev/null 2> /dev/null; } || 
		{ send_cmd watchdog 637 > /dev/null 2> /dev/null; }
	
	if probeMTDongle; then
		if [ $senario = 'wired' ]; then
			/sbin/wifi-tool stop_ap
		elif [ "$WLANEnable_byte" -eq 1 ]; then
			/sbin/wifi-tool stop_ap
		else	
			#[ -e "/tmp/booting" ] && [ $AP_Enable_byte -eq 1 ] && /sbin/wifi-tool start_ap
			/sbin/wifi-tool start_ap #  only see the 
		fi		
	fi

	# if eth0 unplug and wireless not enable 
	if [ $senario = 'wireless' ] && [ "$WLANEnable_byte" -eq 0 ];then
		return
	fi
	# Detect wireless associate status and send ASSOCIATED or DEASSOCIATED to watchdog
	if [ $senario = 'wireless' ] && [ "$WLANEnable_byte" -eq 1 ];then
		[ ! probeMTDongle ] && /etc/rc.d/init.d/wirelessDectd.sh restart
		disable eth0
	else
		median="eth0"
	fi
	
	# prepare interfaces and resolv.conf
	makeupConfs
	
	echo "setting $median..." > /dev/console
	
	ifdown $median
	confAutoconf $median
	#if up  will restart godev and transpeer
	ifup $median
	dhcpOK $median || linkLocalIPOK $median || ifup -f $median=fallback
	confIPv6 $median && echo "IPv6 is done." || echo "IPv6 is failed."
	
	[ probeMTDongle -a -x "/etc/rc.d/init.d/wifiAutoReconnect.sh" ] && /etc/rc.d/init.d/wifiAutoReconnect.sh restart 	
	[ -x "/etc/rc.d/init.d/portForwarder.sh" ] && /etc/rc.d/init.d/portForwarder.sh reload
	# avoid default.script restart upnp_av/orthrus twice
	[ -x "/etc/rc.d/init.d/upnp_av_ipv6.sh" ] && /etc/rc.d/init.d/upnp_av_ipv6.sh restart
	[ -x "/etc/rc.d/init.d/upnp_av.sh" ] && /etc/rc.d/init.d/upnp_av.sh restart
	[ -x "/etc/rc.d/init.d/mDNSResponder.sh" ] && /etc/rc.d/init.d/mDNSResponder.sh restart
	[ -x "/etc/rc.d/init.d/discovery.sh" ] && /etc/rc.d/init.d/discovery.sh restart
	#if up  will restart godev and transpeer
	#[ -x "/opt/opt.local" ] && /opt/opt.local stop > /dev/null 2> /dev/null
	#[ -x "/opt/opt.local" ] && /opt/opt.local start > /dev/null 2> /dev/null
	
	if [ "$PPPoEEnable_byte" -eq 1 ]; then
		echo "== $median:1 =="
		ifdown $median:1 # ifdown interface before ifup
		ifup $median:1
		pidof pppd > /tmp/pppd.pid
	else
		[ -x "/etc/rc.d/init.d/ddnsUpdater.sh" ] && /etc/rc.d/init.d/ddnsUpdater.sh reload
	fi

	#Enable EDCCA in CE.
	if [ $Region -eq 1 ] 
	then
		setEdcca
	fi

	if probeMTDongle; then
		#Pre site survey at back ground to speed up site survey result.
		$(iwpriv ra0 set SiteSurvey=1 ; sleep 4; iwpriv ra0 get_site_survey > /dev/null) &
	fi
}

status() {
	echo "==== Status of $daemon ===="
	echo "== ifconfig =="
	ifconfig | grep in
	echo "== route =="
	route
	echo "== resolv.conf =="
	cat $resolv
	echo "==== ok ===="
}

mustDown() {
	ifconfig | grep -q "^$1" && ifconfig $1 down
}

down() {
	echo "== down $1 =="
	ifdown $1
	usleep 500000
	mustDown $1
}

disable() {
	echo "== disable $1 =="
	ifconfig $1 0.0.0.0 up
}

stop() {
	echo "==== Stopping $daemon ===="
	# send disassociated with ap to watchdog
	send_cmd watchdog 639 > /dev/null 2> /dev/null
	# Set Wi-Fi LED
	if [ -f "/tmp/wifi-led" ]; then
		send_cmd watchdog 778 1 > /dev/null 2> /dev/null
	else
		touch /tmp/wifi-led
	fi
	if probeMTDongle; then
		/etc/rc.d/init.d/wifiAutoReconnect.sh stop &
	else		
		/etc/rc.d/init.d/wirelessDectd.sh stop &
	fi
	mustDown $median

	[ -x "/etc/rc.d/init.d/lld2d.sh" ] && /etc/rc.d/init.d/lld2d.sh stop &
	[ -x "/opt/opt.local" ] && /opt/opt.local stop &

	dhcpv6_pid=$(pidof dibbler-client) && kill $dhcpv6_pid && [ -x /sbin/dibbler-client ] && /sbin/dibbler-client stop &
	# avoid default.script restart upnp_av/orthrus twice
	[ -x "/etc/rc.d/init.d/upnp_av_ipv6.sh" ] && /etc/rc.d/init.d/upnp_av_ipv6.sh stop &
	[ -x "/etc/rc.d/init.d/upnp_av.sh" ] && /etc/rc.d/init.d/upnp_av.sh stop &
	[ -x "/etc/rc.d/init.d/discovery.sh" ] && /etc/rc.d/init.d/discovery.sh stop &
	[ -x "/etc/rc.d/init.d/mDNSResponder.sh" ] && /etc/rc.d/init.d/mDNSResponder.sh stop &
	
#	if probeWireless; then
#		# wlan0 is need by site survey
#		disable wlan0
#
#		# set wireless lan to Infrastructure mode
#		iwpriv wlan0  set NetworkType=Infra
#
#		# make wireless lan connect to an inexistent Access Point
#		iwconfig wlan0 essid "$(pibinfo MacAddress)"
#	fi

	# eth0 is need by ifplugd
	disable eth0

	# finally kill udhcpc, just in case
	killall udhcpc > /dev/null 2> /dev/null
	# finally kill pppd
	killall pppd > /dev/null 2> /dev/null
	# finally  stop zcip
	[ -x "/etc/rc.d/init.d/zcip.sh" ] && /etc/rc.d/init.d/zcip.sh stop &

	killall wifi-led
	killall wifi-led
	killall wifi-led

	rm -f /tmp/dhcpresult.log
	rm -f /tmp/pppd.pid

	echo "==== ok ===="
}

action=$1
linkage=$2
intface=$3
end=$4

[ "$end" = "" ] && [ "$action" != "" ] || showUsage

setWlanInterface

case $action in
	start)
		start
	;;
	stop)
		# stop may call return, instead of exit
		stop || exit 1
	;;
	restart_lite)
		restart_lite $linkage $intface
	;;
	restart)
		# in some case, web server need to be restart to proform normally.
		# send linkup or linkdown to watchdog
		[ "$linkage" = 'up' ] && 
			{ send_cmd watchdog 636 > /dev/null 2> /dev/null; } || 
			{ send_cmd watchdog 637 > /dev/null 2> /dev/null; }

		/etc/rc.d/init.d/lighttpd.sh stop &
		/etc/rc.d/init.d/rtspd.sh stop &
		/etc/rc.d/init.d/rtpd.sh stop &
		[ -x "/etc/rc.d/init.d/transpeer.sh" ] && /etc/rc.d/init.d/transpeer.sh stop & 
		[ -x "/etc/rc.d/init.d/godev.sh" ] && /etc/rc.d/init.d/godev.sh stop & 

		stop

		echo

		start

		/etc/rc.d/init.d/rtpd.sh start
		/etc/rc.d/init.d/rtspd.sh start
		/etc/rc.d/init.d/lighttpd.sh start
		[ "$LinkLocalIP_byte" -eq 0 ] && [ -x "/etc/rc.d/init.d/discovery.sh" ] && /etc/rc.d/init.d/discovery.sh restart &
		[ -x "/etc/rc.d/init.d/transpeer.sh" ] && /etc/rc.d/init.d/transpeer.sh start 
		[ -x "/etc/rc.d/init.d/godev.sh" ] && /etc/rc.d/init.d/godev.sh start 
	;;
	status)
		status
	;;
	*)
		showUsage
	;;
esac

exit 0
