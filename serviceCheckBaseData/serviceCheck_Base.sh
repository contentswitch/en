#!/bin/sh
#---------------------------------------------------------------------------|
#  @Program   : serviceCheck_Base                                           |  
#  @Version   : 1.0                                                         |
#  @Company   : china cache                                                 |
#  @Dep.      : inm                                                         |
#  @Writer    : bin.zheng  <bin.zheng@chinacache.com>                       |
#  @Date      : 2014-12-15                                                  |
#  @Alter     : 2016-01-27                                                  |
#---------------------------------------------------------------------------|
SYS=`arch`
DOWNLOADSERVICE='mirrors.chinacache.com'
DOWNLOADSERVICE1='223.203.98.51'
shift
######update yum.repo######
os_version=`cat /etc/redhat-release|awk -F . '{print $1}'|awk '{print $NF}'`
#wget -q http://${DOWNLOADSERVICE}/yum/servers/yum_install.sh -O -|sh
yum install -y redhat-lsb ntp gd gd-devel
######################
df  | awk '{ print $6 "\t"$2 }' | sed '1d'  >DF.txt
cat DF.txt  | awk '{print $1}'  > df.partition
sed  -i -n '/^\//p'  df.partition
sed -i 's/^\(id:\)\(5\)\(:.*\)$/\13\3/' /etc/inittab
PART_number=`cat df.partition | wc -l`

#---------------FUNCTION DEFINITION---------------
trap 'FREEFILE' 2
greenEcho()
{
    echo -en "\033[31;32m"
    echo "$1"
    echo -en "\033[31;37m"
}

redEcho()
{
    echo -en "\033[31;31m"
    echo -e  "$1"
    echo -en "\033[31;37m"
}

flickerRed ()
{
    tput blink 
    tput bold
    echo -en "\033[31;31m"
    echo "$1"
    tput sgr0
}

FREEFILE() 
{
    rm -f DF.txt
    rm -f df.partition
    rm -f parti.sh
    rm -f parti.result
    rm -f squidstatus.txt
    rm -f AMR.rpm 
    rm -f iptables-stop.sh
    rm -rf /root/config_puppetagentv6.0.sh
    echo -en "\033[40;37m"
}

NEW_SNFUN()
{
    for i in ISP CITY;
    do
        if [ -e /root/$i.* ];
        then
            rm $i.* -rf
        fi
    done
    wget -N http://${DOWNLOADSERVICE1}/BASE/ISP.txt
    wget -N http://${DOWNLOADSERVICE1}/BASE/CITY.txt

    ISP=`hostname |awk -F- '{print $1}'`
    CITY=`hostname |awk -F- '{print $2}'`
    NODE=`hostname |awk -F- '{print $3}'`
    SERVICE=`hostname |awk -F- '{print $4}'`

    if [ "$ISP" == "" -o "$CITY" == "" -o "$NODE" == "" -o "$SERVICE" == "" ]
    then 
        echo -e "\033[40;31m"
        echo -e  "`hostname`: hostname not_standard!"
        SN_result=0
    fi

    I=0
    while read ISP_host ISPCODE
    do 
        if [ "$ISP_host" == "$ISP" ]
        then
            I=1
            break;
        fi
    done < ISP.txt

    if [ "$I" == "0" ];
    then
        echo "Unknow ISP: $ISP"
        FREEFILE
        exit 1
    fi

    C=0
    while read CITY_host Postcode
    do
        if [ "$CITY_host" == "$CITY" ]
        then
            C=1
            break;
        fi
    done < CITY.txt

    if [ "$C" == "0" ];
    then
        echo "Unknow CITY: $CITY"
        FREEFILE
        exit 1
    fi

    SN="$ISPCODE$Postcode$NODE$SERVICE"
    if [ "$SN_result" == "0" ]
    then
        echo -e "\033[40;31m"
        echo "/sn.txt not write!"
    else
        echo "$SN" > /sn.txt
    fi
    echo -e "\033[40;37m"
    rm -rf ISP.txt
    rm -rf CITY.txt
}

CLOCKSET()
{
    echo -en "\033[40;32m"
    echo "Now set the systime and zone"
    /bin/cp -f /usr/share/zoneinfo/Asia/Shanghai  /etc/localtime
    echo -en "\033[40;37m"
    ntpdate 180.97.185.40  || ntpdate 130.149.17.21 
    if [ "`ls /dev/ | grep xvd | wc -l`" -gt "1" ]
    then
        echo "exit" > /dev/null 2>&1
    else
        hwclock > /dev/null 2>&1
        if [ "$?" == "1" ]
        then  
            echo "repairing hwclock"
            rm -rf /sbin/hwclock
            wget http://${DOWNLOADSERVICE}/BASE/hwclock -O /sbin/hwclock
            chmod 755 /sbin/hwclock
            sleep 1
            ntpdate 180.97.185.40  || ntpdate 130.149.17.21
            sleep 1
            hwclock --systohc
            hwclock --systohc --utc
            if [ `rpm -qa |grep -q ccAMRd;echo $?` -eq 0 ];
            then
                kill -s 9 `pgrep ccAMRd`;sleep 3;amr restart dm;amr restart mftt;amr restart ta;amr restart oh;sleep 2;ccamr list
            fi
        else
            hwclock --systohc
            hwclock --systohc --utc
        fi
    fi
    wget -q -N http://${DOWNLOADSERVICE1}/yum/servers/ntp_install.sh -O -|sh
    echo -en "\033[40;37m"
}

HOSTNAMEFUN()
{
    Sethostname()
    {
        echo -e "\033[40;31m"
        echo -e "HOSTNAME is wrong!\nPlease input hostname:"
        read HOSTNAME
        J=1
        while [ "$J" == "1" ]
        do
            echo -en "\033[40;32m"
            echo -e "You input hostname is :$HOSTNAME\nAre you sure?Yes or No"
            read SU
            case $SU in
                y|yes|YES|Y|sure)
                    echo "HOSTNAME is $HOSTNAME"
                    J=0
                ;;
                n|N|no|NO)
                    Sethostname
                    FREEFILE
                ;;
                *)
                    echo -e "\033[40;31m"
                    echo -e "$SU : Unknow response. Please Input again!\n"          >&2
                    echo -e "\033[40;37m"
                    J=1
                ;;
            esac
        done
        hostname $HOSTNAME
        if [ -f /etc/sysconfig/network ];
        then
            sed -i -r 's/(^HOSTNAME=)[^$]*/\1'"$HOSTNAME"'/' /etc/sysconfig/network
        else
            echo -e "NETWORKING=yes\nHOSTNAME=$HOSTNAME" > /etc/sysconfig/network
        fi
        echo -e "\033[40;37m"
    }

    HOSTNAME1=`hostname`
    if [[ "$HOSTNAME1" =~ "localhost" ]];
    then
        Sethostname
    fi
}

CHECKSELINUX()
{
    STATUS=`getenforce`
    if [ "$STATUS" == "Disabled" ];
    then
        grep -q '^SELINUX=disabled' /etc/selinux/config
        if [ $? -eq 0 ];
        then
            echo -e "\033[40;32m The SELINUX is disable now! \033[40;37m"	
        else
            sed -i -r 's/(^SELINUX=)[^$]*/\1disabled/g' /etc/selinux/config
            echo -e "\033[40;32m The SELINUX is disable now! \033[40;37m"
        fi
    else
        setenforce 0
        sed -i -r 's/(^SELINUX=)[^$]*/\1disabled/g' /etc/selinux/config
        echo -e "\033[40;32m Disable the SElinux successfull! \033[40;37m"
    fi
}

checkgcc()
{       
    #re=`rpm -qa|grep -E "^gcc-[0-9]"`
    #if [ "$re" == "" ];
    #then
        echo -e "\033[40;31m gcc is not install!  Install it now ! please wait 30 min........... \033[40;37m"
        sleep 5
        wget -q -O /root/repairgcc.sh http://${DOWNLOADSERVICE}/BASE/repairgcc.sh
        sh /root/repairgcc.sh
        rm -rf /root/repairgcc.sh
        echo -e "\033[40;32m Install is ok ! \033[40;37m" 
        sleep 5
    #fi      
}

BASE()
{
    ######change hostname######
    HOSTNAMEFUN

    #######update sn number######
    NEW_SNFUN

    ######fix hosts######
    if [ `sed 's/#.*//g;/^$/d' /etc/hosts|grep -v "localhost6"|wc -l` -eq 1 ];
    then 
        if [ `grep -v "localhost6" /etc/hosts|awk '{if(($NF=="localhost")&&($1=="127.0.0.1"))print "ok"}'`x == okx ];
        then 
            continue
        else
            echo "127.0.0.1  localhost.localdomain localhost" >> /etc/hosts
        fi
    else 
        echo "127.0.0.1  localhost.localdomain localhost" >> /etc/hosts
    fi

    ######hosts.allow update#####
    if [ -f /etc/hosts.allow ] &&  [ `cat /etc/hosts.allow|wc -l ` -gt 500 ]
    then
        echo -e "\033[40;32m"
        echo "hosts.allow is ok!"
        echo -e "\033[40;37m"
    else
        echo -e "Now Install hosts.allow."
        rm -f /etc/hosts.allow
        wget -N -O /etc/hosts.allow http://${DOWNLOADSERVICE}/BASE/hosts.allow
    fi
	
    ######update bash and openssl install mkfs.ext4
    yum -y install openssl098e.x86_64 openssl bash rsync openssh-server e4fsprogs salt-minion-sonar
    sleep 3
    if [ ${os_version} -eq 5 ];
    then
        wget -q -O /tmp/update_Openssl.sh "http://${DOWNLOADSERVICE}/BASE/update_OpenSSL.sh" && sh /tmp/update_Openssl.sh
    elif [ ${os_version} -eq 6 ];
    then
        wget -q -O /tmp/upgrade_Openssl.sh "http://${DOWNLOADSERVICE}/BASE/upgrade_Openssl.sh" && sh /tmp/upgrade_Openssl.sh
    else
        echo "os version error"
    fi
    sleep 2

    ######update time######
    CLOCKSET

    ######install AMR######
    checkgcc
    wget http://${DOWNLOADSERVICE}/BASE/amr.sh -O- |sh
    #wget -O AMR.rpm http://$DOWNLOADSERVICE/BASE/AMR.rpm
    #rpm -ivh AMR.rpm
    ######update cop unit######
    #copUpdater --update 61.135.208.24 --download 61.135.208.24
    if [ ! -f /Application/oh/etc/config.yaml ];
    then
        cp /Application/oh/etc/config.yaml.default /Application/oh/etc/config.yaml
        sed -i 's/Acl: disable/Acl: enable/g' /Application/oh/etc/config.yaml
        amr restart oh
    fi

    ######stop iptables######
    /sbin/service iptables stop;/sbin/chkconfig --level 2345 iptables off;sed -i '/self/d' /var/spool/cron/root
    wget -q -O iptables-stop.sh http://${DOWNLOADSERVICE}/BASE/iptables-stop.sh
    sh iptables-stop.sh
    sleep 1
    if [ -f /etc/init.d/iptables ];
    then
        mv /etc/init.d/iptables /etc/init.d/acl_iptab
    fi

    ############## Check SELinux ####################
    echo -e "\033[40;32m Now check selinux............ \033[40;37m"
    CHECKSELINUX

    ######Modify the kernel boot sequence######
    case $os_version in
        5)
            uname -r|grep -q xen
            if [ $? -eq 0 ];
            then
                grub_num=`cat /etc/grub.conf |grep title|awk '/CentOS-base/{print NR-1}'`
                sed -i s/^default.*/default=$grub_num/g /boot/grub/grub.conf	
            fi
        ;;
        6)
            uname -r|grep -q xen
            if [ $? -eq 0 ];
            then
                grub_num=`cat /boot/grub/grub.conf |grep title|awk '!/xen/{print NR-1}'|tail -n 1`
                sed -i s/^default.*/default=$grub_num/g /boot/grub/grub.conf
            fi
        ;;
    esac

    ###########Check Service######################
    for stop_service in anacron atd iscsi iscsid libvirt-guests libvirtd microcode_ctl
    do
        /etc/init.d/$stop_service stop >/dev/null 2>&1
        chkconfig $stop_service off >/dev/null 2>&1
    done

    ######The removal of SSH DNS analysis######
    sed -i "s/GSSAPIAuthentication yes/GSSAPIAuthentication no/" /etc/ssh/sshd_config
    sed -i "s/#UseDNS yes/UseDNS no/" /etc/ssh/sshd_config
    service sshd restart
    mv -f /etc/sysconfig/i18n /etc/sysconfig/i18n.bak
    echo -e "LANG=en_US.UTF-8\nSYSFONT=latarcyrheb-sun16">/etc/sysconfig/i18n
    found=`grep -c '344800|348160' /etc/profile`
    if ! [ $found -gt "0" ]
    then
        echo "ulimit -HSn 344800"  >> /etc/profile
    fi
    found=`grep -c HISTTIMEFORMAT /etc/profile`
    if ! [ $found -gt "0" ]
    then
        echo "export HISTSIZE=2000" >> /etc/profile
        echo "export HISTTIMEFORMAT='%F %T:'" >> /etc/profile
    fi
}

#---------------FUNCTION DEFINITION END-----------
SERVICE=`hostname |awk -F- '{print $4}' | cut -c 1-2`

echo -e "\n**********System Information**********\n"

#display Boot error message
dmesg | grep error > boot_error
if [ -s boot_error ]
then
    echo -e "\033[40;31m"
    echo -e  "\n*********Message when booting shows:"
    sort -r boot_error | uniq 
    echo -e "\033[40;37m"
else
    echo -e "\033[40;32m"
    echo -e "\nBoot information is OK!"
    echo -e "\033[40;37m"
fi
rm -f boot_error

#to judge whether the network card is 1000M or not?
echo -e "\033[40;32m"
ethtool eth0 | awk '{if ($1=="Speed:" && $2=="1000Mb/s") print "\neth0 is OK!" }'
ethtool eth1 | awk '{if ($1=="Speed:" && $2=="1000Mb/s") print "eth1 is OK!\n" }'
echo -e "\033[40;31m"
ethtool eth0 | awk '{if ($1=="Speed:" && $2!="1000Mb/s") print "\neth0 is not 1000M!" }'
ethtool eth1 | awk '{if ($1=="Speed:" && $2!="1000Mb/s") print "eth1 is not 1000M!\n" }'
echo -e "\033[40;37m"

if [[ $os_version -eq 6 || -z $os_version ]]
then
   rclocal='/etc/rc.d/rc.local'
else
   rclocal='/etc/rc.local'
fi
sed -i '/ethtoo/d' $rclocal

for i in `ifconfig -a |grep -E 'eth|bond'  |awk '{print $1}'`
do
for r in RX TX
do
nr=`echo $r | tr '[A-Z]' '[a-z]'`
ethtool -g $i | grep "$r:"  | awk '{print $2}' | xargs echo | while read a1 a2
do
     if [ "`ethtool $i |grep -i Speed `" != "" ]
      then  
       if [ $a1 -eq $a2 ]
        then
                echo -e "\033[33m $i max = curr , size is $a2 \033[0m, \033[31mDo not need to set $i ${r}_ring \033[0m"
        else
                echo -e "\033[33m $i max = $a1 \033[0m, \033[34mcurr = $a2\033[0m , \033[32mnow set $i $r\033[0m"
                ethtool -G $i $nr $a1
        fi
        grep -q "ethtool -G $i $nr $a1" $rclocal || echo "ethtool -G $i $nr $a1 >/dev/null 2>&1">>$rclocal
     fi
done
done
done



#to judge whether the disk(partition) is read-only or not?
J=0
for par in `cat df.partition`
do
    echo $par | awk '{print "cd " $1 "\n touch 1 \n rm -f 1"}' > parti.sh
    chmod u+x parti.sh
    ./parti.sh >/dev/null 2>parti.result
    if [ -s parti.result ]
    then
        echo -e "\033[40;31m"
        echo "The partion $par is only-read"
    else
        J=`expr $J + 1`
    fi
done
if [ "$J" = "$PART_number" ]
then
    greenEcho  "No read-only disk.The Disk is OK!"
else
    redEcho	"Disk read only, please check"
    FREEFILE
    exit 1
fi

#system version
if lsb_release -d |grep -q 5.8 && [ $SYS  == "x86_64" ]
then
    echo -e "The system version is : \t `lsb_release -d | awk '{print "x86_64  " $2" " $4}'` "
elif [ $SYS  == "i686" ] && lsb_release -a | grep -q "Linux AS release 4 (Nahant Update 5)" 
then
    echo -e "The system version is : \t i686 \t `lsb_release -d|cut -c '14-' `"
else
    flickerRed "The system version is error."
    echo -e "The system version is : \t $SYS \t `lsb_release -d `"
    redEcho "Press c to continue software install(default to exit)"
    read AN
    if [[ $AN =~ [cC] ]];
    then
        echo "continue software install"
    else
        redEcho "system version is error.\nPlease install system after"
        EXIT 1
    fi	
fi

BASE

############### Check Gateway ##########################
gwip=`route -n|awk '/^0.0.0.0/{print $2}'`
#########################################	
greenEcho "Now check network. Please wait a moment."
LossRate=`ping -f -c 50 -q $gwip | awk -F '[ |%]' '/%/{print $6}'`
	
if [ "$LossRate" != "0"  ]
then
    flickerRed "ping $gwip   $LossRate% packet loss! Please check it after!"
    sleep 5
else
    echo  "No packet loss."
fi

############## Check IPMI ####################
SERVICE=`hostname |awk -F- '{print $4}' | cut -c 1-2`
echo ${SERVICE}
sn_number=`dmidecode -s system-serial-number|wc -L`
sn=`dmidecode -s system-serial-number`
if [ $sn_number -ne 0 ] && [ $sn_number -le 30 ] && [ $sn != "None" ];
then
    echo -e "\033[40;32m Now check IPMI............ \033[40;37m"
    if ! test `rpm -qa OpenIPMI` || ! test `rpm -qa OpenIPMI-tools` ;
    then
       yum -y install OpenIPMI OpenIPMI-tools
        #wget -O /root/ipmi_set.sh http://${DOWNLOADSERVICE}/BASE/ipmi_set.sh
        #sh /root/ipmi_set.sh
    #else
     #   service ipmi restart
      #  if test "`ipmitool -I open  lan print|egrep "IP Address.*:.*172.*"`";
      #  then
            ipmitool -I open  lan print|egrep "IP Address|Subnet|MAC Address|Default Gateway IP"
            echo -e "\033[40;32m IPMI is OK! \033[40;37m"
      #  else
      #      wget -O /root/ipmi_set.sh http://${DOWNLOADSERVICE}/BASE/ipmi_set.sh
      #      sh /root/ipmi_set.sh
#        fi
    fi
    wget -O /root/change_ipmi_passwd.sh http://${DOWNLOADSERVICE}/BASE/change_ipmi_passwd.sh
    sh /root/change_ipmi_passwd.sh
    service ipmi stop
    rm -f /root/change_ipmi_passwd.sh
fi

# trunk and gw file
has_trunk=`ifconfig | grep -E '^(eth|bond)[0-5]\.+'`
[ -n "has_trunk" ] && wget http://223.203.98.51/calc_gw.sh -qO- |sh

wget -O /root/config_puppetagentv6.0.sh http://${DOWNLOADSERVICE}/BASE/config_puppetagentv6.0.sh
if [ $? -ne 0 ];
then
    echo -e "download fail config_puppetagentv6.0.sh"
fi
sh /root/config_puppetagentv6.0.sh
sleep 5
echo "nameserver 127.0.0.1" > /etc/resolv.conf
FREEFILE
################################ AMR ###########################################################
#wget http://${DOWNLOADSERVICE}/BASE/amr.sh -O- |sh 
################################ sonar #############################################################
wget -q http://${DOWNLOADSERVICE}/BASE/update_imp_sonar.sh -O - | sh
