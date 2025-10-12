#!/bin/sh

touch /tmp/uploading
dir="/tmp/update"
out="$dir/out.bin"

# get current setting from tdb
# format looks like VariableName_type
onGetSetting() {
	eval $(dumpSystemKeys | tdb get System) || return 1
	eval $(pibinfo all) || return 1
	version=$Version_ss
	vendor=$Vendor_ms
	oem=$OEM_ms
	model=$Model_ss
	product=$ProdNumber_ss
	hwBoard=$HWBoard
	hwVersion=$HWVersion
	desc=""
	result=""
	hasPT=__mcu__
	[ "$hasPT" = "yes" ] && mcuVersion=$(pt_firmware -v)
	StaticTrustLevel=`tdb get SecureFW StaticTL_byte`
}

getWeight() {
	major=$(echo "$1" | cut -d'.' -f1) || major=0
	minor=$(echo "$1" | cut -d'.' -f2) || minor=0
	sub=$(echo "$1" | cut -d'.' -f3 | cut -d'-' -f1) || sub=0
	echo $(( $major*100 + $minor*10 + $sub ))
}

verifyFirmware() {
	result=signFail
	#result=examFail
	#tar tf "$UPLOADBIN" > /dev/null 2> /dev/null || return 1
	fw_sign_verify.sh "$UPLOADBIN" /etc/db/verify.key > /dev/null 2> /dev/null || return 1
	return 0
}

decryptFirmware() {
	result=decryptFail
	#result=examFail
	pibinfo PriKey > $dir/decrypt.key 2> /dev/null
	fw_decrypt.sh $dir/decrypt.key $out > /dev/null 2> /dev/null || return 1
	return 0
}

checkSetting() {
	touch /tmp/verifying
	rm -f /tmp/uploading

	result=uploadFail
	[ "$out" != "" ] || return 1
	[ -f "$out" ] || return 1
	chmod u+x "$out"
	result=examFail
	"$out" exam $UPLOADBIN || return 1
	result=infoFail
	eval $("$out" info) || return 1
	version=$VERSION
	vendor=$VENDOR
	oem=$OEM
	model=$MODEL
	product=$PRODUCT
	desc=$DESCRIPT
	hwBoard=$HWBOARD
	hwVersion=$HWVERSION
	result=invalidImage

	# at least SIGN, APP, vendor must be the same
	[ "$MECH_SIGN" = "QPAT" ] || return 1
	[ "$MECH_APP" = "doUpdate" ] || return 1
	#[ "$VENDOR" = "$Vendor_ms" ] || return 1

	# if scenario is force, then done
	[ "$scenario" = "forceUpdate" ] && return 0

	# Note here:
	# HWBOARD, HWVERSION are from update image
	# HWBoard, HWVersion are from pibinfo
	# and they are different
	HWMAJOR=$(echo "$HWVERSION" | cut -d'.' -f1)
	HWMajor=$(echo "$HWVersion" | cut -d'.' -f1)

	# if scenario is factory, check only hardware
	if [ "$scenario" = "factoryUpdate" ]; then
		[ "$HWBOARD" = "$HWBoard" ] || return 1
		[ "$HWMAJOR" = "$HWMajor" ] || return 1
		return 0
	fi

	# all other scenarios, check all
	[ "$HWBOARD" = "$HWBoard" ] || return 1
	[ "$HWMAJOR" = "$HWMajor" ] || return 1
	[ "$OEM" = "$OEM_ms" ] || return 1
	#[ "$MODEL" = "$Model_ss" ] || return 1
	models=$(cat $dir/certificate.info | grep Models | cut -d":" -f 2)
	$(echo "$models" | grep "$Model_ss" >/dev/null 2>/dev/null) || return 1
	now=$(getWeight "$Version_ss" 2> /dev/null) || return 1
	then=$(getWeight "$VERSION" 2> /dev/null) || return 1
	[ "$then" -ge "$now" ] || return 1

	if [ -n "$(echo \"$PACKAGE\" | grep \"webfs\")" ]; then
		result=incorrectWebfsVersion
		[ "$then" -eq "$now" ] || return 1
	fi
	return 0
}

saveSetting() {
	result=saveFail
	"$out" update $UPLOADBIN > /dev/null 2> /dev/null || return 1
	return 0
}

do_clean() {
	[ -d "$dir" ] && rm -rf $dir	
	[ -f "$UPLOADBIN" ] && rm -f $UPLOADBIN
	/etc/rc.d/init.d/services.sh start > /dev/null 2> /dev/null
}

# make sure, ...
# 1. $result is set
# 2. variables in dumpXml are all set
onUpdateSetting() {
	TrustLevel=`tdb get SecureFW _TrustLevel_byte`
	if [ "$TrustLevel" = "3" -a "$UpdateStage" = "2" ]; then
		if [ "$UpdateContinue" = "0" ]; then
			result=updateCanceled
			do_clean
			return 0
		fi

		scenario="forceUpdate"
	else
		UPLOADBIN="$UPLOAD"
		if ! verifyFirmware; then
			if [ "$TrustLevel" = "1" ]; then
				do_clean
				return 1
			fi
		fi
		if ! decryptFirmware; then
			do_clean
			return 1
		fi
	fi

	if [ "$TrustLevel" = "3" -a "$UpdateStage" != "2" ]; then
		getCertInfo
		result=updateStage1
		return 0
	fi
	
	# 1. check parameters
	if ! checkSetting; then
		do_clean
		return 1
	fi

	# 1.9, make language files into cache, before mess up flash.
	cat tools_default.xsl frame.lang tools-left.lang tools_default.lang > /dev/null 2> /dev/null
	# 2. save to NOR flash
	send_cmd watchdog 643 >/dev/null 2>/dev/null
	if ! saveSetting; then
		do_clean
		return 1
	fi
	#if [ "$scenario" = "forceUpdate" ]; then
	#	/scripts/pibset HWBoard $HWBOARD
	#	hwBoard=$HWBOARD
	#	/bin/factoryReset
	#fi
	# 3. make it sync
	result=updateOK
	sleep 3
}

onDumpXml() {
	xmlBegin tools_firmware.xsl tools-left.lang tools_firmware.lang
	resultTag $result
	configBegin
		beginTag updateImage
			tag version "$version"
			tag vendor "$vendor"
			tag hwBoard "$hwBoard"
			tag hwVersion "$hwVersion"
			tag oem "$oem"
			tag model "$model"
			tag product "$product"
			tag description "$desc"
			tag StaticTrustLevel "$StaticTrustLevel"
			#tag UPLOADBIN "$UPLOADBIN"
			if [ "$result" == updateStage1 ]; then
				tag Publisher  "$Publisher"
				tag SupportedModels "$SupportedModels"
				tag FirmwareVersion "$FirmwareVersion"
			fi
		endTag updateImage
		[ "$hasPT" = "yes" ] && tag mcuVersion "$mcuVersion"
	configEnd
	xmlEnd
	[ "$result" == "updateOK" ] && {(sleep 5 && reboot) > /dev/null 2> /dev/null &}
}

scenario=$(basename $0 | cut -d'.' -f1)
export SCENARIO="$scenario"
UPLOADBIN=""

. ../../xmlFunctions.sh
. ../../cgiMain.sh

