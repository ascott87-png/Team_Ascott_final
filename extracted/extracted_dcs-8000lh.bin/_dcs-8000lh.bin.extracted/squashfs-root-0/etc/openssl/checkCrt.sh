#!/bin/sh

export OPENSSL_CONF=/etc/openssl/openssl.cnf

keyMd5=`openssl rsa -noout -modulus -in "$1" | openssl md5`
crtMd5=`openssl x509 -noout -modulus -in "$2" | openssl md5`

[ "$keyMd5" == "$crtMd5" ] && exit 0

exit 1
