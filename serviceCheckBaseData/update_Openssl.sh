#!/bin/bash
DOWNLOADSERVER='mirrors.chinacache.com'
scripts_name="update_OpenSSL.sh"
ARCH=`uname -i`
wget -q http://223.203.98.51/yum/servers/yum_install.sh -O -|sh
wget http://${DOWNLOADSERVER}/BASE/openssl-0.9.8zf-1.${ARCH}.tar.gz -SO /tmp/openssl-0.9.8zf-1.${ARCH}.tar.gz

function update_openssl(){
    if [ -f  "/tmp/openssl-0.9.8zf-1.${ARCH}.tar.gz" ];then
	echo "Download openssl-0.9.8zf-1.${ARCH}.tar.gz successfully..." >/tmp/vulnerability.rst
    else
	echo "Download openssl-0.9.8zf-1.${ARCH}.tar.gz failed..." >/tmp/vulnerability.rst
	exit 3
    fi
    cd /tmp/
    tar -xvf openssl-0.9.8zf-1.${ARCH}.tar.gz >/dev/null
    rpm -Uvh ca-certificates-2009-2.noarch.rpm openssl-0.9.8zf-1.${ARCH}.rpm --force --noscripts >/dev/null
    if [  "$?" = "0" ];then
	echo -e "Update Openssl 0.9.8zf successuflly ..." >/tmp/vulnerability.rst
	echo -e "${RED}Success${DEFAULT}"
    else
	echo -e "Update Openssl 0.9.8zf failed ..." >/tmp/vulnerability.rst
	echo -e "${RED}Failed${DEFAULT}"
    fi
}
function judge(){
	FILES=`grep -E "hwcap.*nosegneg" /etc/ld.so.conf.d/* | grep -v "#" | awk -F ":" '{print $1}'`
	LINES=`grep -E "hwcap.*nosegneg" /etc/ld.so.conf.d/* | grep -v "#" | wc -l`
	if [ "${LINES}" = "2" ];then
		for i in $FILES;do
			sed -i 's/hwcap 0 nosegneg/hwcap 1 nosegneg/' $i
		done
		update_openssl
	else
		update_openssl
	fi
}

SYS_VER=`head -n1 /etc/issue`
OPENSSL=`openssl version | awk -F" " '{print $1,$2}'`
CentOS6="CentOS release 6.[0-9]"

if [ "$SYS_VER" = "CentOS release 5.8 (Final)" ] || [ "$SYS_VER" = "CentOS release 5.5 (Final)" ] || [ "$SYS_VER" = "CentOS release 5.4 (Final)" ] || [ "$SYS_VER" = "CentOS release 5.10 (Final)" ] || [ "$SYS_VER" = "CentOS release 5.11 (Final)" ];then
	if [ "$ARCH" = "x86_64" ];then
		if [ "$OPENSSL" = "" ];then
			echo -e "Update Openssl 0.9.8zf successuflly ..." >/tmp/vulnerability.rst
			echo -e "${RED}Success${DEFAULT}"
		else
			judge
		fi
	elif [ "$ARCH" = "i386" ];then
        	echo -e "system is 32bits ..." >/tmp/vulnerability.rst
        	echo -e "${RED}system is 32bits ... ${DEFAULT}"
		exit 2
	fi
elif [[ ${SYS_VER} =~ $CentOS6 ]];then
	yum -y update openssl >/dev/null
	#openssl version
	if [ "$?" = "0" ];then
		echo -e "Update OpenSSL successfully ..." >/tmp/vulnerability.rst
		echo -e "${RED}Success${DEFAULT}"
	else
		echo -e "Update OpenSSL failed ..." >/tmp/vulnerability.rst
		echo -e "${RED}Failed ${DEFAULT}"
	fi
else
	echo -e "system version not match ..." >/tmp/vulnerability.rst
	echo -e "${RED}Failed ${DEFAULT}"
fi

rm -rf /tmp/openssl-0.9.8zf-1.${ARCH}.rpm /tmp/ca-certificates-2009-2.noarch.rpm /tmp/openssl-0.9.8zf-1.x86_64.tar.gz 
#rm -rf /tmp/update_OpenSSL.sh

