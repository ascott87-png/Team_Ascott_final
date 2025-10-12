#!/bin/sh
echo -n "starting create_certificate..."
#bzip2 -d -c /bin/openssl.bz2 > /tmp/openssl
#bzip2 -d -c /lib/libcrypto.so.0.9.8.bz2 > /tmp/libcrypto.so.0.9.8
#chmod 0777 /tmp/openssl
#echo "bzip2... ok."

#HTTPSenable=$(tdb get HTTPS Enable_byte)
SSLhttpd=$(lighttpd -v | grep ssl)

if [ -z "$SSLhttpd" ] ; then
	return
	#echo 'set HTTPS Enable to 1'
	#tdb set HTTPS 'Enable_byte=1'
fi

pemExist=$(tdb get Certificate2 PemExist_byte)
if [ "$pemExist" = "0" ] ; then
	echo 'call cert_create.sh to create certificate'
	/etc/openssl/cert_create.sh
	return
fi
#Certificate=$(tdb get CERTIFICATE Certificate_ls)
#echo "$Certificate" > /tmp/server.pem
#cp /tmp/db/server.pem /tmp/server.pem
#touch /tmp/server.pem
#certificate get /tmp/server.pem HTTPSPem pemData

pemData=$(tdb get HTTPSPem pemData_ls)
pemData2=$(tdb get HTTPSPem pemData2_ls)

echo "$pemData" > /tmp/server.pem
echo "$pemData2" >> /tmp/server.pem

echo "get server.pem... ok."
