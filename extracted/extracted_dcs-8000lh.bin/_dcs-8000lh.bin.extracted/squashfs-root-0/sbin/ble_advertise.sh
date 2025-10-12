#!/bin/sh 
#export PATH=$PATH:/var/bluetooth/bin/
export LD_LIBRARY_PATH=/var/bluetooth/lib/
#hciconfig hci0 up
#hciconfig hci0 noleadv
#hciconfig hci0 noscan
#hciconfig hci0 pscan
ble_advertise hci0
