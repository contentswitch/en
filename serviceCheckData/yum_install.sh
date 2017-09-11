#!/bin/bash
# Name:         yum_install.sh
# Version:      1.00
# Date:         2016-03-01
# Last Change:  2016-10-13
# Author:       liulei


# Email:        liulei@chinacache.com
# Describe:     Update all servers yum repo. This script can Repeated execution

OPSLIST=(182.247.233.3 171.107.85.139 117.21.218.35 113.5.250.229 119.188.140.80 163.177.134.75 60.12.50.207 60.12.50.206 218.75.142.4 218.75.142.3 218.59.211.3 27.22.55.5 180.97.213.100 120.241.147.133 58.215.106.141 113.96.136.100 58.220.22.34 124.67.23.35 124.67.23.36 175.6.18.100 116.211.124.100 218.29.229.233 101.26.39.36 101.26.39.35 116.211.84.5 117.169.22.100 42.232.89.5 58.216.30.165 124.14.4.195 103.220.58.100 124.14.4.196 183.2.224.100 221.204.171.67 118.118.215.100 218.60.47.4 112.90.90.100 59.58.43.46 117.26.145.5 42.81.22.3 42.81.22.4 119.84.70.5 218.59.211.4 222.84.190.66 222.84.190.67 58.20.131.132 117.34.48.5 58.20.131.131 180.97.236.14 180.97.236.13 58.220.22.61 175.6.8.139 58.222.27.100 115.231.14.100 119.188.141.13 58.215.109.35 123.138.188.100 116.211.123.141 111.202.73.190 111.202.73.191 60.165.56.11 115.231.29.5 58.216.29.77 218.60.47.3 222.174.239.131 122.228.116.137 222.174.239.132 123.130.123.34 171.107.87.197 42.202.151.100 122.228.116.133 113.215.17.4 42.81.101.3 113.215.17.7 58.221.69.205 218.29.229.238 122.228.86.67 180.97.254.36 180.97.254.35 121.30.193.48 221.235.254.45 221.235.254.44 61.240.134.136 61.240.134.139 182.247.233.2 58.20.206.100 139.209.89.100 112.84.133.221 120.221.134.100 117.149.196.100 171.107.190.72 180.97.184.44 122.228.87.13 171.107.190.73 218.60.107.100 14.215.89.38)

Check_IP() {
    test -f /scripts/time.log && rm -f /scripts/time.log
    SEND_THREAD_NUM=50
    tmp_fifofile="/tmp/$$.fifo"
    mkfifo "$tmp_fifofile"
    exec 6<>"$tmp_fifofile"

    for ((i=0;i<$SEND_THREAD_NUM;i++))
    do
        echo
    done >&6

    for ((i=0;i<${#OPSLIST[@]};i++))
    do
        read -u6
        {
            echo "`ping -f -c 5 ${OPSLIST[$i]}|awk -F '[/|.]' '/rtt/{print $6}'` ${OPSLIST[$i]}" >> /scripts/time.log
            echo >&6
        } &
    done

    wait

    exec 6>&-

    rm -f /tmp/$$.fifo

    #grep ^[0-9] /scripts/time.log|sort -n|head -1|awk '{print $NF}'
    for ip in `grep ^[0-9] /scripts/time.log|sort -n|awk '{print $NF}'`
    do
        if [ `wget -T 5 -t 2 -qS http://${ip}/BASE/1 --spider >/dev/null 2>&1;echo $?` -eq 0 ];
        then
            echo ${ip}
            break
        fi
    done
}

# check hostname
HOST=`hostname|awk -F - '{print $1}'`

# check server is ops server or not
for WIP in `/sbin/ip a|grep "inet [0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+"|grep -v 127.0.0.1|awk '{print $2}'|cut -d "/" -f 1`
do
    if [ `echo ${OPSLIST[@]}|grep -q -w ${WIP};echo $?` -eq 0 ];
    then
        echo "this's ops server"
        exit 0
    fi
done

# =================================yum install start============================================================
test -f /usr/bin/dig || yum -y install bind-utils
test -f /usr/bin/wget || yum -y install wget

echo -e "\033[32m Begin to install yum \033[0m"

#RELEASE=`cat /etc/redhat-release|awk -F \( '{print $1}'|awk '{print $NF}'|cut -d "." -f 1`
RELEASE=`cat /etc/redhat-release|grep -oE "[0-9]"|head -1`
if [ -f /etc/yum.repos.d/IMP-${RELEASE}.repo ] && [ -f /etc/yum.repos.d/cc-${RELEASE}.repo ] && [ `grep -q mirrors.chinacache.com /etc/hosts;echo $?` -eq 0 ];
then
    exit 0
fi
test -d /etc/yum.repos.d/bak || mkdir /etc/yum.repos.d/bak
yes | mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/bak/
test -f /etc/pki/rpm-gpg/RPM-GPG-KEY-puppetlabs && rm -f /etc/pki/rpm-gpg/RPM-GPG-KEY-puppetlabs

echo "# CentOS-Base-${RELEASE}.repo

[base]
name=CentOS-${RELEASE} - Base
#mirrorlist=http://mirrorlist.centos.org/?release=${RELEASE}&arch=\$basearch&repo=os
baseurl=http://mirrors.chinacache.com/centos/${RELEASE}/os/\$basearch/
gpgcheck=0
#gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-${RELEASE}
gpgkey=http://mirrors.chinacache.com/RPM-GPG-KEY-CentOS-${RELEASE}

#released updates 
[updates]
name=CentOS-${RELEASE} - Updates
#mirrorlist=http://mirrorlist.centos.org/?release=${RELEASE}&arch=\$basearch&repo=updates
baseurl=http://mirrors.chinacache.com/centos/${RELEASE}/updates/\$basearch/
gpgcheck=0
#gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-${RELEASE}
gpgkey=http://mirrors.chinacache.com/RPM-GPG-KEY-CentOS-${RELEASE}

#additional packages that may be useful
[extras]
name=CentOS-${RELEASE} - Extras
#mirrorlist=http://mirrorlist.centos.org/?release=${RELEASE}&arch=\$basearch&repo=extras
baseurl=http://mirrors.chinacache.com/centos/${RELEASE}/extras/\$basearch/
gpgcheck=0
#gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-${RELEASE}
gpgkey=http://mirrors.chinacache.com/RPM-GPG-KEY-CentOS-${RELEASE}

#additional packages that extend functionality of existing packages
[centosplus]
name=CentOS-${RELEASE} - Plus
#mirrorlist=http://mirrorlist.centos.org/?release=${RELEASE}&arch=\$basearch&repo=centosplus
baseurl=http://mirrors.chinacache.com/centos/${RELEASE}/centosplus/\$basearch/
gpgcheck=0
enabled=1
#gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-${RELEASE}
gpgkey=http://mirrors.chinacache.com/RPM-GPG-KEY-CentOS-${RELEASE}
" >> /etc/yum.repos.d/CentOS-Base-${RELEASE}.repo

if [ ${RELEASE} -lt 7 ];
then
    echo "#contrib - packages by Centos Users
[contrib]
name=CentOS-${RELEASE} - Contrib
#mirrorlist=http://mirrorlist.centos.org/?release=${RELEASE}&arch=\$basearch&repo=contrib
baseurl=http://mirrors.chinacache.com/centos/${RELEASE}/contrib/\$basearch/
gpgcheck=0
enabled=1
#gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-${RELEASE}
gpgkey=http://mirrors.chinacache.com/RPM-GPG-KEY-CentOS-${RELEASE}
" >> /etc/yum.repos.d/CentOS-Base-${RELEASE}.repo
fi

if [ ${RELEASE} -eq 6 ];
then
    echo "#centos 6.x xen package
[centos-virt-xen]
name=CentOS-${RELEASE} - xen
baseurl=http://mirrors.chinacache.com/centos/${RELEASE}/virt/\$basearch/xen-46
gpgcheck=0
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-Virtualization
" >> /etc/yum.repos.d/CentOS-Base-${RELEASE}.repo
fi

echo "# epel-${RELEASE}.repo

[epel]
name=Extra Packages for Enterprise Linux ${RELEASE} - \$basearch
#mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=epel-6&arch=\$basearch
baseurl=http://mirrors.chinacache.com/epel/${RELEASE}/\$basearch
failovermethod=priority
enabled=1
gpgcheck=1
#gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-${RELEASE}
gpgkey=http://mirrors.chinacache.com/epel/RPM-GPG-KEY-EPEL-${RELEASE}

[epel-debuginfo]
name=Extra Packages for Enterprise Linux ${RELEASE} - \$basearch - Debug
#mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=epel-debug-6&arch=\$basearch
baseurl=http://mirrors.chinacache.com/epel/${RELEASE}/\$basearch/debug
failovermethod=priority
enabled=1
#gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-${RELEASE}
gpgkey=http://mirrors.chinacache.com/epel/RPM-GPG-KEY-EPEL-${RELEASE}
gpgcheck=1

[epel-source]
name=Extra Packages for Enterprise Linux ${RELEASE} - \$basearch - Source
#mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=epel-source-6&arch=\$basearch
baseurl=http://mirrors.chinacache.com/epel/${RELEASE}/SRPMS
failovermethod=priority
enabled=1
#gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-${RELEASE}
gpgkey=http://mirrors.chinacache.com/epel/RPM-GPG-KEY-EPEL-${RELEASE}
gpgcheck=1" >> /etc/yum.repos.d/epel-${RELEASE}.repo

echo "# epel-testing-${RELEASE}.repo

[epel-testing]
name=Extra Packages for Enterprise Linux ${RELEASE} - Testing - \$basearch
#mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=testing-epel${RELEASE}&arch=\$basearch
baseurl=http://mirrors.chinacache.com/epel/testing/${RELEASE}/\$basearch
failovermethod=priority
enabled=1
#gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-${RELEASE}
gpgkey=http://mirrors.chinacache.com/epel/RPM-GPG-KEY-EPEL-${RELEASE}
gpgcheck=1

[epel-testing-debuginfo]
name=Extra Packages for Enterprise Linux ${RELEASE} - Testing - \$basearch - Debug
#mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=testing-debug-epel${RELEASE}&arch=\$basearch
baseurl=http://mirrors.chinacache.com/epel/testing/${RELEASE}/\$basearch/debug
failovermethod=priority
enabled=1
#gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-${RELEASE}
gpgkey=http://mirrors.chinacache.com/epel/RPM-GPG-KEY-EPEL-${RELEASE}
gpgcheck=1

[epel-testing-source]
name=Extra Packages for Enterprise Linux ${RELEASE} - Testing - \$basearch - Source
#mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=testing-source-epel${RELEASE}&arch=\$basearch
baseurl=http://mirrors.chinacache.com/epel/testing/${RELEASE}/SRPMS
failovermethod=priority
enabled=1
#gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-${RELEASE}
gpgkey=http://mirrors.chinacache.com/epel/RPM-GPG-KEY-EPEL-${RELEASE}
gpgcheck=1" >> /etc/yum.repos.d/epel-testing-${RELEASE}.repo

echo "# IMP-${RELEASE}.repo

[IMP]
name=IMP
keepcache=0
baseurl=http://mirrors.chinacache.com/imp/CENTOS-${RELEASE}/
enabled=1
gpgcheck=0" >> /etc/yum.repos.d/IMP-${RELEASE}.repo

echo "# puppetlabs-${RELEASE}.repo

[puppetlabs-products]
name=Puppet Labs Products El ${RELEASE} - \$basearch
baseurl=http://mirrors.chinacache.com/puppetlabs/el/${RELEASE}/products/\$basearch
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-puppetlabs
enabled=1
gpgcheck=1

[puppetlabs-deps]
name=Puppet Labs Dependencies El ${RELEASE} - \$basearch
baseurl=http://mirrors.chinacache.com/puppetlabs/el/${RELEASE}/dependencies/\$basearch
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-puppetlabs
enabled=1
gpgcheck=1

[puppetlabs-devel]
name=Puppet Labs Devel El ${RELEASE} - \$basearch
baseurl=http://mirrors.chinacache.com/puppetlabs/el/${RELEASE}/devel/\$basearch
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-puppetlabs
enabled=0
gpgcheck=1

[puppetlabs-products-source]
name=Puppet Labs Products El ${RELEASE} - \$basearch - Source
baseurl=http://mirrors.chinacache.com/puppetlabs/el/${RELEASE}/products/SRPMS
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-puppetlabs
failovermethod=priority
enabled=0
gpgcheck=1

[puppetlabs-deps-source]
name=Puppet Labs Source Dependencies El ${RELEASE} - \$basearch - Source
baseurl=http://mirrors.chinacache.com/puppetlabs/el/${RELEASE}/dependencies/SRPMS
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-puppetlabs
enabled=0
gpgcheck=1

[puppetlabs-devel-source]
name=Puppet Labs Devel El ${RELEASE} - \$basearch - Source
baseurl=http://mirrors.chinacache.com/puppetlabs/el/${RELEASE}/devel/SRPMS
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-puppetlabs
enabled=0
gpgcheck=1" >> /etc/yum.repos.d/puppetlabs-${RELEASE}.repo

echo "-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG/MacGPG2 v2.0.17 (Darwin)

mQINBEw3u0ABEAC1+aJQpU59fwZ4mxFjqNCgfZgDhONDSYQFMRnYC1dzBpJHzI6b
fUBQeaZ8rh6N4kZ+wq1eL86YDXkCt4sCvNTP0eF2XaOLbmxtV9bdpTIBep9bQiKg
5iZaz+brUZlFk/MyJ0Yz//VQ68N1uvXccmD6uxQsVO+gx7rnarg/BGuCNaVtGwy+
S98g8Begwxs9JmGa8pMCcSxtC7fAfAEZ02cYyrw5KfBvFI3cHDdBqrEJQKwKeLKY
GHK3+H1TM4ZMxPsLuR/XKCbvTyl+OCPxU2OxPjufAxLlr8BWUzgJv6ztPe9imqpH
Ppp3KuLFNorjPqWY5jSgKl94W/CO2x591e++a1PhwUn7iVUwVVe+mOEWnK5+Fd0v
VMQebYCXS+3dNf6gxSvhz8etpw20T9Ytg4EdhLvCJRV/pYlqhcq+E9le1jFOHOc0
Nc5FQweUtHGaNVyn8S1hvnvWJBMxpXq+Bezfk3X8PhPT/l9O2lLFOOO08jo0OYiI
wrjhMQQOOSZOb3vBRvBZNnnxPrcdjUUm/9cVB8VcgI5KFhG7hmMCwH70tpUWcZCN
NlI1wj/PJ7Tlxjy44f1o4CQ5FxuozkiITJvh9CTg+k3wEmiaGz65w9jRl9ny2gEl
f4CR5+ba+w2dpuDeMwiHJIs5JsGyJjmA5/0xytB7QvgMs2q25vWhygsmUQARAQAB
tEdQdXBwZXQgTGFicyBSZWxlYXNlIEtleSAoUHVwcGV0IExhYnMgUmVsZWFzZSBL
ZXkpIDxpbmZvQHB1cHBldGxhYnMuY29tPokCPgQTAQIAKAIbAwYLCQgHAwIGFQgC
CQoLBBYCAwECHgECF4AFAk/x5PoFCQtIMjoACgkQEFS3okvW7DAIKQ/9HvZyf+LH
VSkCk92Kb6gckniin3+5ooz67hSr8miGBfK4eocqQ0H7bdtWjAILzR/IBY0xj6OH
KhYP2k8TLc7QhQjt0dRpNkX+Iton2AZryV7vUADreYz44B0bPmhiE+LL46ET5ITh
LKu/KfihzkEEBa9/t178+dO9zCM2xsXaiDhMOxVE32gXvSZKP3hmvnK/FdylUY3n
WtPedr+lHpBLoHGaPH7cjI+MEEugU3oAJ0jpq3V8n4w0jIq2V77wfmbD9byIV7dX
cxApzciK+ekwpQNQMSaceuxLlTZKcdSqo0/qmS2A863YZQ0ZBe+Xyf5OI33+y+Mr
y+vl6Lre2VfPm3udgR10E4tWXJ9Q2CmG+zNPWt73U1FD7xBI7PPvOlyzCX4QJhy2
Fn/fvzaNjHp4/FSiCw0HvX01epcersyun3xxPkRIjwwRM9m5MJ0o4hhPfa97zibX
Sh8XXBnosBQxeg6nEnb26eorVQbqGx0ruu/W2m5/JpUfREsFmNOBUbi8xlKNS5CZ
ypH3Zh88EZiTFolOMEh+hT6s0l6znBAGGZ4m/Unacm5yDHmg7unCk4JyVopQ2KHM
oqG886elu+rm0ASkhyqBAk9sWKptMl3NHiYTRE/m9VAkugVIB2pi+8u84f+an4Hm
l4xlyijgYu05pqNvnLRyJDLd61hviLC8GYU=
=qHKb
-----END PGP PUBLIC KEY BLOCK-----" >> /etc/pki/rpm-gpg/RPM-GPG-KEY-puppetlabs

echo "[cc]
name=ChinaCache Custom Packages for Enterprise Linux
baseurl=http://mirrors.chinacache.com/CC/${RELEASE}/\$basearch
failovermethod=priority
enabled=1
gpgcheck=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CC" >> /etc/yum.repos.d/cc-${RELEASE}.repo

if [ ${RELEASE} -eq 4 ];
then
    sed -i 's/enabled=1/enabled=0/g' /etc/yum.repos.d/IMP-${RELEASE}.repo
    sed -i 's/enabled=1/enabled=0/g' /etc/yum.repos.d/puppetlabs-${RELEASE}.repo
    sed -i 's/enabled=1/enabled=0/g' /etc/yum.repos.d/cc-${RELEASE}.repo
fi

if [[ `uname -i` != "x86_64" ]];
then
    sed -i 's/enabled=1/enabled=0/g' /etc/yum.repos.d/IMP-${RELEASE}.repo
    sed -i 's/enabled=1/enabled=0/g' /etc/yum.repos.d/cc-${RELEASE}.repo
fi

echo -e "\033[32m Yum install complete \033[0m"
# =============================yum install end==================================================


# =============================resolve start====================================================
echo -e "\033[32m Begin to resolve \033[0m"

test -d /scripts/ || mkdir /scripts/
test -f /scripts/time.log && rm -f /scripts/time.log

resolve_CHN_CNC(){
    DNS_IP="114.114.114.114 8.8.8.8"
    for dip in ${DNS_IP}
    do
        IPLIST=`dig @${dip} mirrors.chinacache.com +short|grep ^[0-9]`
        for a in ${IPLIST}
        do
    	if [ `wget -T 5 -t 2 -qS http://${a}/BASE/1 --spider > /dev/null 2>&1;echo $?` -eq 0 ];
            then
                echo "`ping -f -c 5 ${a}|awk -F '[/|.]' '/rtt/{print $6}'` ${a}" >> /scripts/time.log
            fi
        done
        if [ -f /scripts/time.log ];
        then
            TIME=`grep ^[0-9] /scripts/time.log|sort -n|head -1|awk '{print $1}'`
            if [ -n $TIME ] || [ $TIME -eq 0 ]
            then
                if [ $TIME -gt 150 ];
                then
                    echo "This server may be not in China"
                    echo "Please wait 1-3 minutes..."
                    IP=`Check_IP`
                else
                    IP=`grep ^[0-9] /scripts/time.log|sort -n|head -1|awk '{print $NF}'`
                fi
            fi
        fi
    done
    echo ${IP}
}

if [[ ${HOST} == 'CHN' ]] || [[ ${HOST} == 'CNC' ]]
then
    IP=`resolve_CHN_CNC`
fi 

if [ -z ${IP} ];
then
    IP=`Check_IP`
    if [ -z ${IP} ];
    then
        IP='223.203.98.51'
    fi
fi

chattr -ia /etc/hosts
if [ `grep ${IP} /etc/hosts|grep -q mirrors.chinacache.com;echo $?` -ne 0 ];
then
    sed -i "/mirrors.chinacache.com/d" /etc/hosts
    echo "${IP} mirrors.chinacache.com" >> /etc/hosts
fi

# =============================resolve end====================================================

#echo -e "\033[32m rebuild rpm db \033[0m"
#rm -f /var/lib/rpm/__db.*
#rpm --rebuilddb
yum clean all
echo -e "\033[32m resolve complete \033[0m"
