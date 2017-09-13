#!/bin/bash

today=`date +%m%d`
smsversion=$1
fc_version=`rpm -qa |grep 'FC-7.0.255-C.rdb' |wc -l`
sleep 2;
fc_pid_num=`ps -ef |grep squi[d] |wc -l`
fc_install=`rpm -qa |grep F[C]|wc -l`
if [ $fc_version -eq 0 ];then
if [ $fc_pid_num -eq 0 ];then
    echo "       FC not run ..."
else
    /etc/init.d/flexicache stop;
fi
if [ $fc_install -eq 0 ];then
    echo "       FC not install ..."
else
    rpm -e FC;
    rpm -e FC;
    sleep 1;
fi
else
    echo "This device is sms_source . . . "
fi

if [ ! -n "$smsversion" ];then
    read -p "please enter SMS-rpm-version:" smsversion
    echo "vill be install sms version:$smsversion"
else
    echo "vill be install sms version:$smsversion"
fi
curl -Ss http://223.202.204.146:8080/xiaohui.lou/uninstall_mvod.sh  |bash
sleep 1;

ppswf() {
  mkdir -p /usr/local/sms_bak/swf

  wget -O /usr/local/sms_bak/swf/kkweilivetest.swf http://223.202.204.151:8080/people/kkweilivetest.swf
  wget -O /usr/local/sms_bak/swf/liveplayer.swf http://223.202.204.151:8080/people/liveplayer.swf
  ls /usr/local/sms_bak/swf
}

ppswf


mkdir -p /data/proclog/log/sms/access && echo "mkdir access" > /tmp/sms_install.log 2>&1;
mkdir -p /data/proclog/log/sms/cache && echo "mkdir cache" > /tmp/sms_install.log 2>&1;
mkdir -p /data/proclog/log/sms/billing && echo "mkdir billing" > /tmp/sms_install.log 2>&1;
mkdir -p /data/proclog/log/sms/httpbilling&& echo "mkdir httpbilling" > /tmp/sms_install.log 2>&1;
mkdir -p /usr/local/sms_bak && echo "mkdir sms_bak" > /tmp/sms_install.log 2>&1;
mkdir /usr/local/sbin/sms > /dev/null 2>&1;

wget  -O /etc/ChinaCache/app.d/SMSSERVER.amr  223.202.204.151:8080/SMSSERVER.amr > /tmp/sms_install.log 2>&1;
/usr/sbin/amr restart amr && echo "amr restart ok" > /tmp/sms_install.log 2>&1;

get_ssl_key () {
        /usr/bin/wget -qO /usr/local/ccCert/2017122012-live-lx-hdl.huomaotv.cn-2017020812.crt http://223.202.204.151:8080/httplive001/ssl/2017122012-live-lx-hdl.huomaotv.cn-2017020812.crt
        /usr/bin/wget -qO /usr/local/ccCert/2017122012-live-lx-hdl.huomaotv.cn-2017020812.key http://223.202.204.151:8080/httplive001/ssl/2017122012-live-lx-hdl.huomaotv.cn-2017020812.key
}

check_ssl_dir () {
    if [ ! -d /usr/local/ccCert ];then
        mkdir -p /usr/local/ccCert;
        get_ssl_key;
    else
        if [ ! -f /usr/local/ccCert/2017122012-live-lx-hdl.huomaotv.cn-2017020812.crt ];then
            get_ssl_key;
        fi
    fi
}

rm -f /Application/dm/etc/dir.d/DM-SMS.yaml.default > /tmp/sms_install.log 2>&1;
wget  -O /Application/dm/etc/dir.d/DM-SMS.yaml.default  223.202.204.151:8080/sms002/DM-SMS.yaml.default > /tmp/sms_install.log 2>&1;
#/usr/sbin/amr restart dm && echo "dm restart  ok";
wget -qO-  http://223.202.197.223/dm/fc_updatedm.sh|bash  #update dm
	
rm -f /Application/ng/etc/info.d/NG-SMS.yaml.default > /tmp/sms_install.log 2>&1;
wget  -O /Application/ng/etc/info.d/NG-SMS.yaml.default  223.202.204.151:8080/NG-SMS.yaml.default > /tmp/sms_install.log 2>&1;
#/usr/sbin/amr restart  ng && echo "ng restart ok";

cd && rm -f $smsversion* > /tmp/sms_install.log 2>&1;
wget -S http://223.202.204.151:8080/sms-rpm-version/$smsversion > /tmp/sms_install.log 2>&1;
rpm -ivh $smsversion > /tmp/sms_install.log 2>&1;
mv /usr/local/sms/conf/nginx.conf /usr/local/sms/conf/nginx.conf.bak > /tmp/sms_install.log 2>&1;
	
wget  -O  /usr/local/sms_bak/crossdomain.xml 223.202.204.151:8080/crossdomain.xml > /tmp/sms_install.log 2>&1;
echo "wget crossdomain.xml ok" > /tmp/sms_install.log 2>&1;
	
#wget -SO /usr/local/sms/lua/bianfeng/play_bianfeng.lua http://223.202.204.151:8080/play_bianfeng.lua > /tmp/sms_install.log 2>&1;
	
/usr/sbin/amr restart dm  && echo dm restart ok > /tmp/sms_install.log 2>&1;
/usr/sbin/amr restart  ng && echo ng restart ok > /tmp/sms_install.log 2>&1;

chattr -ai /etc/resolv.conf > /tmp/sms_install.log 2>&1;
echo "nameserver 114.114.114.114" > /etc/resolv.conf;
echo "nameserver 8.8.8.8" >> /etc/resolv.conf;
echo "127.0.0.1  sms.information.center" >> /etc/hosts;
	
cd && wget -SO /usr/local/sbin/sms/sms_monitor.sh http://223.202.204.151:8080/sms_monitor.sh > /tmp/sms_install.log 2>&1;
echo "*/2 * * * * root bash /usr/local/sbin/sms/sms_monitor.sh" >>/etc/crontab;
	
wget -qO /usr/local/sms/flvconfupdate.sh 202.110.80.160:8080/httplive001/bash/flvconfupdate.sh && bash /usr/local/sms/flvconfupdate.sh $today  > /dev/null 2>&1
#wget -qO /usr/local/sms/confupdate.sh 202.110.80.160:8080/httplive001/bash/rtmpconfupdate.sh && bash /usr/local/sms/confupdate.sh $today > /dev/null 2>&1
wget -O /usr/local/sms/conf/nginx.conf http://223.202.204.151:8080/sms002/nginx.conf > /tmp/sms_install.log 2>&1;

sleep 10;

/usr/local/sms/sbin/nginx -t > /tmp/sms_install.log 2>&1;
if [ $? -eq 0 ]; then
	/usr/local/sms/sbin/nginx -c /usr/local/sms/conf/nginx.conf;
	echo '0 */1 * * * /usr/sbin/ntpdate -u -t 5 ntp.chinacache.com 2>&1 /dev/null' > /var/spool/cron/root 2>&1;
else
	echo "conf file has error" > /tmp/sms_install.log 2>&1;
	echo "conf file has error" ;
fi

