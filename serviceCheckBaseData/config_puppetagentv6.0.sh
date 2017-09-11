#!/bin/bash
. /etc/init.d/functions
if [ `nc -vzt 223.203.98.51 80 > /dev/null 2>&1;echo $?` -ne 0 ];
then
    wget -q http://mirrors.chinacache.com/BASE/yum_install.sh -O -|sh
else
    wget -q http://223.203.98.51/yum/servers/yum_install.sh -O-|sh
fi

#configure puppet
ConfigAgent () {
    sed -i '/puppetmaster.chinacache.com/d' /etc/hosts
    sed -i '/puppetfile.chinacache.com/d' /etc/hosts
    sed -i '/puppetca.chinacache.com/d' /etc/hosts
    echo "180.97.185.134 puppetmaster.chinacache.com" >> /etc/hosts
    echo "180.97.185.133 puppetfile.chinacache.com" >> /etc/hosts
    echo "180.97.185.132 puppetca.chinacache.com" >> /etc/hosts

    #gateway=`ip r | grep default | awk '{print $3}'`
    #small_gw=`echo ${gateway} | awk -F'.' '{print $1"."$2"."$3}'`
    #ip=`ip r | awk '$1~"'${small_gw}'" {print $NF}' |grep -oE '([0-9]{1,3}\.?){4}' |sort -u`
    #certname=`hostname|tr '[A-Z]' '[a-z]'`-` echo ${ip} | awk -F '.' '{print $4}'`
    certname=`hostname|tr '[A-Z]' '[a-z]'`-`facter ipaddress | awk -F '.' '{print $4}'`
    echo $certname
    
    echo "
        certname = $certname
        waitforcert = 180s
        server = puppetmaster.chinacache.com
        ca_server = puppetca.chinacache.com
        runinterval = 1800
        show_diff = true
        report = true
        listen = true
        trace = true
        splay = true
        puppetport = 8139
        autoflush = true" >> /etc/puppet/puppet.conf

    if [ $? -eq 0 ];then
        #service puppet start   
        chkconfig puppet on
        sleep 10
#        puppet agent -t
    fi
}

if [ `status puppet > /dev/null 2>&1;echo $?` -eq 0 ] || [ `rpm -q puppet > /dev/null 2>&1;echo $?` -eq 0 ];
then
    echo "Puppet already exist, Do not install it again."
    exit 1
fi

OSVersion=`cat /etc/redhat-release|awk -F \( '{print $1}'|awk '{print $NF}'|cut -d "." -f 1`
if [ `echo 567|grep -q ${OSVersion};echo $?` -ne 0 ];
then
    echo "OS version is ${OSVersion}, puppet don't be supported"
    exit 1
fi

TRY_TIMES=0
TRY_MAX=2
while [ $TRY_TIMES -lt $TRY_MAX ];
do
   if [ $OSVersion -ne 7 ];then 
     yum -y install puppet-3.4.3
   else
     yum -y install puppet-3.7.0
   fi
   if [ $? -eq 0 ];
    then
        cp /etc/puppet/puppet.conf /etc/puppet/puppet.conf.bak
        ConfigAgent
        break;
    else
        (( TRY_TIMES++ ))
        sleep 30
    fi
  
done

exit 0
