#!/bin/bash
# Name:         ntp_install.sh
# Version:      1.02
# Date:         2016-04-07
# Last Change:  2016-11-07
# Author:       liulei
# Email:        liulei@chinacache.com
# Describe:     Install or Update all servers's ntpd service. This script can Repeated execution

DOWNLOADSERVER="mirrors.chinacache.com"
test -d /scripts || mkdir /scripts
#if [ `grep mirrors.chinacache.com /etc/hosts|grep -q 98.51;echo $?` -eq 0 ];
#then
#    sed -i '/mirrors.china/d' /etc/hosts
#    mip=`dig $DOWNLOADSERVER @114.114.114.114 +short | grep ^[0-9]| head -1`
#    if [ ! -z "$mip" ]
#    then
#        echo "$mip $DOWNLOADSERVER" >> /etc/hosts
#    else
#        echo "no ip found from $DOWNLOADSERVER"
#    fi
#fi
ps aux| grep -E "ntpd|ntp.sh|ntp.china|ntp_check" |grep -v grep | awk '{print $2}' |xargs kill -9

# check /etc/hosts
Hosts_Check() {
    if [ `grep -q "^::1" /etc/hosts;echo $?` -eq 0 ];
    then
        sed -i 's/^::1/#::1/g' /etc/hosts
    fi
    if [ `grep '127.0.0.1' /etc/hosts|grep -v -q ::1;echo $?` -ne 0 ];
    then
        echo "127.0.0.1   localhost localhost.domain" >> /etc/hosts
    fi
}

# check /sbin/hwclock
Hwclock_Check() {
    if [[ `ls -l /sbin/hwclock|awk '{print $5}'` -ne '32712' ]];
    then
        RELEASE=`cat /etc/redhat-release|grep -oE "[0-9]"|head -1`
        if [ ${RELEASE} -eq 6 ];
        then
            wget -N http://${DOWNLOADSERVER}/BASE/hwclock_6 -O /sbin/hwclock
        else
            wget -N http://${DOWNLOADSERVER}/BASE/hwclock -O /sbin/hwclock
        fi
        chmod 755 /sbin/hwclock
    fi
}

# update yum
Yum_Check() {
    if [ `grep -q mirrors.chinacache.com /etc/hosts;echo $?` -ne 0 ] || [ `grep mirrors.chinacache.com /etc/hosts|grep -q 223.203.98.51;echo $?` -eq 0 ] || [ `grep -q yum_check /etc/crontab;echo $?` -ne 0 ];
    then
        if [ `rpm -q nc > /dev/null;echo $?` -ne 0 ];
        then
            yum -y install nc
            if [ $? -ne 0 ];
            then
                echo "Install nc failed, yum error"
                exit
            fi
        fi
        if [ `nc -vzt 223.203.98.51 80 > /dev/null;echo $?` -eq 0 ];
        then
            wget -qN http://223.203.98.51/yum/servers/yum_install.sh -O -|sh
            wget -N http://223.203.98.51/yum/servers/yum_check.sh -P /scripts/
            sed -i '/yum_check.sh/d' /etc/crontab
            echo "0 * * * * root sh /scripts/yum_check.sh > /dev/null 2>&1" >> /etc/crontab
        else
            echo -e "\E[1;31mCan not connect to 223.203.98.51 port 80\033[0m, Please contact with liulei_pre by RTX or send mail to liulei@chinacache.com."
            exit
        fi
    fi
}

# delete ntp which exist on cron
Ntp_Check(){
    test `rpm -q ntp > /dev/null 2>&1;echo $?` -ne 0 && yum -y install ntp
    
    test `grep -q ntp /etc/crontab > /dev/null 2>&1;echo $?` -eq 0 && sed -i '/ntp/d' /etc/crontab
    
    test `grep -q syntime /etc/cron.d/fc-root-all > /dev/null 2>&1;echo $?` -eq 0 && sed -i '/syntime/d' /etc/cron.d/fc-root-all
    
    test `grep -q ntp /var/spool/cron/root > /dev/null 2>&1;echo $?` -eq 0 && sed -i '/ntp/d' /var/spool/cron/root

    
    /etc/init.d/crond restart > /dev/null 2>&1
}

# use ntp.sh to update time
Repair(){
    wget -N -P /scripts http://223.203.98.51/ntp.sh && chmod +x /scripts/ntp.sh
    echo "0 * * * * root sh /scripts/ntp.sh" >> /etc/crontab
    /etc/init.d/crond restart
    chkconfig ntpd off
}

# ntp.conf use ip address
Use_Ip() {
    # replace domain to ip in the ntp.conf 
    sed -i "s/mirrors.chinacache.com/${IP_HOST}/g" /etc/ntp.conf
    # write available ip to the ntp.conf
    for ((i=0;i<${#NTPSERVER[@]};i++))
    do
        IPLIST=`dig @114.114.114.114 ${NTPSERVER[$i]} +short|grep ^[0-9]`
    	if [[ -z ${IPLIST} ]];
    	then
            IPLIST=`dig @8.8.8.8 ${NTPSERVER[$i]} +short|grep ^[0-9]`
            if [[ -z ${IPLIST} ]];
            then
		break
            fi
        fi
        for ip in ${IPLIST}
        do
            if [ `/usr/sbin/ntpdate -q ${ip}|awk '/delay/{if($NF!="0.00000")print $0}'|grep -v -q no;echo $?` -eq 0 ];
            then
                test `grep -q -w ${ip} /etc/ntp.conf;echo $?` -ne 0 && sed -i "/prefer/a\server ${ip}" /etc/ntp.conf
            fi
        done
    done
	
    # if no available ip, repair and show warning msg
    if [ `awk '/server/{if($2!="127.127.1.0")print $2}' /etc/ntp.conf|wc -l` -eq 1 ] && [ `/usr/sbin/ntpdate -q ${IP_HOST} |awk '/delay/{if($NF!="0.00000")print $0}'|grep -v -q no;echo $?` -ne 0 ];
    then
        echo -e "\E[1;31mntpd Unavailable\033[0m, you can put this command \E[1;32mrdate -s ${IP_HOST}\033[0m in the crontab to update time.\nWhile you can also contact with liulei_pre by RTX or send mail to liulei@chinacache.com."
        Repair
        exit
    fi
}

# ntp.conf use domain
#Use_Domain(){
#    # write available ip to the ntp.conf
#    for ((i=0;i<${#NTPSERVER[@]};i++))
#    do
#        IPLIST=`dig @114.114.114.114 ${NTPSERVER[$i]} +short|grep ^[0-9]`
#        if [[ -z ${IPLIST} ]];
#        then
#            IPLIST=`dig @8.8.8.8 ${NTPSERVER[$i]} +short|grep ^[0-9]`
#            if [[ -z ${IPLIST} ]];
#            then
#                #echo -e "\E[1;31mresolve failed\033[0m, please contact with liulei_pre by RTX or send mail to liulei@chinacache.com."
#                #Repair
#                #exit
#		break
#            fi
#        fi
#        for ip in ${IPLIST}
#        do
#            if [ `/usr/sbin/ntpdate -q ${ip}|awk '/delay/{if($NF!="0.00000")print $0}'|grep -v -q no;echo $?` -eq 0 ];
#            then
#                if [ `grep -q ${ip} /etc/hosts;echo $?` -ne 0 ];
#                then
#                    sed -i "/${NTPSERVER[$i]}/d" /etc/hosts
#                    echo "${ip} ${NTPSERVER[$i]}" >> /etc/hosts
#		    sed -i "/${NTPSERVER[$i]}/d" /etc/ntp.conf
#                    sed -i "/prefer/a\server ${NTPSERVER[$i]}" /etc/ntp.conf
#                    break
#                fi
#            fi
#        done
#    done
#
#    # if no available ip, repair and show warning msg
#    if [ `awk '/server/{if($2!="127.127.1.0")print $2}' /etc/ntp.conf|wc -l` -eq 1 ] && [ `/usr/sbin/ntpdate -q mirrors.chinacache.com |awk '/delay/{if($NF!="0.00000")print $0}'|grep -v -q no;echo $?` -ne 0 ];
#    then
#        echo -e "\E[1;31mntpd Unavailable\033[0m, you can put this command \E[1;32mrdate -s mirrors.chinacache.com\033[0m in the crontab to update time.\nWhile you can also contact with liulei_pre by RTX or send mail to liulei@chinacache.com."
#        Repair
#        exit
#    fi
#}

# check mirrors.chinacache.com resolve
Yum_Check
echo -e "\E[1;33mLast system time: `date +"%F %T"`\033[0m"

# repair hardwire clock
Hwclock_Check

# rsync time
rdate -s mirrors.chinacache.com
if [ $? -ne 0 ];
then
    /etc/init.d/ntpd stop
    ntpdate mirrors.chinacache.com
fi

# repair soft clock
hwclock --systohc
echo -e "\E[1;32mCurrent system time: `date +"%F %T"`\033[0m"

# install ntp
if [ `wc -l /etc/ntp.conf|cut -d " " -f 1` -gt 20 ] || [ `/etc/init.d/ntpd status > /dev/null 2>&1;echo $?` -ne 0 ] || [ `grep -q -E "^::1" /etc/hosts;echo $?` -eq 0 ];
then
    # clear crontab of ntp
    Ntp_Check
    NTP_STATUS=`/etc/init.d/ntpd status > /dev/null 2>&1;echo $?`
    IP_PING=`ping mirrors.chinacache.com -c 1|head -1|grep -o -E "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+"`
    IP_HOST=`grep mirrors.chinacache.com /etc/hosts|grep -v \#|awk '{print $1}'`
    if [ ${NTP_STATUS} -eq 0 ];
    then
        yes | cp /etc/ntp.conf /etc/ntp.conf.bk
        /etc/init.d/ntpd stop
    fi
    chattr -ia /etc/ntp.conf
    chattr -ia /etc/sysconfig/ntpd
    chattr -ia /etc/hosts
    # modify /etc/hosts before unlock
    Hosts_Check

    echo "driftfile /var/lib/ntp/drift
restrict default kod nomodify notrap nopeer noquery
restrict 127.0.0.1 
server mirrors.chinacache.com prefer
server 127.127.1.0
fudge  127.127.1.0 stratum 15	
includefile /etc/ntp/crypto/pw
keys /etc/ntp/keys
disable monitor
logfile /var/log/ntp.log" > /etc/ntp.conf
fi

NTPSERVER=(
    [0]=0.centos.pool.ntp.org
    [1]=cn.pool.ntp.org
    [2]=ntp.sjtu.edu.cn
    [3]=dns.sjtu.edu.cn
    [4]=dns2.synet.edu.cn
)

if [[ ${IP_PING} != ${IP_HOST} ]];
then
    # resolve unavailable so use ip
    Use_Ip
else
    for ((i=0;i<${#NTPSERVER[@]};i++))
    do
        sed -i "/prefer/a\server ${NTPSERVER[$i]}" /etc/ntp.conf
    done
fi
sed -i -r 's/(^SYNC_HWCLOCK=)[^$]*/\1yes/' /etc/sysconfig/ntpd
chkconfig ntpd on
/etc/init.d/ntpd restart

if [ `hwclock > /dev/null 2>&1;echo $?` -ne 0 ];
then
    wget http://223.203.98.51/yum/servers/repair_hwclock.sh -O-|sh
    if [ `hwclock > /dev/null 2>&1;echo $?` -ne 0 ];
    then
        echo "The server need reboot, after excute this script again."
    fi
fi

sleep 3
# check ntpd available?
if [ `ntpq -p|grep -q LOCAL > /dev/null 2>&1;echo $?` -ne 0 ];
then
    ntpq -p
    echo -e "\033[35m ntpd service not available \033[0m"
    /etc/init.d/ntpd stop
    Repair
fi

echo -e "\033[35m HardWare time is :\033[0m" `hwclock`
echo -e "\E[1;32mntp update success!\033[0m"
