#!/bin/sh

touch /tmp/uploading

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
	LevelOfTrust=`tdb get SecureFW TrustLevel_byte`
}

# make sure, ...
# 1. $result is set
# 2. variables in dumpXml are all set
onUpdateSetting() {
	result=InvalidParameter

	if [ "$LevelOfTrust" = "1" -o "$LevelOfTrust" = "2" -o "$LevelOfTrust" = "3" ]; then
		tdb set SecureFW TrustLevel_byte="$LevelOfTrust"
		result=saveLevelOfTrustOK
	fi
}

onDumpXml() {
	xmlBegin tools_firmware.xsl tools-left.lang tools_firmware.lang
	resultTag $result
	configBegin
		tag StaticTrustLevel "$StaticTrustLevel"
		tag LevelOfTrust "$LevelOfTrust"
	configEnd
	xmlEnd
}

. ../../xmlFunctions.sh
. ../../cgiMain.sh

