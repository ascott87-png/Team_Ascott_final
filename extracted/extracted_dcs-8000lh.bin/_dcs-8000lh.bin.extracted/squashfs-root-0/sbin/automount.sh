#!/bin/sh


MOUNT_PATH="/mnt/usb"
VOLUME_PATH="/tmp/local"
#MUSIC_FOLDER="music"

MOUNT=/bin/mount
UMOUNT=/bin/umount
MKDIR=/bin/mkdir

domount() {
	M=`mount | grep $1`
	if [ "$M" = "" ]; then
		if [ ! -d "$MOUNT_PATH" ]; then
			$MKDIR -p "$MOUNT_PATH"
		fi
		$MOUNT -t vfat -o fmask=0000,dmask=0000,allow_utime=0022 /dev/$1 "$MOUNT_PATH" && echo -n "/dev/$1" > /tmp/sddev
		[ -f "/tmp/WirelessModel" ] && model=$( tdb get System ModelW_ss ) || model=$( tdb get System Model_ss )
		[ ! -d $MOUNT_PATH/$model ] && $MKDIR $MOUNT_PATH/$model
#		[ ! -d $MOUNT_PATH/$MUSIC_FOLDER ] && $MKDIR $MOUNT_PATH/$MUSIC_FOLDER
		[ $model != "" ] && ln -sf $MOUNT_PATH/$model $VOLUME_PATH
	else
		$UMOUNT -lf "$MOUNT_PATH" && rm /tmp/sddev 
		rm $VOLUME_PATH
	fi
}

test=$(echo $1 | grep -re "mmcblk[0-9]$")
if [ "$test" != "" ]; then
	if [ -b /dev/${test}p1 ]; then
		domount ${test}p1	
	elif [ -b /dev/${test}p2 ] || [ -b /dev/${test}p3 ] || [ -b /dev/${test}p4 ]; then
		echo "no part1, but have other part, do not mount" > /dev/console
	else
		domount $test
	fi
else
	exit 1
fi

exit $?



