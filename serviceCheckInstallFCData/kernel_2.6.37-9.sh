#!/bin/bash
# by peng.xu
# 2017-04-27
# update kernel to 2.6.37-9
# wiki: http://wiki.dev.chinacache.com/pages/viewpage.action?pageId=15074781
DOWNLOADSERVICE1='mirrors.chinacache.com'
DOWNLOADSERVICE='223.203.98.51'

release=`cat /etc/issue |head -n 1`
cnf_count=`ls /boot | grep -c 2.6.37-9`
if [ "$release" == "CentOS release 5.8 (Final)" ]
then
    #wget -qN http://hpcc:CChpcc@118.126.12.141/kernel/cctcp/el5/2.6.37-9/cctcp-utils-2.6.37-9.rpm
    #wget -qN http://hpcc:CChpcc@118.126.12.141/kernel/cctcp/el5/2.6.37-9/kernel-2.6.37-9.el5.x86_64.rpm
    
    wget -qN http://${DOWNLOADSERVICE1}/BASE/FC/kernel/cctcp/el5/2.6.37-9/cctcp-utils-2.6.37-9.rpm
    wget -qN http://${DOWNLOADSERVICE1}/BASE/FC/kernel/cctcp/el5/2.6.37-9/kernel-2.6.37-9.el5.x86_64.rpm

    rpm -ivh kernel-2.6.37-9.el5.x86_64.rpm
    if [ "`rpm -qa |grep cctcp`" == "" ] ;then rpm -ivh cctcp-utils-2.6.37-9.rpm; else rpm -Uvh cctcp-utils-2.6.37-9.rpm ; fi
    echo -e "\033[32mkernel 2.6.37-9 update success\033[0m"
    #if [ ${cnf_count} -ge 5 ]; then echo -e "\033[32mkernel 2.6.37-9 update success\033[0m"; else echo -e "\033[31mkernel 2.6.37-9 update failed\033[0m"; exit; fi
elif [ "$release" == "CentOS release 6.5 (Final)" ]
then
    #wget -qN http://hpcc:CChpcc@118.126.12.141/kernel/cctcp/el6/2.6.37-9/cctcp-utils-2.6.37-9.rpm
    #wget -qN http://hpcc:CChpcc@118.126.12.141/kernel/cctcp/el6/2.6.37-9/kernel-2.6.37-9.el6.x86_64.rpm
    #wget -qN http://hpcc:CChpcc@118.126.12.141/kernel/cctcp/el6/2.6.37-9/kernel-firmware-2.6.37-9.el6.x86_64.rpm
    
     wget -qN http://${DOWNLOADSERVICE1}/BASE/FC/kernel/cctcp/el6/2.6.37-9/cctcp-utils-2.6.37-9.rpm
     wget -qN http://${DOWNLOADSERVICE1}/BASE/FC/kernel/cctcp/el6/2.6.37-9/kernel-2.6.37-9.el6.x86_64.rpm
     wget -qN http://${DOWNLOADSERVICE1}/BASE/FC/kernel/cctcp/el6/2.6.37-9/kernel-firmware-2.6.37-9.el6.x86_64.rpm
   
    rpm -ivh kernel-2.6.37-9.el6.x86_64.rpm kernel-firmware-2.6.37-9.el6.x86_64.rpm
    if [ "`rpm -qa |grep kernel-firmware`" == "" ]; then rpm -ivh kernel-firmware-2.6.37-9.el6.x86_64.rpm ; else rpm -Uvh kernel-firmware-2.6.37-9.el6.x86_64.rpm;fi
    if [ "`rpm -qa |grep cctcp`" == "" ] ;then rpm -ivh cctcp-utils-2.6.37-9.rpm; else rpm -Uvh cctcp-utils-2.6.37-9.rpm ; fi
    echo -e "\033[32mkernel 2.6.37-9 update success\033[0m"
    #rpm -Uvh cctcp-utils-2.6.37-9.rpm 
    #if [ $? -eq 0 ]; then  echo -e "\033[31mkernel 2.6.37-9 update failed\033[0m"; exit;else echo -e "\033[32mkernel 2.6.37-9 update success\033[0m"; fi
    #if [ ${cnf_count} -ge 6 ]; then echo -e "\033[32mkernel 2.6.37-9 update success\033[0m"; else echo -e "\033[31mkernel 2.6.37-9 update failed\033[0m"; exit; fi
fi

check_grub(){
    etc_md5=`md5sum /etc/grub.conf | awk '{print $1}'`
    boot_md5=`md5sum /boot/grub/grub.conf | awk '{print $1}'`
    if [ "$etc_md5" != "$boot_md5" ]
    then
        cp /boot/grub/grub.conf /boot/grub/grub.conf.`date +%s`
        cat /etc/grub.conf > /boot/grub/grub.conf
        ln -sf /boot/grub/grub.conf /etc/grub.conf
    fi
}

check_grub

has_ixgbe=`lspci -nn |grep -c 10-Gigabit`
if [ ${has_ixgbe} -eq 0 ];then
echo -e "\033[32mOver,Restart effect!\033[0m"
else
echo -e "\033[33mwould you want to open the multiqueue with ixgbe netcard?\033[0m"
other(){
select i in 'yes' 'no'
do
    case $i in
        1|y|yes)
	    wget http://223.203.98.51/set_ixgbe_multiqueue.sh -qO - |sh
	;;
	2|n|no|*)
	    echo "bye"
	;;
    esac
    break
done
}

other
fi
