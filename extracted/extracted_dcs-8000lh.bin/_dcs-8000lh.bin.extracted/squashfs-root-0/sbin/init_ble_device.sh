#!/bin/sh
export PATH=$PATH:/var/bluetooth/bin/
export LD_LIBRARY_PATH=/var/bluetooth/lib/
/sbin/gen_bt_config > /dev/null 2 > /dev/null
hciconfig hci0 up
