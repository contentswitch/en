#! /bin/bash

service iptables stop
service ip6tables stop
chkconfig iptables off
chkconfig ip6tables off

for((i=0;i<10;i++))
do
        for M in `lsmod|awk '/conn/||/xt_/||/ipt_/||/ip6t_/||/nf_/||/_tables/||/ip_vs/{print $1}'`
        do
                rmmod $M &>/dev/null
        done
done

if [ "`lsmod |awk '/conn/'`" == "" ]
then
        echo "iptables has been stopped completely."
else
        echo "WARNING: For some reasons, iptables can NOT be stopped, the device must be rebooted!"
fi
