#!/bin/sh
#---------------------------------------------------------------------------|
#  @Program   : serviceCheck                                                |
#  @Version   : 7.0                                                         |
#  @Company   : china cache                                                 |
#  @Dep.      : PRE                                                         |
#  @Writer    : bin.zheng  <bin.zheng@chinacache.com>                       |
#  @Date      : 2014-12-22                                                  |
#  @update    : 2016-06-13                                                  |
#---------------------------------------------------------------------------|
DOWNLOADSERVICE='mirrors.chinacache.com'
DOWNLOADSERVICE1=223.203.98.51
DOWNLOADSERVICE2='61.135.208.24'
greenEcho() {
    echo -e "\E[1;32m""$@ \033[0m"
}
redEcho() {
    echo -e "\E[1;31m""$@ \033[0m"
}

grep -q "114.114" /etc/resolv.conf || echo "nameserver 114.114.114.114" >> /etc/resolv.conf
wget -q http://${DOWNLOADSERVICE1}/yum/servers/yum_install.sh -O -|sh

wget -q -N -O /root/serviceCheck_Base.sh http://${DOWNLOADSERVICE1}/BASE/serviceCheck_Base.sh
sh /root/serviceCheck_Base.sh
#if [ $? -ne 0 ]
#then
#    exit 1
#fi
greenEcho "Base is finish!!!!!"
sleep 1

APPS="SQUID LDC EXIT"
echo "Please choose one to install:"
select N in ${APPS}
do
    case $N in
        SQUID)
            greenEcho "Begin to install SQUID"
            sleep 3
            wget -q -N -O /root/serviceCheck_installFC.sh http://${DOWNLOADSERVICE1}/FC/serviceCheck_installFC.sh
            sh /root/serviceCheck_installFC.sh
            if [ $? -ne 0 ];
            then
                break
            fi
            greenEcho "FC is finish"
            break
        ;;
        LDC)
	    #redEcho "install LDC script being modified, hold on!"
            greenEcho "Begin to install LDC"
            wget -T 5 -t 2 -q -N -O /root/serviceCheck_installLDC.sh http://${DOWNLOADSERVICE1}/serviceCheck_installLDC.sh
            sh /root/serviceCheck_installLDC.sh
            if [ $? -ne 0 ];then
                break
            fi
            greenEcho "LDC is finish"
            break
        ;;
        EXIT)
            break
        ;;
        *)
            echo "Error, please input again."
        ;;
    esac
done
test /root/serviceCheck_Base.sh && rm -f /root/serviceCheck_Base.sh
test /root/serviceCheck_installFC.sh && rm -f /root/serviceCheck_installFC.sh
test /root/serviceCheck_installLDC.sh && rm -f /root/serviceCheck_installLDC.sh
