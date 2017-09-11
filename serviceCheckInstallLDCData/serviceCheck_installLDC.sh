#!/bin/bash
#---------------------------------------------------------------------------|
#  @Program   : serviceCheck_installLDC                                     |  
#  @Version   : 1.1                                                         |
#  @Company   : china cache                                                 |
#  @Dep.      : inm                                                         |
#  @Writer    : bin.zheng  <bin.zheng@chinacache.com>                       |
#  @Date      : 2015-01-06                                                  |
#  @Alter     : 2016-06-13                                                  |
#  @Describe  : Install LDC                                                 |
#---------------------------------------------------------------------------|
SYS=`arch`
X86Newker=2.6.37
KERNEL=`uname -r|awk -F'-' '{print $1}'`
LDCdownload='http://$DOWNLOADSERVICE/ldc_setup070403.tgz'
Iptablesdownload='http://$DOWNLOADSERVICE/iptables'
Hostsallowdownload='http://$DOWNLOADSERVICE/hosts.allow'
DOWNLOADSERVICE=223.203.98.51
DOWNLOADSERVICE2=61.240.134.172

#---------------FUNCTION BEGIN----------------------
IPTABLES()
{
	if [ -f /etc/sysconfig/iptables ] &&  `grep -e "61.135" /etc/sysconfig/iptables > /dev/null`  && `grep -e "-A Cc-allow-nodes -j DROP" /etc/sysconfig/iptables >/dev/null`
	then
        	echo -en "\033[40;32m"
       		echo "iptables is ok!"
	        echo -en "\033[40;37m"
	else
		ldc=1
		while [ "$ldc" = "1" ]
		do
		        echo -en "\033[40;31m"
		        echo "Install iptalbes?(Y or N) "
		        read AN
		        echo -en "\033[40;37m"
		        case $AN in
		        y|Y|yes|Yes)
				echo -en "\033[40;32m"
				echo "**********Now install iptables!**********"
				ldc=2
				echo -en "\033[40;37m"
				rpm -qa iptables >/dev/null
				if [ $? -ne 0 ];then
					yum install iptables
				fi
				rm -f /etc/sysconfig/iptables
				wget -T 5 -t 2 -S  http://$DOWNLOADSERVICE/iptables -O /etc/sysconfig/iptables
				if [ $? -ne 0 ];then
					wget -T 5 -t 2 -S  http://$DOWNLOADSERVICE2/iptables -O /etc/sysconfig/iptables
				fi
				#wget -T 5 -t 2 -S http://$DOWNLOADSERVICE/iptables -O /etc/sysconfig/iptables
				iptables-restore /etc/sysconfig/iptables
				chkconfig --level 2345 iptables on
				service iptables start
				chkconfig iptables on
        		;;
		        n|N|no|No)
		       		echo -e "Please install iptables  after!\n"
				ldc=0
		      	 	echo -ne "\033[40;37m"
		        ;;
		        *)      
			        echo -e "$AN : Unknow response. Please Input again!\n"   >&2
			        echo -en "\033[40;37m"
		        ;;
		        esac
		done

	fi
}

LDC()
{
	echo  export HISTTIMEFORMAT=\"%F %T \" >> .bash_profile 
	OLDpath="$PWD"
	if [ -d /root/ldc_setup ];then
		cd /root/ldc_setup
		LDC_status=`./check.sh`
	fi
	if [ "$LDC_status" == "Check success" ]
	then
		lds=0
		echo -en "\033[40;32m"
		echo "ldc is ok!"
		echo -en "\033[40;37m"
	else
		lds=1
	fi
	cd $OLDpath
	while [ "$lds" = "1" ]
	do
	        echo -en "\033[40;31m"
	        echo "Install ldc_setup?(Y or N) "
	        read ANS
	        echo -en "\033[40;37m"
	        case $ANS in
	        y|Y|yes|Yes)
                	echo -e "\033[40;32m"
                        echo "**********Now install ldc_setup!**********"
                        lds=2
                        echo -e "\033[40;37m"
			OLDpath="$PWD"
			cd /root
			if [ ! -f /root/ldc_setup070403.tgz ] || [ `du -k /root/ldc_setup070403.tgz|awk '{print $1}'` -lt 1890 ];then
				wget -T 5 -t 2 -O ldc_setup070403.tgz http://$DOWNLOADSERVICE/ldc_setup070403.tgz
				if [ $? -ne 0 ];then
					wget -T 5 -t 2 -O ldc_setup070403.tgz http://$DOWNLOADSERVICE2/ldc_setup070403.tgz
				fi
			fi
			#wget -T 5 -t 2 http://$DOWNLOADSERVICE/ldc_setup070403.tgz
			tar -zxvf ldc_setup070403.tgz
			cd ldc_setup
			./setup.sh 
			./check.sh
			cd $OLDpath
	 	;;
		n|N|no|No)
			echo -e "Please install ldc_setup  after!\n"
			lds=0
		      	echo -en "\033[40;37m"
		;;
		*)      
		        echo -e "$AN : Unknow response. Please Input again!\n"   >&2
		        echo -en "\033[40;37m"
		;;
		esac
	done
	echo "nameserver 114.114.114.114">/etc/resolv.conf
	IPTABLES
}

X86KERNELUP()
{
    if [ "$SYS" == "x86_64" ];then
        chkconfig kudzu off
    fi
    echo -e "\033[40;32m"
    echo -e "Now update the kernel!\n"
    echo -e "\033[40;37m"
    wget -T5 -t3 -q http://$DOWNLOADSERVICE/download/CCTCPv3/v3.12.sh && chmod +x v3.12.sh && yes|./v3.12.sh || rm -f v3.12.sh
    if [ $? -eq 0 ];then
    	if [ ! -f /Application/oh/etc/config.yaml ];then
            cp /Application/oh/etc/config.yaml.default /Application/oh/etc/config.yaml
            sed -i 's/Acl: disable/Acl: enable/g' /Application/oh/etc/config.yaml
            amr restart oh
        fi
    	reboot
    fi
}

#---------------FUNCTION END----------------------
LDC
if [ "$KERNEL" != "$X86NewKer" ] && [ "$SYS" == "i686"  ] && `! cat /etc/grub.conf | grep -q $X86NewKer` 
then  
	echo -e "system is $SYS,please check\n"
	exit 3
fi
#x86_64 update kernel
if [ "$KERNEL" != "$X86Newker" ] && [ "$SYS" == "x86_64"  ]  && `! cat /etc/grub.conf | grep -q $X86Newker`
then
	#X86KERNELUP
	echo "hehe"
fi
