#!/bin/bash

##########################################################
##Uprade OpenSSL to resolve Vulnerablity(CVE-2015-1793) ##
##########################################################

#SCRIPT_NAME="upgrade_OpenSSL.sh"
#PACKAGE_NAME="openssl-1.0.1p.tgz"
#WGET="/usr/bin/wget"
wget -q http://223.203.98.51/yum/servers/yum_install.sh -O -|sh

update(){
	#cd /tmp/ && rpm -Uvh /tmp/openssl*1.0.1p*.rpm --replacefiles --nodeps
	cd /tmp/ && rpm -Uvh /tmp/openssl*1.0.1t*.rpm --replacefiles --nodeps
	if [ "$?" = "0" ];then
		CODE="0"
	else
		CODE="1"
	fi
}

SYS_VERSION=`lsb_release -r | awk '{print $2}' | cut -d '.' -f1`
if [ ${SYS_VERSION} -eq "6" ];then
	JUDGE=`rpm -q openssl | grep "openssl-1.0.1t"`
	if [ "$JUDGE" = "" ];then
		#yumdownloader --destdir=/tmp openssl-devel-1.0.1p openssl-static-1.0.1p openssl-1.0.1p
		yumdownloader --destdir=/tmp openssl-devel-1.0.1t openssl-static-1.0.1t openssl-1.0.1t
		if [ "$?" = "0" ];then
			update
		else
			CODE="3"
		fi
	else
		CODE="0"
	fi
else
	CODE="2"
fi
 
case $CODE in
	0) echo "OpenSSL 1.0.1t Upgrade Successfully." >> /root/openssl.rst;;
	1) echo "OpenSSL 1.0.1t Upgrade Failed." >> /root/openssl.rst;;
	2) echo "SYS_VERSION ERROR" >> /root/openssl.rst;;
	3) echo "Download PACKAGES Failed" >> /root/openssl.rst;;
	*) echo "$0 Running Failed." >> /root/openssl.rst;;
esac

