#!/bin/sh
#Get subject value from db and remove white space
tdbname='CertificateReq'
vCountry='Country_ss'
vProvince='Province_ls'
vLocality='Locality_ls'
vOrganization='Org_ls'
vOrganization_u='Org_u_ls'
vCommonName='CommonName_ls'
vValidity='Validity_num'
vKeyLen='KeyLength_num'

country_name=$(tdb get $tdbname $vCountry)
state_province=$(tdb get $tdbname $vProvince | sed -re "s/\ /\\\ /g")
locality_name=$(tdb get $tdbname $vLocality | sed -re "s/\ /\\\ /g")
organization_name=$(tdb get $tdbname $vOrganization | sed -re "s/\ /\\\ /g")
organization_unit_name=$(tdb get $tdbname $vOrganization_u | sed -re "s/\ /\\\ /g")
common_name=$(tdb get $tdbname $vCommonName | sed -re "s/\ /\\\ /g")
validity=$(tdb get $tdbname $vValidity)
keylen=$(tdb get $tdbname $vKeyLen)

#country_name='TW'
#state_province='Asia'
#locality_name='Asia'
#organization_name='D-Link Corporation'
#organization_unit_name='D-Link Corporation'
#common_name='www.dlink.com'
#validity='3650'


#create private key and certificate request file
export OPENSSL_CONF=/etc/openssl/openssl.cnf
#openssl req -new -x509 -keyout /tmp/server.pem -out /tmp/server.pem -days $validity -nodes -config /etc/openssl/openssl.cnf -subj /C=$country_name/ST="$state_province"/L="$locality_name"/O="$organization_name"/OU="$organization_unit_name"/CN="$common_name"
openssl req -config $OPENSSL_CONF -new -newkey rsa:$keylen -nodes -keyout /tmp/server.key -out /tmp/server.csr -subj /C=$country_name/ST="$state_province"/L="$locality_name"/O="$organization_name"/OU="$organization_unit_name"/CN="$common_name"
#Save it into db
#tdb set CERTIFICATE Certificate_ls="$(cat /tmp/server.pem)"
certificate set /tmp/server.key HTTPSPem keyData
certificate set /tmp/server.csr HTTPSPem csrData
#tdb set Certificate 'PemExist_byte=1'
