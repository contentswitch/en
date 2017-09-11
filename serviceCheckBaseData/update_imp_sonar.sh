#!/bin/bash
RELEASE=`cat /etc/redhat-release|grep -oE "[0-9]"|head -1`
if [ ! -f /etc/yum.repos.d/IMP-${RELEASE}.repo ] || [ `grep -q mirrors.chinacache.com /etc/hosts;echo $?` -ne 0 ];
then
    wget -q http://223.203.98.51/yum/servers/yum_install.sh -O -|sh
fi

if [ `grep -q IMP_TEST /etc/yum.repos.d/IMP-${RELEASE}.repo;echo $?` -ne 0 ];
then
    echo "[IMP_TEST]
name=IMP_TEST
keepcache=0
baseurl=http://223.203.98.51/imp/testing/CENTOS-${RELEASE}/
enabled=0
gpgcheck=0" >> /etc/yum.repos.d/IMP-${RELEASE}.repo
fi

yum_install_falcon(){
    echo "stop sonar-falcon."
    /imp/sonar-falcon/control stop > /dev/null 2>&1
    echo "yum remove sonar-falcon."
    yum remove sonar-falcon -y
    yum clean all;
    yum --disablerepo=* --enablerepo=IMP install sonar-falcon -y
    if [ $? -gt 0 ];
    then
        echo "yum install sonar-falcon error."
    else
        echo "yum install sonar-falcon ok."
    fi
}

yum_install_logmon(){
    echo "stop sonar-logmon."
    /imp/sonar-logmon/control stop > /dev/null 2>&1
    echo "yum remove sonar-logmon."
    yum remove sonar-logmon -y
    yum clean all;
    yum --disablerepo=* --enablerepo=IMP install sonar-logmon -y
    if [ $? -gt 0 ];
    then
        echo "yum install sonar-logmon error."
    else
        echo "yum install sonar-logmon ok."
    fi
}

yum_install_amr(){
    echo "stop sonar-amr."
    /imp/sonar-amr/control stop > /dev/null 2>&1
    echo "yum remove sonar-amr."
    yum remove sonar-amr -y
    yum clean all;
    yum --disablerepo=* --enablerepo=IMP install sonar-amr -y
    if [ $? -gt 0 ];
    then
        echo "yum install sonar-amr error."
    else
        echo "yum install sonar-amr ok."
    fi
}

yum_install(){
    yum --disablerepo=* --enablerepo=IMP install sonar-python27 -y
    yum_install_falcon
    yum_install_logmon
    yum_install_amr
}

clean_yum(){
    if [ `grep -q IMP_TEST /etc/yum.repos.d/IMP-${RELEASE}.repo;echo $?` -eq 0 ];
    then
        sed -i '/IMP_TEST/,$d' /etc/yum.repos.d/IMP-${RELEASE}.repo
    fi
}

main(){
    yum_install
    if [ $? -gt 0 ];
    then
        echo " yum error."
    else
        clean_yum
    fi
}

main "$@"
