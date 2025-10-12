#!/bin/sh

mac_addr=$1
mac_b1=$(echo $mac_addr | cut -d':' -f1)
mac_b2=$(echo $mac_addr | cut -d':' -f2)
mac_b3=$(echo $mac_addr | cut -d':' -f3)
mac_b4=$(echo $mac_addr | cut -d':' -f4)
mac_b5=$(echo $mac_addr | cut -d':' -f5)
mac_b6=$(echo $mac_addr | cut -d':' -f6)

#rtwpriv wlan0 efuse_get realmap
rtwpriv wlan0 efuse_get btfmap

#echo rtwpriv wlan0 efuse_set wmap,16,$mac_b1$mac_b2$mac_b3$mac_b4$mac_b5$mac_b6
#echo rtwpriv wlan0 efuse_set mac,$mac_b1$mac_b2$mac_b3$mac_b4$mac_b5$mac_b6
echo rtwpriv wlan0 efuse_set btwmap,3C,$mac_b6$mac_b5$mac_b4$mac_b3$mac_b2$mac_b1

echo MacAddress=$mac_addr | pibinfo set

#rtwpriv wlan0 efuse_set wmap,16,$mac_b1$mac_b2$mac_b3$mac_b4$mac_b5$mac_b6
#rtwpriv wlan0 efuse_set mac,$mac_b1$mac_b2$mac_b3$mac_b4$mac_b5$mac_b6
rtwpriv wlan0 efuse_set btwmap,3C,$mac_b6$mac_b5$mac_b4$mac_b3$mac_b2$mac_b1

#rtwpriv wlan0 efuse_get realmap
rtwpriv wlan0 efuse_get btfmap

bt_mac_b6=`rtwpriv wlan0 efuse_get btfmap | grep 0x030 | cut -d ' ' -f 13`
bt_mac_b5=`rtwpriv wlan0 efuse_get btfmap | grep 0x030 | cut -d ' ' -f 14`
bt_mac_b4=`rtwpriv wlan0 efuse_get btfmap | grep 0x030 | cut -d ' ' -f 15`
bt_mac_b3=`rtwpriv wlan0 efuse_get btfmap | grep 0x030 | cut -d ' ' -f 16`
bt_mac_b2=`rtwpriv wlan0 efuse_get btfmap | grep 0x040 | cut -d ' ' -f 1 | cut -c 7-8`
bt_mac_b1=`rtwpriv wlan0 efuse_get btfmap | grep 0x040 | cut -d ' ' -f 2`

#wlan_mac_b1=`rtwpriv wlan0 efuse_get realmap | grep 0x10 | head -n 1 | cut -d ' ' -f 7`
#wlan_mac_b2=`rtwpriv wlan0 efuse_get realmap | grep 0x10 | head -n 1 | cut -d ' ' -f 8`
#wlan_mac_b3=`rtwpriv wlan0 efuse_get realmap | grep 0x10 | head -n 1 | cut -d ' ' -f 9 | cut -c 2-3`
#wlan_mac_b4=`rtwpriv wlan0 efuse_get realmap | grep 0x10 | head -n 1 | cut -d ' ' -f 10`
#wlan_mac_b5=`rtwpriv wlan0 efuse_get realmap | grep 0x10 | head -n 1 | cut -d ' ' -f 11`
#wlan_mac_b6=`rtwpriv wlan0 efuse_get realmap | grep 0x10 | head -n 1 | cut -d ' ' -f 12`

printf "pibinfo MacAddress:\t%s\n" `pibinfo MacAddress`
printf "BT MAC address:\t\t%s:%s:%s:%s:%s:%s\n" $bt_mac_b1 $bt_mac_b2 $bt_mac_b3 $bt_mac_b4 $bt_mac_b5 $bt_mac_b6
#printf "Wi-Fi MAC address:\t%s:%s:%s:%s:%s:%s\n" $wlan_mac_b1 $wlan_mac_b2 $wlan_mac_b3 $wlan_mac_b4 $wlan_mac_b5 $wlan_mac_b6


