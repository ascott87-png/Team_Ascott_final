#!/bin/sh

p=/tmp/update
mkdir $p
tar -xf "$1" certificate.info -C $p
tar -xf "$1" aes.key.rsa -C $p
tar -xf "$1" sign.sha1.rsa -C $p
target=$(cat $p/certificate.info | grep "Target" | cut -d":" -f2)
tar -xf "$1" $target.aes -C $p
file=$(echo $target | cut -d'.' -f 0)
tar -xOf "$1" $file.aes | openssl dgst -sha1 | cut -d' ' -f2 > $p/$file.sha1
sum1=`cat $p/$target.aes $p/aes.key.rsa $p/certificate.info $p/$file.sha1 | openssl dgst -sha1 | cut -d' ' -f2`

[ ! -f "$p/sign.sha1.rsa" ] && echo "no sign" && exit 2

#openssl rsautl -decrypt -in sign.sha1.rsa -inkey verify.key -pubin -out sign.sha1
#openssl rsautl -verify -inkey verify.key -pubin -in sign.sha1.rsa > sign.sha1
openssl rsautl -verify -inkey "$2" -pubin -in $p/sign.sha1.rsa > $p/sign.sha1

sum2=`cat $p/sign.sha1`

echo $sum1
echo $sum2

if [ "$sum1" == "$sum2" ] ; then
	echo "verify ok"
	exit 0
fi

echo "verify failed"
exit 1

