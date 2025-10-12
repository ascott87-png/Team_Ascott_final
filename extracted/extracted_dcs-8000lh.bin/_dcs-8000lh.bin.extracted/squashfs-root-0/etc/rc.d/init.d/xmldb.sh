#!/bin/sh

echo -n "Setup db... "
cd /tmp
#tar xzf /dev/mtd_ID || /scripts/setup_mac eth0	
tar xzf /dev/mtd_xmldb > /dev/null 2> /dev/null || tar xzf /dev/mtd_xmldb_bak > /dev/null 2> /dev/null || {
	cp -a /etc/db /tmp; cp /tmp/db/default.xml /tmp/db/db.xml; echo "default, ... "; }
[ -f /tmp/db/db.xml ] || { 
	mkdir -p /tmp/db; cp -a /tmp/db.xml /tmp/db/ || cp /etc/db/default.xml /tmp/db/db.xml; }
cd /

echo "ok."
