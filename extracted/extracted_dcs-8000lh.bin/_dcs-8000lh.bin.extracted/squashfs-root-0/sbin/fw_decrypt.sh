#!/bin/sh
ret=0
p=/tmp/update
target=$(cat $p/certificate.info | grep "Target" | cut -d":" -f2)
#openssl rsautl -decrypt -in aes.key.rsa -inkey decrypt.key -out aes.key
openssl rsautl -decrypt -in $p/aes.key.rsa -inkey "$1" -out $p/aes.key || ret=1

password=`cat $p/aes.key`

#openssl aes-128-cbc -k "$password" -nosalt -d -in update.bin.aes -out /tmp/update.bin
openssl aes-128-cbc -k "$password" -nosalt -d -in $p/$target.aes -out "$2" || ret=1
chmod u+x $2
exit $ret
