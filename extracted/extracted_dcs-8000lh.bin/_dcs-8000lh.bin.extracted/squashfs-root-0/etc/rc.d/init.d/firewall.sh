#!/bin/sh

v4table=iptables
v6table=ip6tables
PATH=$PATH:/sbin
RejectExternalIP=`tdb get RTPServer RejectExtIP_byte`
IPv6_Enabled=$(tdb get IPv6 Enable_byte)
die() {
	echo $@
	exit 1
}

showUsage() {
	die "$0 {start|stop|restart|status|reload} [prefix]"
}

cleanup() {
	$binary_v4 -F
	$binary_v4 -X
	$binary_v4 -Z
	$binary_v4 -P INPUT ACCEPT
	if [ $IPv6_Enabled -eq "1" ]; then 
		$binary_v6 -F
		$binary_v6 -X
		$binary_v6 -Z
		$binary_v6 -P INPUT ACCEPT
	fi
}

setDefaultRule() {
	$binary_v4 -P INPUT $defaultAction	
	if [ $IPv6_Enabled -eq "1" ]; then 
		$binary_v6 -P INPUT $defaultAction	
	fi
}

loadDBSetting() {
	tdb get Firewall << EOM
Enable_byte
Action_byte
ActionSet_ls
Action6Set_ls
AdminAllowOn_byte
AdminAllowAddr_ss
EOM
}

start() {
	echo -n "Startting firewall..."
	cleanup
	[ -x $binary_v4 ] || die "$binary_v4 is not a valid application"
	if [ $IPv6_Enabled -eq "1" ]; then 
		[ -x $binary_v6 ] || die "$binary_v6 is not a valid application"
	fi
	[ -d $prefix ] && export PREFIX=$prefix
	export LD_LIBRARY_PATH=$prefix/lib
	eval $(loadDBSetting)
	if [ "$Enable_byte" = "1" ]; then
		if [ "$Action_byte" = "0" ]; then
			action="DROP"
			defaultAction="ACCEPT"
		else
			action="ACCEPT"
			defaultAction="DROP"
			$binary_v4 -A INPUT -i lo -j ACCEPT
			if [ $IPv6_Enabled -eq "1" ]; then 
				$binary_v6 -A INPUT -i lo -j ACCEPT
			fi
		fi
		setDefaultRule
		if [ "$ActionSet_ls" != "" ]; then
			for ip in $ActionSet_ls
			do
				if [ "$(echo $ip | grep -)" != "" ]; then
					$binary_v4 -I INPUT -m iprange --src-range $ip -j $action
				else
					$binary_v4 -A INPUT -s $ip -j $action
				fi
			done
		fi
		if [ $IPv6_Enabled -eq "1" ]; then 
			if [ "$Action6Set_ls" != "" ]; then
				for ip in $Action6Set_ls
				do
					if [ "$(echo $ip | grep -)" != "" ]; then
						$binary_v6 -I INPUT -m iprange --src-range $ip -j $action
					else
						$binary_v6 -A INPUT -s $ip -j $action
					fi
				done
			fi
			if [ "$AdminAllowOn_byte" = "1" ] && [ "$AdminAllowAddr_ss" != "" ]; then
				if [ "$(echo $AdminAllowAddr_ss | grep :)" != "" ]; then
					$binary_v6 -I INPUT -s $AdminAllowAddr_ss -j ACCEPT
				else
					$binary_v4 -I INPUT -s $AdminAllowAddr_ss -j ACCEPT
				fi
			fi
		fi
	fi
	if [ "$RejectExternalIP" = "1" ]; then
		$binary_v4 -A INPUT -i lo -j ACCEPT
		$binary_v4 -A INPUT -p tcp --dport 554 -j DROP
		if [ $IPv6_Enabled -eq "1" ]; then 
			$binary_v6 -A INPUT -i lo -j ACCEPT
			$binary_v6 -A INPUT -p tcp --dport 554 -j DROP
		fi
	fi
	echo "ok."
}

status() {
	echo "IPv4 table ..."
	$binary_v4 -L -n
	if [ $IPv6_Enabled -eq "1" ]; then 
		echo "IPv6 table ..."
		$binary_v6 -L -n
	fi
}

stop() {
	cleanup
}

action=$1
prefix=$2
end=$3

[ "$end" = "" ] && [ "$action" != "" ] || showUsage
[ "$prefix" = "" ] || [ -d "$prefix" ] || die "$prefix is not a valid directory"

binary_v4=$prefix/sbin/$v4table
binary_v6=$prefix/sbin/$v6table
export XTABLES_LIBDIR=$prefix/lib/xtables/

case $action in
	reload)
		stop
		start
	;;
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
	status)
		status
	;;
	*)
		showUsage
	;;
esac

exit 0
