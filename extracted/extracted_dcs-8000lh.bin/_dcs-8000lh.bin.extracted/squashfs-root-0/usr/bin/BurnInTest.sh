#/bin/sh

action=$1
circleSecs=900

die() {
	echo $@
	exit 1
}

showUsage () {
	die "$0 {start}"
}

dumpBurnInKeys () {
	echo -n \
	BurnInWMins_num \
	BurnResult_ls
}

ledNenoLight ()
{
	count=$@
	while [ $count -gt 0 ]; do
		light wpsLed off
		light power on
		sleep 1
		light power off
		light active on
		sleep 1
		light active off
		light wpsLed on
		sleep 1
		let count=$count-3
	done
}

start () {
	eval $( dumpBurnInKeys | tdb get BurnIn )
	echo " ======== Idle $BurnInWMins_num mins, then starting burnin.======="

	let sleepSecs=$BurnInWMins_num*60
	sleep $sleepSecs

	orderWD ledStatus disable
	light power off
	light active off
	light wpsLed off
	light ir on

	circleTimes=1
	while true; do
		addlog Burnin $circleTimes times OK.
		curl -m $circleSecs -s http://127.0.0.1/video/mjpg.cgi > /dev/null &
		curl -m $circleSecs -s http://127.0.0.1/video/mjpg.cgi > /dev/null &
		curl -m $circleSecs -s http://127.0.0.1/video/mjpg.cgi > /dev/null &
		curl -m $circleSecs -s http://127.0.0.1/video/mjpg.cgi > /dev/null &
		curl -m $circleSecs -s http://127.0.0.1/video/mjpg.cgi > /dev/null &
		curl -m $circleSecs -s http://127.0.0.1/video/mjpg.cgi > /dev/null &
		curl -m $circleSecs -s http://127.0.0.1/video/mjpg.cgi > /dev/null &
		curl -m $circleSecs -s http://127.0.0.1/video/mjpg.cgi > /dev/null &
		curl -m $circleSecs -s http://127.0.0.1/video/mjpg.cgi > /dev/null &
		curl -m $circleSecs -s http://127.0.0.1/video/mjpg.cgi > /dev/null &

		ledNenoLight $circleSecs
		let circleTimes=$circleTimes+1
		sleep 10
	done
}

case $action in
	start)
		start
		;;
	*)
		showUsage
		;;
esac

while true; do

done

