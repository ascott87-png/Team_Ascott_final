#!/bin/sh

EFUSEBUFFER_PATH=/tmp/RT5370_USB_1T1R_MAIN_V1_6.BIN

showUsage() {
	echo $0 will write the efusebuffer from PATH to PIB with uuencode.
	echo Usage :
	echo $0 [PATH]
	echo default : $0 $EFUSEBUFFER_PATH 
	exit 1
}

[ "$1" != "" ] && EFUSEBUFFER_PATH=$1

iwpriv ra0 set efuseBufferModeWriteBack=1 && echo Write back OK || echo Write back FAILED
cat $EFUSEBUFFER_PATH | uuencode $EFUSEBUFFER_PATH | pibinfo setEfuseBuffer && echo set PIB OK || echo set PIB FAILED

