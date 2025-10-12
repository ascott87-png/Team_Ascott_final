#!/bin/sh

daemon=mDNSResponder
PATH=$PATH:/sbin

die() {
	echo $@
	exit 1
}

showUsage() {
	die "$0 {start|stop|restart|status} [prefix]"
}

setup() {
	HttpPort_num=$(tdb get HTTPServer Port_num)
	CameraName_ms=$(tdb get Host CameraName_ms)
	Model_ms=$(tdb get System Model_ms)
	MacAddress="$(pibinfo MacAddress | sed 's/://g')"
	Last4Mac=$(echo $MacAddress | cut -b 9-12)
	HWVersion="$(mdb get hw_version )"
	FWVersion="$(tdb get System OEMVersion_ss)"
	DcpPort=8080
	MDVersion=$(cat /mydlink/version | sed 's/VERSION=//g')
	MDId=$(mdb get mydlink_no)
	DcpVersion=$(cat /mydlink/dcp_version)
	RegSt=$(mdb get register_st)
	mmp=$(cat /mydlink/m2m)

echo -n "\
${Model_ms}-${Last4Mac}
_http._tcp.
$HttpPort_num

${Model_ms}-${Last4Mac}
_dcp._tcp.
$DcpPort
mac=$MacAddress
model=$Model_ms
hw_ver=$HWVersion
fw_ver=$FWVersion
md_ver=$MDVersion
md_id=$MDId
version=$DcpVersion
reg_st=$RegSt
mmp=$mmp
"
}

setupCustomHostName() {
	if [ ! -f $hostname ] ||  [ -z $(cat $hostname) ];then
		Model_ms=$(tdb get System Model_ms)
		MacAddress="$(pibinfo MacAddress | sed 's/://g')"
		echo "$Model_ms-$MacAddress" > $hostname
	else
		echo "file is exists"
	fi
}

start() {
	! pids=$(pidof $daemon) || die "$daemon($pids) is already running."

	echo -n "Startting $daemon... "
	[ -x "$binary" ] || die "$binary is not a valid application"
	enable=$(tdb get Bonjour Enable_byte)
	if [ $enable -eq 0 ]; then
		echo "disabled."
		return 0
	fi

	export LD_LIBRARY_PATH=$prefix/lib
	setup > $conf
	setupCustomHostName
	$binary -b -f $conf > /dev/null 2> /dev/null
	echo "ok."
}

status() {
	echo -n "$daemon"
	pids=$(pidof $daemon) && echo "($pids) is running." || echo " is stop."
}

stop() {
	pids=$(pidof $daemon) || { echo "$daemon is not running." && return 1; }
	echo -n "Stopping $daemon... "
	kill -SIGQUIT $(echo $pids | cut -d' ' -f1)
#	kill $(echo $pids | cut -d' ' -f1)
	sleep 1
	pids=$(pidof $daemon) && killall -9 $daemon && sleep 1 && pids=$(pidof $daemon) && die "ng." || echo "ok."
}

action=$1
prefix=$2
end=$3

[ "$end" = "" ] && [ "$action" != "" ] || showUsage
[ "$prefix" = "" ] || [ -d "$prefix" ] || die "$prefix is not a valid directory"

binary=$prefix/sbin/$daemon
conf=/tmp/$daemon.conf
hostname=/tmp/$daemon.hostname

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
		sleep 1
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
