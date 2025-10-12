#!/bin/sh

mode_byte=$(tdb get Ble Mode_byte)
if [ "$mode_byte" = "1" ]; then
	/etc/rc.d/init.d/bluetoothd.sh restart
fi

