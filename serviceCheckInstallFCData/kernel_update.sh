#!/bin/bash
# Name:         kernel_update.sh
# Version:      1.01
# Date:         2016-06-02
# Last Change:  2016-06-12
# Author:       liulei
# Email:        liulei@chinacache.com
# Describe:     This script use to update kernel to 3.10.0 on web project.

#DOWNLOADSERVER='61.135.208.24'
DOWNLOADSERVER='mirrors.chinacache.com'
GRUBCONF="/boot/grub/grub.conf"

Install_Confirm() {
    while true
    do
        echo "Are you confirm this server in the web project ?[y/n]"
        read RESULT
        case ${RESULT} in
            y|Y|yes|YES)
                break
            ;;
            n|N|no|NO)
                echo "Script exit"
                exit
            ;;
            *)
                echo "Input error"
                continue
            ;;
        esac
    done
}

Sysctl_Modify() {
    echo "net.ipv4.tcp_cc_initcwnd = 48
net.ipv4.tcp_cc_initrwnd = 10
net.ipv4.tcp_cc_maxif = 1
net.ipv4.tcp_cc_min_rto = 200
net.ipv4.tcp_cc_pacing = 10
net.ipv4.tcp_cc_sacked_acked = 1
net.ipv4.tcp_cc_sndbuf_factor = 3
net.ipv4.tcp_cc_synack_interval = 50
net.ipv4.tcp_cc_synack_timeout = 250 500 1000 2000 4000
net.ipv4.tcp_cc_synrtt = 1
net.ipv4.tcp_cc_tmo_fallback = 500
net.ipv4.tcp_cc_tw_timeout = 5" >> /etc/sysctl.conf
}

if [ `uname -r|grep -q '3.10.0';echo $?` -ne 0 ];
then
    #Install_Confirm
    test -f /etc/modprobe.d/igb.conf && rm -f /etc/modprobe.d/igb.conf
    wget -N http://${DOWNLOADSERVER}/BASE/kernel-3.10.0 -O kernel-3.10.0-cc.1.0.3.el6.x86_64.rpm
    rpm -ivh kernel-3.10.0-cc.1.0.3.el6.x86_64.rpm && rm -f kernel-3.10.0-cc.1.0.3.el6.x86_64.rpm
    Sysctl_Modify
    if [ `grep title ${GRUBCONF}|head -1|grep -q '3.10.0';echo $?` -eq 0 ] && [ `grep -q 'default=0' ${GRUBCONF};echo $? ` -eq 0 ];
    then
        echo -e "\033[32mkernel update success\033[0m"
        echo -e "\033[32mPlease Reboot system\033[0m"
        #for((i=5;i>=0;i--));
        #do
        #    echo -n -e "Reboot system after $i seconds\r"
        #    if [ $i -eq  0 ];then echo -e "\n";fi
        #    sleep 1
        #done
        #reboot
    else
        echo -e "\033[31mPlease check ${GRUBCONF}\033[0m"
        yes|cp /etc/grub.conf /boot/grub/grub.conf && ln -sf /boot/grub/grub.conf /etc/grub.conf
        exit
    fi
elif [ `grep -q tcp_cc /etc/sysctl.conf;echo $?` -ne 0 ];
then
    Sysctl_modify
else
    echo "Kernel has already update"
fi
