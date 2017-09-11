#!/bin/sh
if [ `grep -q mirrors.chinacache.com /etc/hosts;echo $?` -ne 0 ];
then
    wget -qN http://223.203.98.51/yum/servers/yum_install.sh -O -|sh
fi
PERL=`ls /usr/bin/perl`
if [ -z "$PERL" ]
then
    yum install -y perl
fi

KERN=`uname -r |grep -oP 'el\d+'`

yum update krb5-libs.x86_64 -y && yum install krb5-libs.i686 -y
yum install -y libxml2.so.2 
yum install libxml2-devel.i686 -y 
yum update krb5-libs.x86_64 -y 
yum install libgssapi_krb5.so.2 -y 
sys=`cat /etc/issue|head -1|awk -F. '{print $1}'`
if [ "$sys" = "CentOS release 6" ]
then
  rpm -Uvh http://mirrors.chinacache.com/BASE/libcom_err-1.41.12-22.el6.x86_64.rpm --force --nodeps
fi
wget -qN http://mirrors.chinacache.com/BASE/copUpdate.sh -O-|sh
#copUpdater --update 61.135.208.24 --download 61.135.208.24
yum install -y  libz.so.1
wget http://mirrors.chinacache.com/BASE/hosts.allow -O /etc/hosts.allow
DATE=`date +%s`
cp -r /Application/dm/etc/dir.d /Application/dm/etc/dir.d_$DATE
wget -qNO /Application/dm/etc/dir.d.fc.tar.gz  http://mirrors.chinacache.com/BASE/dir.d.fc.tar.gz
#wget -N -qO /Application/dm/etc/dir.d.fc.tar.gz  http://223.202.197.223/dm/dir.d.fc.tar.gz
/bin/tar zxf /Application/dm/etc/dir.d.fc.tar.gz -C /Application/dm/etc/ -p
touch /var/log/ccamr/200001010005.log

if [ "$KERN" == "el7" ];then
echo "[Unit]
Description=amr
After=network.target

[Service]
StandardOutput=null
ExecStart=/usr/sbin/ccAMRd
ExecStop=null
PrivateTmp=true

[Install]
WantedBy=multi-user.target" > /usr/lib/systemd/system/amr.service

wait
systemctl enable amr.service

wait
systemctl start amr.service

else
    amr restart amr
fi

amr restart ta
amr restart ng
amr restart oh
amr restart dm


sleep 5
amr list
