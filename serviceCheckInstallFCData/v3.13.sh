#!/bin/bash

ARCH=x86_64

SERVERIP="mirrors.chinacache.com/BASE"
HOSTNAME=`hostname`
#if [[ "$HOSTNAME" =~ "^CHN-*" ]]; then
#	SERVERIP=220.181.45.26
#fi
#echo "Update sever: $SERVERIP";

KBUILD=`uname -a | awk '{print $3" "$4}'`
CCOS=""
CCBUILD=""
RUNOS=""
function check_prev_ccos {
    MD5LINUX2637="70e13914aee4ac76e86d4eca50cca2de"
    MD5CFG7="5ffcc8ed2ef0a2a1195fdf1d87d00608"
    MD5CFG7IGB="abe673dd1f94e7d6537a2f48f18e3f5e"
    MD5CFG6="4536d2fd415ef464cec8c572d83592d7"
    MD5CFG5B64="4601467fde1a5abab69df9642d441951"

    CCOSCHECK=`wget -q http://${SERVERIP}/download/luyc/ccos-2.6.37/ccoscheck -O - | bash -s preupcheck --`
    
    MD5=`echo "${CCOSCHECK}" | awk -F'[()]' '{print $2}'`
    RUNOS=`echo "${CCOSCHECK}" | awk '{print $10" "$11}'`
    CCOS=`echo "${CCOSCHECK}" | awk -F'[() ]' '{print $6}'`
    CCBUILD=`echo "${CCOSCHECK}" | awk -F'[() ]' '{print $6" "$7}'`

    case "${CCOS}" in
        2.6.37-1)
            if [ "${MD5}" != "${MD5LINUX2637}" ]; then
                CCOS=""
            fi
            ;;
        #2.6.24.4-7)
        #    if [ "${MD5}" != "${MD5CFG7}" ]; then
        #        if [ "${MD5}" != "${MD5CFG7IGB}" ]; then
        #            CCOS=""
        #        fi
        #    fi
        #    ;;
        #2.6.24.4-6)
        #    if [ "${MD5}" != "${MD5CFG6}" ]; then
        #        CCOS=""
        #    fi
        #    ;;
        #2.6.24.4-5)
        #    if [ "${MD5}" != "${MD5CFG5B64}" ]; then
        #        CCOS=""
        #    fi
        #    ;;
        *)
            CCOS=""
        ;;
    esac
}

check_prev_ccos
if [ "${CCOS}" != "" -a "${CCBUILD}" != "" ]; then
TIP="Ok. The latest kernel ${CCBUILD} was already installed. need reboot"
if [ "${CCBUILD}" != "" ]; then
if [ "${CCBUILD}" = "${RUNOS}" ]; then
TIP="Ok. The kernel ${CCBUILD} is up to date."
fi
fi

echo "${TIP}"
exit 0
fi

CONFIG="" # set by device info

ERROR=""
function check_dev_config {
    KVERSION=`uname -r`
    LSPCI=`lspci`
    if [ "$LSPCI" = "" ]; then
        #echo "It's a virtual machine device(${KBUILD})."
        CONFIG=5
        return 0
    fi
    case "${KVERSION}" in
        2.6.37-1)
            CONFIG=5
            ;;
        #2.6.24.4-7)
        #    CONFIG=7
        #    ;;
        #2.6.24.4-6)
        #    CONFIG=6
        #    ;;
        #2.6.24.4-5)
        #    wget -q http://${SERVERIP}/download/luyc/cc-os-cfg5-x86_64/ccosupdate-cfg5-x86_64.sh -O - | bash
        #    exit $?
        #    ;;
        #2.6.24.4)
        #    if [ "${KBUILD}" = "2.6.24.4 #6" ]; then
        #        CONFIG=6
        #    else
        #        CONFIG=7
        #    fi
        #    ;;
        *)
            #BCM5716=`lspci | grep 'BCM5716'`
            #if [ "$BCM5716" != "" ]; then
            #    echo "Failed. NIC BCM5716's driver doesn't support, can't update!"
            #    exit 1
            #fi
            #SAS2008=`lspci | grep 'Logic SAS2008'`
            #if [ "$SAS2008" != "" ]; then
            #    echo "Failed. SCSI SAS2008's driver doesn't support, can't update!"
            #    exit 1
            #fi
            ERROR="Failed. This type of device(${KBUILD}) has not been tested. Update may fail, so i quit!"
            CONFIG=5
            #return 1
            ;;
    esac
    return 0
}

check_dev_config
dev_type="`uname -i`"
if [ "$dev_type" = "i386" ];then
echo "Failed. This 32-bits device(${KBUILD}) not support!";
exit 1;
fi
install_is_ok="`uname -r | grep 2.6.37`"
if [ "$install_is_ok" == "" ];then
	 echo "************** WARNING **********************************************************"
	 echo "This machine is not running on kernel 2.6.37. "
	 echo "Current kernel \""`uname -r`"\" may not works well."
	 echo "If it cannot boot up after installation, please contact TCP optimization team."
	 echo "Enter 'y' to continue, otherwise we will stop installation after 10 s."
	 echo "**********************************************************************************"
	 installcmd="n"
	 read -t 10 -n 1 -p "Please Enter 'y' or 'n' : " installcmd;
	 echo
	 if [ "$installcmd" != "y" ];then
	    echo "Installation Failed.";
		exit 1;
	 fi
fi
echo "Installing, please wait"
grep 5\\. /etc/redhat-release &> /dev/null && IS_CENTOS5=1
if [ -z $IS_CENTOS5 ]; then
CONFIG=8.el6
MODPROBE='/etc/modprobe.d/cctcp.conf'
touch $MODPROBE
else
CONFIG=8.el5
MODPROBE='/etc/modprobe.conf'
fi
if [ "${CONFIG}" = "" ]; then
echo $ERROR;
exit 1;
fi

#echo "Looks fine to the kernel using config-$CONFIG. Please check update result before reboot."
{ date; uname -a; } >> /etc/.kernel_history

KERNEL_VERSION=2.6.37-${CONFIG}
CCTCP_VERSION=1.3-3
SERVER_PATH=download/CCTCPv3/v3.13
CCVA="ccv13"
CCVAKMDIR="/lib/modules/$KERNEL_VERSION/kernel/net/ipv4"


mv -f kernel-$KERNEL_VERSION.${ARCH}.rpm kernel-$KERNEL_VERSION.${ARCH}.rpm.bk >/dev/null 2>&1
#echo "Downloading kernel-$KERNEL_VERSION.${ARCH}.rpm ..."
wget -q http://${SERVERIP}/${SERVER_PATH}/kernel-$KERNEL_VERSION.${ARCH}.rpm -O kernel-$KERNEL_VERSION.${ARCH}.rpm
#echo "Download kernel-$KERNEL_VERSION.${ARCH}.rpm completed"
if [ -z $IS_CENTOS5 ]; then
wget -q http://${SERVERIP}/${SERVER_PATH}/kernel-firmware-$KERNEL_VERSION.noarch.rpm
fi

#rpm -q --quiet kernel-2.6.24.4-7 >/dev/null && rpm -e kernel-2.6.24.4-7
rpm -q --quiet kernel-2.6.37-6 >/dev/null && rpm -e kernel-2.6.37-6
rpm -q --quiet kernel-$KERNEL_VERSION >/dev/null && rpm -e kernel-$KERNEL_VERSION

if [ "${CONFIG}" = "6" ]; then
sed -i 's/^\(.*scsi.*\)/#\1/' ${MODPROBE}
fi
sed -i 's/^\(.*megasr.*\)/#\1/' ${MODPROBE}

rpm -q --quiet lksctp-tools-1.0.2-6.4E.1.i386 && rpm -e --nodeps lksctp-tools-1.0.2-6.4E.1.i386
rpm -q --quiet lksctp-tools-devel-1.0.2-6.4E.1.i386 && rpm -e --nodeps lksctp-tools-devel-1.0.2-6.4E.1.i386
rpm -q --quiet lksctp-tools-doc-1.0.2-6.4E.1.i386rpm && rpm -e --nodeps lksctp-tools-doc-1.0.2-6.4E.1.i386
sed -i '49s/lineNum == 6/lineNum == 8/' /monitor/bin/netConnMon.pl 2>/dev/null
sed -i '/^SELINUX=/s/enforcing/disable/' /etc/selinux/config

# IO performance tuning
TMP=`mktemp`
cat << 'EOD' > $TMP
# Augment read_ahead_kb to improve Disk/IO performance
VERSION=`perl -le 'print join "", map { sprintf "%03d", $_ } (split /\./, (split /-/, qx(uname -r))[0])[0..2]'`
if [ $VERSION -ge '002006024' ]
then
    perl -e 'map { `echo 512 > /sys/block/$_/queue/read_ahead_kb` }
        `fdisk -l | grep Disk` =~ m{dev/(.*):}mg'
fi
# End of augment read_ahead_kb
EOD
RC_LOCAL=`readlink -n -f /etc/rc.local`
sed -i '/Augment read_ahead_kb/,/End of augment read_ahead_kb/d' $RC_LOCAL
cat $TMP >> $RC_LOCAL
rm -f $TMP

####

# bind NIC MAC
ifcfgDir="/etc/sysconfig/network-scripts"
bondDir="/proc/net/bonding"

function getRealMac {
    ifcfg=$ifcfgDir"/ifcfg-"$1
    bondif=`grep '^MASTER' $ifcfg 2>/dev/null | awk -F'=' '{print $2}'`

    if [ -n "$bondif" ]; then
        mac=`grep -E "Slave Interface|Permanent HW addr" $bondDir/$bondif | awk -F': ' '{print $2}' | grep $1 -A1 | tail -1`
    else
        mac=`ifconfig $1 2>/dev/null | grep HWaddr | awk -F'HWaddr ' '{print $2}'`
    fi
    echo $mac
}
function checkBindMac {
    ifcfg=$ifcfgDir"/ifcfg-"$1
    if [ ! -f $ifcfg ]; then
        return 2
    fi
    grep '^HWADDR=' $ifcfg &>/dev/null
    if [ $? -eq 0 ];then
        echo "bound: $ifcfg"
        return 1
    else
        return 0
   fi
}

ethList=`grep ' eth' /proc/net/dev 2>/dev/null | awk -F: '{print $1}'`
for eth in $ethList
do
    checkBindMac $eth
    if [ $? -eq 0 ];then
        mac=`getRealMac $eth`
        if [ -n "$mac" ]; then
            echo "HWADDR=$mac" >> $ifcfgDir"/ifcfg-"$eth
            echo "bind: $eth HWADDR=$mac"
        fi
    fi
done
###

rm -f $CCVAKMDIR/tcp_ccv*.ko /lib/modules/${KERNEL_VERSION}/extra/flashcache/flashcache.ko
if [ -z $IS_CENTOS5 ]; then
\cp -fr /lib/firmware /tmp/
rpm -e --nodeps kernel-firmware 2>/dev/null ||:
rpm --quiet -i kernel-firmware-$KERNEL_VERSION.noarch.rpm
rm -f kernel-firmware-$KERNEL_VERSION.noarch.rpm
\cp -frn /tmp/firmware/* /lib/firmware
\rm -fr /tmp/firmware
fi
rpm --quiet -ivh --oldpackage kernel-$KERNEL_VERSION.${ARCH}.rpm >/dev/null
rm -f kernel-$KERNEL_VERSION.${ARCH}.rpm

if [ "${CONFIG}" = "6" ]; then
sed -i 's/^#*\(.*scsi.*\)/\1/' ${MODPROBE}
fi
sed -i 's/^#*\(.*megasr.*\)/\1/' ${MODPROBE} &>/dev/null

#for ccvx in $CCVA
#do
#done

#echo "Downloading cctcp-utils-$CCTCP_VERSION.i386.rpm ..."
wget -q http://${SERVERIP}/${SERVER_PATH}/cctcp-utils-$CCTCP_VERSION.rpm -O cctcp-utils-$CCTCP_VERSION.rpm
#echo "Download cctcp-utils-$CCTCP_VERSION.i386.rpm completed" 

rpm -q --quiet cctcp-utils-$CCTCP_VERSION && rpm -e cctcp-utils-$CCTCP_VERSION&>/dev/null
rpm -q --quiet cctcp-utils && rpm -e cctcp-utils &>/dev/null
rm -f /etc/cctcp.cfg* /etc/cctcp-mode*

rpm --quiet -ivh cctcp-utils-$CCTCP_VERSION.rpm >/dev/null
rm -f cctcp-utils-$CCTCP_VERSION.rpm

if [ -z $IS_CENTOS5 ]; then
INITRD=initramfs
else
INITRD=initrd
fi
rpm -q --quiet kernel-$KERNEL_VERSION && ls /boot/$INITRD-$KERNEL_VERSION.$ARCH.img &>/dev/null || { echo 'Failed. Some file has not been installed correctly.'; exit 1; }

#echo "Download hio driver"
#mkdir -p /lib/modules/${KERNEL_VERSION}/kernel/drivers/hio
#wget -q http://${SERVERIP}/${SERVER_PATH}/hio.ko -O /lib/modules/2.6.37-5/kernel/drivers/hio/hio.ko &>/dev/null
if [ ! -z $IS_CENTOS5 ]; then
sed -i '$a \\nmodprobe hio &>/dev/null' /etc/rc.local
sed -ri 's/^(A.*)(SUBSYSTEM=="scsi", )(.*)$/#\1\2\3\n\1\2KERNEL=="[0-9]*:[0-9]*", WAIT_FOR_SYSFS="ioerr_cnt"/;' /etc/udev/rules.d/05-udev-early.rules
fi

#echo "Download the latest drivers"
#wget -q http://${SERVERIP}/${SERVER_PATH}/e1000.ko -O /lib/modules/${KERNEL_VERSION}/kernel/drivers/net/e1000/e1000.ko &>/dev/null
#wget -q http://${SERVERIP}/${SERVER_PATH}/e1000e.ko -O /lib/modules/${KERNEL_VERSION}/kernel/drivers/net/e1000e/e1000e.ko &>/dev/null
#wget -q http://${SERVERIP}/${SERVER_PATH}/ixgbe.ko -O /lib/modules/${KERNEL_VERSION}/kernel/drivers/net/ixgbe/ixgbe.ko &>/dev/null
#wget -q http://${SERVERIP}/${SERVER_PATH}/igb.ko -O /lib/modules/${KERNEL_VERSION}/kernel/drivers/net/igb/igb.ko &>/dev/null

#echo "Download flashcache driver"
#mkdir -p /lib/modules/${KERNEL_VERSION}/extra/flashcache/flashcache
#wget -q http://${SERVERIP}/${SERVER_PATH}/flashcache.ko -O /lib/modules/${KERNEL_VERSION}/extra/flashcache/flashcache.ko &>/dev/null
wget -q http://${SERVERIP}/${SERVER_PATH}/flashcache.modules -O /etc/sysconfig/modules/flashcache.modules
chmod 755 /etc/sysconfig/modules/flashcache.modules

wget -q http://${SERVERIP}/${SERVER_PATH}/flashcache_create -O /usr/local/sbin/flashcache_create
wget -q http://${SERVERIP}/${SERVER_PATH}/flashcache_load -O /usr/local/sbin/flashcache_load
wget -q http://${SERVERIP}/${SERVER_PATH}/flashcache_destroy -O /usr/local/sbin/flashcache_destroy
wget -q http://${SERVERIP}/${SERVER_PATH}/flashcache_scan -O /usr/local/sbin/flashcache_scan
chmod 755 /usr/local/sbin/flashcache_*

sed -i 's/\=A/\=LA/g' /etc/grub.conf

echo "Ok. Installed new kernel $KERNEL_VERSION. Please check before reboot($KBUILD)."

{ date; ls -lh /boot/initrd-$KERNEL_VERSION.img 2>/dev/null; } >> /etc/.kernel_history
