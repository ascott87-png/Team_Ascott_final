#!/bin/sh

mknod /dev/console c 5 1
mknod /dev/dbg_iomem c 120 0
mknod /dev/usb_phy_mdio c 121 0
mknod /dev/efuse c 122 0
mknod /dev/hconf c 123 0
mknod /dev/ram0 b 1 0
mknod /dev/android_uvc c 243 0

insmod /lib/modules/rlx_dma.ko
insmod /lib/modules/rlx_i2s.ko
insmod /lib/modules/rlx_codec.ko
insmod /lib/modules/rlx_snd.ko

insmod /lib/modules/rtsx-icr.ko

insmod /lib/modules/rts_cam.ko
insmod /lib/modules/rts_camera_soc.ko
insmod /lib/modules/rts_camera_hx280enc.ko
insmod /lib/modules/rts_camera_jpgenc.ko
insmod /lib/modules/rtstream.ko

#Load /lib/firmware/isp.fw 
echo 1 > /sys/devices/platform/rts_soc_camera/loadfw
