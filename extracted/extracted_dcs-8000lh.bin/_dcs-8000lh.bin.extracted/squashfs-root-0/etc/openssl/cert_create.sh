#!/bin/sh
#Get subject value from db and remove white space

tdbname='Certificate2'
vCountry='Country_ss'
vProvince='Province_ls'
vLocality='Locality_ls'
vOrganization='Org_ls'
vOrganization_u='Org_u_ls'
vCommonName='CommonName_ls'
vValidity='Validity_num'
vKeyLen='KeyLength_num'

cert_method=$(tdb get Certificate2 Method_byte)
if [ "$cert_method" -eq "0" ] ; then
	tdbname='HTTPS'
	vCountry='_Country_ss'
	vProvince='_Province_ls'
	vLocality='_Locality_ls'
	vOrganization='_Org_ls'
	vOrganization_u='_Org_u_ls'
	vCommonName='_CommonName_ls'
	vValidity='_Validity_num'
	vKeyLen='_KeyLength_num'
fi

crtData=''
if [ "$cert_method" -eq "2" ] ; then
	tdbname='CertificateReq'
	crtData=$(tdb get 'HTTPSPem' 'crtData_ls')
fi

#echo $tdbname
country_name=$(tdb get $tdbname $vCountry)
state_province=$(tdb get $tdbname $vProvince | sed -re "s/\ /\\\ /g")
locality_name=$(tdb get $tdbname $vLocality | sed -re "s/\ /\\\ /g")
organization_name=$(tdb get $tdbname $vOrganization | sed -re "s/\ /\\\ /g")
organization_unit_name=$(tdb get $tdbname $vOrganization_u | sed -re "s/\ /\\\ /g")
common_name=$(tdb get $tdbname $vCommonName | sed -re "s/\ /\\\ /g")
validity=$(tdb get $tdbname $vValidity)
keylen=$(tdb get $tdbname $vKeyLen)

#create certificate
if [ "$cert_method" -eq "2" ] ; then
	if [ -z "$crtData" ] ; then
		return
	fi
	keyData=$(tdb get 'HTTPSPem' 'keyData_ls')
	echo "$keyData" > /tmp/server.pem
	echo "$crtData" >> /tmp/server.pem
	tdb set HTTPSPem pemData_ls="$keyData"
	tdb set HTTPSPem pemData2_ls="$crtData"
else
	export OPENSSL_CONF=/etc/openssl/openssl.cnf
	openssl req -sha256 -new -newkey rsa:$keylen -x509 -keyout /tmp/server.key -out /tmp/server.crt -days $validity -nodes -config $OPENSSL_CONF -subj /C=$country_name/ST="$state_province"/L="$locality_name"/O="$organization_name"/OU="$organization_unit_name"/CN="$common_name"
	cat /tmp/server.key /tmp/server.crt > /tmp/server.pem
	tdb set HTTPSPem pemData_ls="$(cat /tmp/server.key)"
	tdb set HTTPSPem pemData2_ls="$(cat /tmp/server.crt)"
	rm /tmp/server.key /tmp/server.crt
fi
#Save it into db
#tdb set CERTIFICATE Certificate_ls="$(cat /tmp/server.pem)"
#certificate set /tmp/server.pem HTTPSPem pemData
tdb set Certificate2 'PemExist_byte=1'
