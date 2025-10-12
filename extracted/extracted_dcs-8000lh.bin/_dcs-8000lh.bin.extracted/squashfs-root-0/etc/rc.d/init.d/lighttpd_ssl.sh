#!/bin/sh

daemon=lighttpd_ssl
PATH=$PATH:/sbin

Server_Enabled=$(tdb get HTTPServer Enable_byte)
if [ $Server_Enabled -eq "0" ]; then
	exit  0
fi

if [ $(tdb get System OEM_ss) == "Alphanetworks" ] || [ $(tdb get System OEM_ss) == "Trendnet" ]; then 
		method=digest		
else
		method=basic
fi

IPv6_Enabled=$(tdb get IPv6 Enable_byte)

die() {
	echo $@
	exit 1
}

showUsage() {
	die "$0 {start|stop|restart|status} [prefix]"
}

dumpAccountKey() {
	echo -n "\
AdminUser_ss 
AdminPasswd_ss
LiveAuth_byte
SnapAuth_byte
User1_ss
Password1_ss
User2_ss
Password2_ss
User3_ss
Password3_ss
User4_ss
Password4_ss
User5_ss
Password5_ss
User6_ss
Password6_ss
User7_ss
Password7_ss
User8_ss
Password8_ss
User9_ss
Password9_ss
User10_ss
Password10_ss
User11_ss
Password11_ss
User12_ss
Password12_ss
User13_ss
Password13_ss
User14_ss
Password14_ss
User15_ss
Password15_ss
User16_ss
Password16_ss
User17_ss
Password17_ss
User18_ss
Password18_ss
User19_ss
Password19_ss
User20_ss
Password20_ss
Operator1_ss
OperatorPwd1_ss
Operator2_ss
OperatorPwd2_ss
Operator3_ss
OperatorPwd3_ss
Operator4_ss
OperatorPwd4_ss
Operator5_ss
OperatorPwd5_ss
"
}

readAccount() {
	eval $(dumpAccountKey | tdb get HTTPAccount)
}

md5hex() {
	echo -n "$1" | md5sum | cut -b -32
}

setupAdmin() {
	cat > /tmp/lighttpd-htdigest.user << EOM
$1:$mac_realm:$(md5hex "$1:$mac_realm:$2")
$1:nipca:$(md5hex "$1:nipca:$2")
$1:onvif:$(md5hex "$1:onvif:$2")
EOM
}

setupUser() {
	cat >> /tmp/lighttpd-htdigest.user << EOM
$1:$mac_realm:$(md5hex "$1:$mac_realm:$2")
$1:nipca:$(md5hex "$1:nipca:$2")
$1:onvif:$(md5hex "$1:onvif:$2")
EOM
}

setupAuth() {
lighttpd_lang="eng|cht|chn|de|es|it|fr|pt"
# valid-user depend on auth settings
if [ "$LiveAuth_byte" -eq 1 ]; then
# snap auth
if [ "$SnapAuth_byte" -eq 1 ]; then
cat << EOM
\$HTTP["url"] =~ "^/image/" {
	auth.require = ( "" =>
		(
			"method" => "$method",
			"realm" => "$mac_realm",
			"require" => "valid-user"
		)
	)
}
\$HTTP["url"] =~ "^/image2/" {
	auth.require = ( "" =>
		(
			"method" => "digest",
			"realm" => "$mac_realm",
			"require" => "valid-user"
		)
	)
}
EOM
fi
cat << EOM
\$HTTP["url"] =~ "^/(video|audio|m|dev|cgi|directview|volumes|$lighttpd_lang)/" {
	auth.require = ( "" =>
		(
			"method" => "$method",
			"realm" => "$mac_realm",
			"require" => "valid-user"
		)
	)	
}	
\$HTTP["url"] =~ "^/(av2|event2|play2|dev2)/" {
	auth.require = ( "" =>
		(
			"method" => "digest",
			"realm" => "$mac_realm",
			"require" => "valid-user"
		)
	)
}
\$HTTP["url"] =~ "^/wss" {
	auth.require = ( "" =>
		(
			"method" => "$method",
			"realm" => "$mac_realm",
			"require" => "valid-user"
		)
	)
}

\$HTTP["url"] =~ "^/(users|ptz)/" {
	auth.require = ( "" =>
		(
			"method" => "$method",
			"realm" => "nipca",
			"require" => "valid-user"
		)
	)
}
\$HTTP["url"] =~ "^/vaview.htm" {               
        auth.require = ( "" =>                   
        (                                                                       
                "method" => "$method",       
                "realm" => "$mac_realm",     
                "require" => "valid-user"    
        )                                    
        )                                    
}
\$HTTP["url"] =~ "^/vjview.htm" {               
        auth.require = ( "" =>                   
        (                                                                       
                "method" => "$method",       
                "realm" => "$mac_realm",     
                "require" => "valid-user"    
        )                                    
        )                                    
}
EOM
fi
# admin always need auth
cat << EOM
\$HTTP["url"] =~ "^/onvif/" {
	auth.require = ( "" =>
        (
            "method" => "digest",
            "realm" => "onvif",
            "require" => "valid-user" 
        )
    )
}
\$HTTP["url"] =~ "^/config/" {
	auth.require = ( "" =>
        (
            "method" => "$method",
            "realm" => "nipca",
            "require" => "user=$AdminUser_ss"
        )
	)
}
\$HTTP["url"] =~ "^/(.*/admin/|auth/|.*/mainFrame.cgi)" {
	auth.require = ( "" =>
		(
			"method"  => "$method",
			"realm"   => "$mac_realm",
			"require" => "user=$AdminUser_ss" 
		)
	)
}
EOM
}

start() {
	! pids=$(pidof $daemon) || die "$daemon($pids) is already running."
	echo -n "Startting $daemon... "
	[ -x $binary ] || die "$binary is not a valid application"
	export LD_LIBRARY_PATH=$prefix/lib
	export PREFIX=$prefix
	readAccount
	HttpsPort_num=$(tdb get HTTPServer HTTPSPort_num)
	Port_num=$(tdb get HTTPServer Port_num)

	model=$( [ $(pibinfo Wireless) -eq 1 ] && tdb get System ModelW_ss || tdb get System Model_ss )
	mac_realm="${model}_$(pibinfo MacAddress | cut -b 16-17)"
	
	# create dynamic conf file.
	[ "$HttpsPort_num" != "" ] || HttpsPort_num=443
	[ "$Port_num" != "" ] || Port_num=80
	echo > /tmp/lighttpd-inc_ssl.conf
	echo "auth.require.accept.provision = $(admin-accept)"  >> /tmp/lighttpd-inc_ssl.conf
	echo "auth.require.accept.url = \"/auth/\""  >> /tmp/lighttpd-inc_ssl.conf
	echo "auth.require.accept.pattern = \"\/auth\/.*|\/config\/user_mod.cgi\""  >> /tmp/lighttpd-inc_ssl.conf 
	[ -f "/sbin/ecr_client" ] && \
	echo "server.max-keep-alive-requests = 128" >> /tmp/lighttpd-inc_ssl.conf && \
	echo "server.max-keep-alive-idle = 30" >> /tmp/lighttpd-inc_ssl.conf && \
	echo "server.max-read-idle = 60" >> /tmp/lighttpd-inc_ssl.conf && \
	echo "server.max-write-idle = 360" >> /tmp/lighttpd-inc_ssl.conf

	# csrf enable or not
	echo "auth.require.accept.csrfflag = $(tdb get HTTPServer CSRFEnable_byte)" >> /tmp/lighttpd-inc_ssl.conf

	SSLEnable_b=$(tdb get HTTPS Enable_byte)
	if [ "$SSLEnable_b" = "0" ] ; then
		#echo 'server.document-root = env.PREFIX + "/tmp/www/"' >> /tmp/lighttpd-inc.conf
	   if [ "$HttpsPort_num" = "443" ]; then
		echo -n '$HTTP["scheme"] == "https" {
    				$HTTP["host"] =~ ".*" {
        				url.redirect = (".*" => "http://%0' >> /tmp/lighttpd-inc_ssl.conf
        	echo -n ":$Port_num" >> /tmp/lighttpd-inc_ssl.conf
        	echo '$0")
    				}
			}' >> /tmp/lighttpd-inc_ssl.conf
	    else
		echo -n '$HTTP["scheme"] == "https" {
    				$HTTP["host"] =~ "(.*)(\:[0-9]*)$" {
        				url.redirect = (".*" => "http://%1' >> /tmp/lighttpd-inc_ssl.conf
        	echo -n ":$Port_num" >> /tmp/lighttpd-inc_ssl.conf
        	echo '$0")
    				}
			}' >> /tmp/lighttpd-inc_ssl.conf
	    fi
	fi

	#enable ipv6
	echo "server.port = $HttpsPort_num" >> /tmp/lighttpd-inc_ssl.conf
	if [ $IPv6_Enabled -eq "1" ]; then 
		echo "\$SERVER[\"socket\"] == \"[::]:$HttpsPort_num\" {" >> /tmp/lighttpd-inc_ssl.conf
		echo "server.use-ipv6 = \"enable\"" >> /tmp/lighttpd-inc_ssl.conf
	else 
		echo "\$SERVER[\"socket\"] == \":$HttpsPort_num\" {" >> /tmp/lighttpd-inc_ssl.conf
	fi
	echo "ssl.engine = \"enable\"" >> /tmp/lighttpd-inc_ssl.conf
	echo "ssl.pemfile = \"/tmp/server.pem\"" >> /tmp/lighttpd-inc_ssl.conf
	echo "ssl.use-sslv2 = \"disable\"" >> /tmp/lighttpd-inc_ssl.conf
	echo "ssl.use-sslv3 = \"disable\"" >> /tmp/lighttpd-inc_ssl.conf
	echo "ssl.cipher-list = \"RC4-MD5 RC4-SHA AES128-SHA AES256-SHA DHE-RSA-AES128-SHA DHE-RSA-AES256-SHA DES-CBC3-SHA\"}" >> /tmp/lighttpd-inc_ssl.conf
	setupAuth >> /tmp/lighttpd-inc_ssl.conf
	# create dynamic user conf
	setupAdmin "$AdminUser_ss" "$AdminPasswd_ss"
	[ "$User1_ss" != "" ] && setupUser "$User1_ss" "$Password1_ss"
	[ "$User2_ss" != "" ] && setupUser "$User2_ss" "$Password2_ss"
	[ "$User3_ss" != "" ] && setupUser "$User3_ss" "$Password3_ss"
	[ "$User4_ss" != "" ] && setupUser "$User4_ss" "$Password4_ss"
	[ "$User5_ss" != "" ] && setupUser "$User5_ss" "$Password5_ss"
	[ "$User6_ss" != "" ] && setupUser "$User6_ss" "$Password6_ss"
	[ "$User7_ss" != "" ] && setupUser "$User7_ss" "$Password7_ss"
	[ "$User8_ss" != "" ] && setupUser "$User8_ss" "$Password8_ss"
	[ "$User9_ss" != "" ] && setupUser "$User9_ss" "$Password9_ss"
	[ "$User10_ss" != "" ] && setupUser "$User10_ss" "$Password10_ss"
	[ "$User11_ss" != "" ] && setupUser "$User11_ss" "$Password11_ss"
	[ "$User12_ss" != "" ] && setupUser "$User12_ss" "$Password12_ss"
	[ "$User13_ss" != "" ] && setupUser "$User13_ss" "$Password13_ss"
	[ "$User14_ss" != "" ] && setupUser "$User14_ss" "$Password14_ss"
	[ "$User15_ss" != "" ] && setupUser "$User15_ss" "$Password15_ss"
	[ "$User16_ss" != "" ] && setupUser "$User16_ss" "$Password16_ss"
	[ "$User17_ss" != "" ] && setupUser "$User17_ss" "$Password17_ss"
	[ "$User18_ss" != "" ] && setupUser "$User18_ss" "$Password18_ss"
	[ "$User19_ss" != "" ] && setupUser "$User19_ss" "$Password19_ss"
	[ "$User20_ss" != "" ] && setupUser "$User20_ss" "$Password20_ss"
	[ "$Operator1_ss" != "" ] && setupUser "$Operator1_ss" "$OperatorPwd1_ss"
	[ "$Operator2_ss" != "" ] && setupUser "$Operator2_ss" "$OperatorPwd2_ss"
	[ "$Operator3_ss" != "" ] && setupUser "$Operator3_ss" "$OperatorPwd3_ss"
	[ "$Operator4_ss" != "" ] && setupUser "$Operator4_ss" "$OperatorPwd4_ss"
	[ "$Operator5_ss" != "" ] && setupUser "$Operator5_ss" "$OperatorPwd5_ss"
	#deny /volumes/local
	echo "\$HTTP[\"url\"] =~ \"^/volumes/\" { url.access-deny = (\"\") }" >> /tmp/lighttpd-inc_ssl.conf
	# start...
	while [ ! -f "/tmp/server.pem" ]; do 
		sleep 1
	done
	$binary -f $prefix/etc/lighttpd/lighttpd_ssl.conf -m $prefix/lib
	echo "ok."
}

status() {
	echo -n "$daemon"
	pids=$(pidof $daemon) && echo "($pids) is running." || echo " is stop."
}

stop() {
	pids=$(pidof $daemon) || { echo "$daemon is not running." && return 1; }
	echo -n "Stopping $daemon... "
	kill $(echo $pids | cut -d' ' -f1)
	sleep 1
	pids=$(pidof $daemon) && killall -9 $daemon && sleep 1 && pids=$(pidof $daemon) && die "ng." || echo "ok."
}

action=$1
prefix=$2
end=$3

[ "$end" = "" ] && [ "$action" != "" ] || showUsage
[ "$prefix" = "" ] || [ -d "$prefix" ] || die "$prefix is not a valid directory"

ln -sf $prefix/sbin/lighttpd $prefix/sbin/$daemon
conf=$prefix/etc/$daemon.conf
binary=$prefix/sbin/$daemon

case $action in
	start)
		start
	;;
	stop)
		stop
	;;
	restart)
		stop
		start
	;;
	status)
		status
	;;
	*)
		showUsage
	;;
esac

exit 0
