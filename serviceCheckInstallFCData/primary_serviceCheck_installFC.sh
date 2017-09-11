#!/bin/bash
#---------------------------------------------------------------------------|
#  @Program   : serviceCheck_Base                                           |  
#  @Version   : 1.0                                                         |
#  @Company   : china cache                                                 |
#  @Dep.      : inm                                                         |
#  @Writer    : bin.zheng  <bin.zheng@chinacache.com>                       |
#  @Date      : 2014-12-16                                                  |
#  @Alter     : 2014-12-16                                                  |
#---------------------------------------------------------------------------|
X86Newker=2.6.37
NewKer=2.6.24.4
FCVERNUM=FlexiCache-V5.6.1.11.R.11834
#FCVERNUM=FlexiCache-V7.0.12.R
SYS=`arch`
FCVER=$FCVERNUM.$SYS
DOWNLOADSERVICE=223.203.98.51
DOWNLOADSERVICE2=mirrors.chinacache.com
LDCdownload='http://$DOWNLOADSERVICE/ldc_setup070403.tgz'
Iptablesdownload='http://$DOWNLOADSERVICE/iptables'
Hostsallowdownload='http://$DOWNLOADSERVICE/hosts.allow'
KERNEL=`uname -r|awk -F'-' '{print $1}'`
updateyes="$1"
shift
KERNEL=`uname -r|awk -F'-' '{print $1}'`
RELEASE=`cat /etc/redhat-release|grep -oE "[0-9]"|head -1`
#---------------FUNCTION DEFINITION---------------
sixtyFour()
{
	rpm -q bind
	if [ $? -ne 0 ];then
		echo -en "\033[32mheihei\033[0m"
		echo "Install named service"
		if [ ! -f /root/bind-9.3.6-4.P1.el5_4.2.x86_64.rpm ] || [ `du -k bind-9.3.6-4.P1.el5_4.2.x86_64.rpm |awk '{print $1}'` -lt 990 ];then
			wget -T 5 -t 2 -O ./bind-9.3.6-4.P1.el5_4.2.x86_64.rpm  http://$DOWNLOADSERVICE/RPMS/bind-9.3.6-4.P1.el5_4.2.x86_64.rpm 
			if [ $? -ne 0 ];then
				wget -T 5 -t 2 -O ./bind-9.3.6-4.P1.el5_4.2.x86_64.rpm  http://$DOWNLOADSERVICE2/RPMS/bind-9.3.6-4.P1.el5_4.2.x86_64.rpm
			fi
		fi
		rpm -ivh bind-9.3.6-4.P1.el5_4.2.x86_64.rpm  
		if [ $? -ne 0 ];then
            echo "nameserver        114.114.114.114" >/etc/resolv.conf
            yum -y install bind
        fi
		rpm -qa bind |grep -q  "bind"
		if [ $? -eq 0 ];then
			echo -ne "\033[40;32m bind is ok ! \033[40;37m"
		else
			echo echo -ne "\033[40;31m bind is not install!!! please check... \033[40;37m"
			exit 1
		fi
	fi
	wget -T 5 -t 2 -O ./named.tar.gz  http://$DOWNLOADSERVICE/named.tar.gz
	if [ $? -ne 0 ];then
		wget -T 5 -t 2 -O ./named.tar.gz  http://$DOWNLOADSERVICE2/BASE/named.tar.gz
	fi
	tar zxf named.tar.gz -C /var/named
	service named restart  >/dev/null 2>&1
	echo -en "\033[33m named install ok \033[0m"
	AddCMD
	if [ `lspci | wc -l ` -lt 3  ];then
		VIRTUAL
	fi
	if   `! cat /etc/passwd | grep "squid" >/dev/null`;then
		useradd  -s /bin/nologin squid
                usermod -G squid sonar
	fi
}

checksnmp_sysstat()
{
	rpm -ql net-snmp >/dev/null
	if [ $? -ne 0 ];then
	  wget -T 5 -t 2 -O /root/net-snmp-5.1.2-11.EL4.10.i386.rpm http://$DOWNLOADSERVICE/addPa/net-snmp-5.1.2-11.EL4.10.i386.rpm
		if [ $? -ne 0 ];then
			wget -T 5 -t 2 -O /root/net-snmp-5.1.2-11.EL4.10.i386.rpm http://$DOWNLOADSERVICE2/addPa/net-snmp-5.1.2-11.EL4.10.i386.rpm
		fi
	  rpm -ivh /root/net-snmp-5.1.2-11.EL4.10.i386.rpm
	fi
	rpm -ql sysstat >/dev/null
	if [ $? -ne 0 ];then
		wget -T 5 -t 2 -O /root/sysstat-5.0.5-14.rhel4.i386.rpm http://$DOWNLOADSERVICE/addPa/sysstat-5.0.5-14.rhel4.i386.rpm
		if [ $? -ne 0 ];then
			wget -T 5 -t 2 -O /root/sysstat-5.0.5-14.rhel4.i386.rpm http://$DOWNLOADSERVICE2/addPa/sysstat-5.0.5-14.rhel4.i386.rpm
		fi
		rpm -ivh /root/sysstat-5.0.5-14.rhel4.i386.rpm
	fi
}

VIRTUAL()
{
	mkdir /data/proclog/refresh_db
	mkdir /data/refresh_db
	mount --bind /data/proclog/refresh_db /data/refresh_db
	egrep -q "/data/refresh_db" /etc/fstab|| echo "/data/proclog/refresh_db        /data/refresh_db        none    rw,bind 0 0" >>/etc/fstab
	#MOUNT
}

#MOUNT()
#{
# virtual_server cache partition mount
#	echo -en "\033[40;32m"
#	echo "mount virtual_Server cache partition"
#	echo -en "\033[40;37m"
#    pf=(`fdisk -l   2>&1 |grep 'Disk /dev/sd'  |awk '{print $2}' |awk -F: '{print $1}' | sort| uniq`)
#    Disk_num=${#pf[*]}
#    for ((i=0;i<Disk_num-1;))
#	do
#		tmp=${pf[$i]}
#		((i++))
#		if `! grep $tmp /etc/fstab >/dev/null`;then
#			mkdir -p /data/cache$i
#			echo "$tmp /data/cache$i	ext3	noatime,nodiratime	0 0"	>> /etc/fstab
#		fi
#	done
#	if `! grep ${pf[$i]} /etc/fstab >/dev/null`;then
#		mkdir -p /data/proclog
#        echo "${pf[$i]} /data/proclog   ext3	noatime,nodiratime 0 0"    >> /etc/fstab
#    fi
#	mount -a
#}

AddCMD()
{
#	if ! rpm -qa sysstat > /dev/null
#	then
		wget -T 5 -t 2 -O ./sysstat-7.0.2-3.el5_5.1.x86_64.rpm  -q http://$DOWNLOADSERVICE/addPa/sysstat-7.0.2-3.el5_5.1.x86_64.rpm 2>&1
		if [ $? -ne 0 ];then
			wget -T 5 -t 2 -O ./sysstat-7.0.2-3.el5_5.1.x86_64.rpm  -q http://$DOWNLOADSERVICE2/addPa/sysstat-7.0.2-3.el5_5.1.x86_64.rpm
		fi
		rpm -ih sysstat-7.0.2-3.el5_5.1.x86_64.rpm --force --nodeps
		rm -rf ./sysstat-7.0.2-3.el5_5.1.x86_64.rpm 
#	fi
#	if ! rpm -qa iptraf > /dev/null
#	then
		wget -T 5 -t 2 -O ./iptraf-3.0.0-5.el5.x86_64.rpm -q http://$DOWNLOADSERVICE/addPa/iptraf-3.0.0-5.el5.x86_64.rpm 2>&1
		if [ $? -ne 0 ];then
			wget -T 5 -t 2 -O ./iptraf-3.0.0-5.el5.x86_64.rpm -q http://$DOWNLOADSERVICE2/addPa/iptraf-3.0.0-5.el5.x86_64.rpm
		fi
		rpm -ih iptraf-3.0.0-5.el5.x86_64.rpm --force --nodeps
		rm -rf  ./iptraf-3.0.0-5.el5.x86_64.rpm
#	fi
	InstallSnmpd
	checkgcc
}

InstallSnmpd()
{
	echo "nameserver        114.114.114.114" >/etc/resolv.conf
	yum install -y net-snmp-*
	yum install -y nmap*
	echo "com2sec notConfigUser  default       ccsecurity_readonly" >>/etc/snmp/snmpd.conf 
	echo "nameserver 127.0.0.1" >/etc/resolv.conf
}

checkgcc()
{
	re=`find /usr/ -name "gcc"|grep "/usr/bin/gcc"`
	#re=`which gcc`
	#if [ "$re" != "/usr/bin/gcc" ];then
	if [ "$re" == "" ];then
	  echo -e "\033[40;31m gcc is not install!  Install it now ! please wait 30 min........... \033[40;37m"
	  sleep 5
	  wget -T 5 -t 2 -T 5 -t 2 -O /root/repairgcc.sh http://${DOWNLOADSERVICE}:9999/repairgcc.sh
		if [ $? -ne 0 ];then
			wget -T 5 -t 2 -T 5 -t 2 -O /root/repairgcc.sh http://$DOWNLOADSERVICE2/repairgcc.sh
		fi
	  sh /root/repairgcc.sh 
	  rm -rf /root/repairgcc.sh
	  echo -e "\033[40;32m Install is ok ! \033[40;37m" 
	  sleep 5
	fi
}

SquidInstall()
{
#squid install
#while :
#do
        echo -e "\033[40;32m"
#        echo "Install squid?(Y or N) "
        echo "Install squid"
#        read AN
        echo -e "\033[40;37m"
#        case $AN in
#        y|Y|yes|Yes)
                echo -e "\033[40;32m"
                echo "**********Now install squid**********"
                echo -e "\033[40;37m"
                OLDpath="$PWD"
                cd /tmp
                wget -T 5 -t 2 http://$DOWNLOADSERVICE/$FCVER.tgz  -O $FCVER.tgz
				if [ $? -ne 0 ];then
					wget -T 5 -t 2 http://$DOWNLOADSERVICE2/BASE/$FCVER.tgz  -O $FCVER.tgz
				fi
                tar zxf $FCVER.tgz
                cd $FCVER
                ./InstallSquidsetup.sh
                cd $OLDpath
		echo -e "\033[40;32m"
		echo -e "change /data/cache* owner\n"
		echo -e "\033[40;37m"
		mkdir -p /data/proclog/log/squid
		chown -R squid:squid /data
		touch /usr/local/squid/etc/redirect.conf
		chown squid:squid /usr/local/squid/etc/redirect.conf
###update FC.5.0--->FC.7.0####
		#copUpdater --install FC-7.0.12-R.`uname -i` 2&>1 >/dev/null  && echo "FC.7.0 UPDATE " || echo "FC UPDATE IS FAULT,NOW FC VERSION IS FC.5.0"
#############################
#                break
#        ;;
#        n|N|no|No)
#		echo -e "\033[40;32m"
#                echo -e "Please Install squid after!\n"
#                echo -e "\033[40;37m"
#                break;
#        ;;
#        *)
#		echo -e "\033[40;32m"
#                echo -e "$AN : Unknow response. Please Input again!\n"   >&2
#                echo -e "\033[40;37m"   
#        ;;
#        esac
#done

}

X86KERNELUP()
{
if [ "$SYS" == "x86_64" ];then
        chkconfig kudzu off
fi
echo -e "\033[40;32m"
echo -e "Now update the kernel!\n"
echo -e "\033[40;37m"
#OLDpath="$PWD"
#cd /root
#if [ ! -f kernel-2.6.37-1.x86_64-offline.tar.gz ] || [ `du -k kernel-2.6.37-1.x86_64-offline.tar.gz | awk '{print $1}'` -lt 21800 ] ; then
#	wget -T 5 -t 2 -O kernel-2.6.37-1.x86_64-offline.tar.gz http://61.135.208.24/release/kernel/x86_64/kernel-2.6.37-1.x86_64-offline.tar.gz
#fi
#tar zxvf kernel-2.6.37-1.x86_64-offline.tar.gz -C /root
#cd $X86Newker
#chmod +x update_kernel_offline.sh && /root/$X86Newker/update_kernel_offline.sh
#wget -T 5 -t 2  http://61.135.208.24/download/luyc/cc-os-cfg7/ccosupdate-chkdev.sh -O - | bash
#wget -q http://61.135.208.24/download/CCTCPv3/v3.12.sh -O - | bash
#wget -q http://61.135.208.24/download/CCTCPv3/v3.11.sh && chmod +x v3.11.sh && echo "y" | ./v3.11.sh || rm -f v3.11.sh
#wget -T5 -t3 -q http://mirrors.chinacache.com/BASE/download/CCTCPv3/v3.12.sh && chmod +x v3.12.sh && yes|./v3.12.sh || rm -f v3.12.sh

#------------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------- update kernel -----------------------------------------------------------------------------#
wget -T5 -t3 -q http://mirrors.chinacache.com/BASE/download/CCTCPv3/v3.13.sh && chmod +x v3.13.sh && yes|./v3.13.sh || rm -f v3.13.sh
#------------------------------------------------------------------------------------------------------------------------------------#
#------------------------------------------------------------------------------------------------------------------------------------#

if [ $? -eq 0 ];then
	if [ ! -f /Application/oh/etc/config.yaml ];then
        cp /Application/oh/etc/config.yaml.default /Application/oh/etc/config.yaml
        sed -i 's/Acl: disable/Acl: enable/g' /Application/oh/etc/config.yaml
        amr restart oh
    fi
	#reboot
fi
}


#---------------FUNCTION END----------------------
chkconfig kudzu off
if [ "$SYS" == "x86_64" ];then
	sixtyFour
fi
if [ "$SYS" == "i686" ];then
	checksnmp_sysstat
fi
service squid start  > /dev/null
service squid status |grep running > squidstatus.txt
if [ -s squidstatus.txt  ];then
	echo -e "\033[32mSquid service is running...\033[0m"
else
	SquidInstall
fi
rm -f squidstatus.txt
echo "nameserver 127.0.0.1" >/etc/resolv.conf
#copUpdater
#copUpdater --install FC-7.0.12-R.`uname -i`
#copUpdater --update 61.135.208.24 --download 61.135.208.24
#rpm -Uvh http://223.203.98.51/FC-7.0.12-R.x86_64.rpm --force --nodeps
wget -N http://$DOWNLOADSERVICE2/BASE/FC-7.0.12-R.x86_64.rpm && rpm -Uvh FC-7.0.12-R.x86_64.rpm --force --nodeps
rm -f /usr/local/bin/robot.sh
sed -i '/robot/d' /etc/cron.d/fc-root-all
#rpm -ivh http://223.203.98.51/BASE/tencent_log_analyzer-1-1_FCV2.x86_64.rpm
wget -qN http://223.203.98.51/BASE/tencent_log_analyzer-1-1_FCV2.x86_64.rpm && rpm -ivh tencent_log_analyzer-1-1_FCV2.x86_64.rpm && rm -f tencent_log_analyzer-1-1_FCV2.x86_64.rpm

if [ ${RELEASE} -eq 5 ];
then
    wget -qN http://223.203.98.51/FC/kernel_2.6.37-9.sh && sh kernel_2.6.37-9.sh && rm -f kernel_2.6.37-9.sh
elif [ ${RELEASE} -eq 6 ];
then
    wget http://223.203.98.51/HPCC/kernel_update.sh && sh kernel_update.sh && rm -f kernel_update.sh
fi

# change sn to squid.conf
if [ ! -f "/usr/local/squid/etc/squid.conf" ];then
wget http://223.203.98.51/squid.conf -O /usr/local/squid/etc/squid.conf
fi
if [ -f "/sn.txt" ]
then
  sn_content=`cat /sn.txt`
  squid_sn=`grep "^visible_hostname" /usr/local/squid/etc/squid.conf | awk '{print $2}'`
  if [ "$sn_content" != "$squid_sn" ]
  then
    sed -i 's/'"$squid_sn"'/'"$sn_content"'/g' /usr/local/squid/etc/squid.conf
  fi
else
  echo -e "\033[31mNo sn.txt found\033[0m"
fi

#Kernel not 2.6.24.4 .Then update kernel.
if [ "$KERNEL" != "$NewKer" ] && [ "$SYS" == "i686"  ] && `! cat /etc/grub.conf | grep "$NewKer" >/dev/null` 
then  
	echo -e "system is $SYS,please check\n"
	exit 3
fi
#x86_64 update kernel
if [ ${RELEASE} -eq 5 ] && [ "$KERNEL" != "$X86Newker" ] && [ "$SYS" == "x86_64"  ]  && `! cat /etc/grub.conf | grep "$X86Newker" >/dev/null`
then
	X86KERNELUP
fi
#-----------------CLEAR HOSTS---------------------#
chattr -ia /etc/hosts
#echo "127.0.0.1 localhost.localdomain localhost" >/etc/hosts

