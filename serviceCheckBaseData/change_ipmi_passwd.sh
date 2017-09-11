#!/bin/bash
downloadserver1='223.203.98.51'
downloadserver2='61.240.134.172'
red='\033[40;31m'
green='\033[40;32m'
back='\033[40;37m'
ipmirpm='OpenIPMI-2.0.16-16.el5.x86_64.rpm'
ipmi_lib='OpenIPMI-libs-2.0.16-16.el5.x86_64.rpm'
ipmi_tools='OpenIPMI-tools-2.0.16-16.el5.x86_64.rpm'
lsb_ver=`whereis redhat-lsb |awk '{print $2}'`
if [ -z "$lsb_ver" ]
then
yum install -y redhat-lsb
fi
lsb=`lsb_release -r|awk  '{print $2}'|awk -F'.' '{print $1}'`

#grep -q sohu /etc/hosts || (chattr -ai /etc/hosts &&  echo "221.236.12.140 mirrors.sohu.com" >> /etc/hosts && chattr +ai /etc/hosts)
source /etc/profile
if ! test `rpm -qa OpenIPMI`;then
	yum -y install OpenIPMI
        if [ $? -ne 0 ];then
	        wget -T 5 -t 2 -O /root/${ipmirpm} http://${downloadserver1}/${ipmirpm}
                if [ $? -ne 0 ];then
	                wget -T 5 -t 2 -O /root/${ipmirpm} http://${downloadserver2}/${ipmirpm}
                        if [ $? -ne 0 ];then
        	                echo -e "${red}${ipmirpm} not download sucessfully!Please try manual download .${back}"
                                exit 1
                        fi
                fi
                wget -T 5 -t 2 -O /root/${ipmi_lib} http://${downloadserver1}/${ipmi_lib}
                if [ $? -ne 0 ];then
                        wget -T 5 -t 2 -O /root/${ipmi_lib} http://${downloadserver2}/${ipmi_lib}
                        if [ $? -ne 0 ];then
                                echo -e "${red}${ipmi_lib} not download sucessfully!Please try manual download .${back}"
                                exit 1
                        fi
                fi
                rpm -ivh /root/${ipmi_lib}
                rpm -ivh /root/${ipmirpm}
        fi
fi
if ! test `rpm -qa OpenIPMI-tools`;then
        yum -y install OpenIPMI-tools
        if [ $? -ne 0 ];then
                wget -T 5 -t 2 -O /root/${ipmi_tools} http://${downloadserver1}/${ipmi_tools}
                if [ $? -ne 0 ];then
                        wget -T 5 -t 2 -O /root/${ipmi_tools} http://${downloadserver2}/${ipmi_tools}
                        if [ $? -ne 0 ];then
                                echo -e "${red}${ipmi_tools}not download sucessfully!Please try manual download .${back}"
                                exit 1
                        fi
                fi
                rpm -ivh /root/${ipmi_tools}
        fi
fi

/etc/init.d/ipmi start>/dev/null 2>&1
sleep 1
CHANNEL=`for i in {1..14}; do /usr/bin/ipmitool lan print $i 2>/dev/null | grep -q ^Set && echo $i; done|head -n 1`

USER='chinacache'
PASS='6e88790e13ded'
USERID=6
/usr/bin/ipmitool user set name $USERID $USER
/usr/bin/ipmitool user set password $USERID $PASS
/usr/bin/ipmitool user priv $USERID 4 $CHANNEL
/usr/bin/ipmitool channel  setaccess $CHANNEL $USERID callin=on ipmi=on link=on privilege=4
/usr/bin/ipmitool sol payload enable $CHANNEL $USERID
/usr/bin/ipmitool user enable $USERID

/usr/bin/ipmitool -I open user list $CHANNEL |grep -v "ID" | awk '{if(($2!~"true")&&($2!~"false")&&($2!~"Empty"))print $1,$2}' |while read USERID USER
do
grep -q $USERID /root/sys_user.log || echo "$USERID $USER" >> /root/sys_user.log
#/usr/bin/ipmitool user set name $USERID $USER
/usr/bin/ipmitool user set password $USERID $PASS
/usr/bin/ipmitool user list $CHANNEL|grep ^$USERID
done
/etc/init.d/ipmi stop>/dev/null 2>&1

#history -w
#history -c
#rm -rf /root/.bash_history
