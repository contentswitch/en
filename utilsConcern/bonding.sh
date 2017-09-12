#!/bin/bash

#---------------------------------------------------------------------------|
#  @Program   : bonding.sh                                                  |
#  @Version   : 2.0                                                         |
#  @Company   : china cache                                                 |
#  @Dep.      : sysops                                                      |
#  @Writer    : peng.xu  <peng.xu@chinacache.com>                           |
#  @Date      : 2017-06-13                                                  |
#---------------------------------------------------------------------------|
CONFIGFILE=/etc/modprobe.conf
CONFIGPATH=/etc/sysconfig/network-scripts
yum install -y redhat-lsb
SYSTEM_version=`lsb_release -a|grep "Release"|awk '{print $2}'`
KERN=`uname -r |grep -oP 'el\d+'`
modprobe bonding
bond_M=$1

# check args
if [ "${bond_M}" == "" ];then
    echo -e "`printf %-16s "Usage: \n\tsh $0"` <bond0|bond1>"
    exit 1
fi

# pre
if [ "$KERN" == "el6" ];then
        ln -sf /etc/rc.d/rc.local /etc/rc.local
	/etc/init.d/NetworkManager stop
elif [ "$KERN" == "el7" ];then
        ln -sf /etc/rc.d/rc.local /etc/rc.local
	has_eth=`ifconfig |grep "^eth[0-3]:"`
	if [ -z "$has_eth" ];then
		echo -e "\033[32mpresent to change name for netcards\033[0m"
		LANG=C
		dmesg | grep rename| awk '{print $7,$9}' > /tmp/temp.txt
		mkdir $CONFIGPATH/bak
		sed -i 's/yes/no/g' ${CONFIGPATH}/bak/ifcfg-*;
		cp ${CONFIGPATH}/ifcfg-* ${CONFIGPATH}/bak/ -f
		while read eth en
		do
		  ifindex=$(udevadm info -a -p /sys/class/net/${en} |grep ifindex | awk -F '"' '{print $2}')
		  mac_add=$(ifconfig  ${en} | awk '/ether/ {print $2}')
		  i=$((ifindex-2))
		if [ -f  ${CONFIGPATH}/ifcfg-${en} ];then
		
		  sed -i "s/$en/eth$i/" ${CONFIGPATH}/ifcfg-${en}
		  mv ${CONFIGPATH}/ifcfg-${en} ${CONFIGPATH}/ifcfg-eth$i
		elif [ -f ${CONFIGPATH}/ifcfg-eth$i ];then
				:
		else
		cat > ${CONFIGPATH}/ifcfg-eth$i <<END
DEVICE="eth$i"
ONBOOT=yes
NETBOOT=yes
UUID="$(uuidgen)"
IPV6INIT=yes
BOOTPROTO=dhcp
HWADDR="${mac_add}"
TYPE=Ethernet
NAME="eth$i"
END
		fi
		done < /tmp/temp.txt
		
		sed -i.bak 's/crashkernel\=auto/&\ net\.ifnames\=0\ biosdevname\=0/' /etc/default/grub
		grub2-mkconfig -o /boot/grub2/grub.cfg
		ls -l /etc/sysconfig/network-scripts/ifcfg-eth*

	fi
true > /etc/udev/rules.d/70-persistent-net.rules
for dev in eth{0..3}
do
	mac_add=$(ifconfig  ${dev} | awk '/ether/ {print $2}')
	[ -n "$mac_add" ] && echo -e "SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="${mac_add}", ATTR{type}=="1", KERNEL=="eth*", NAME="$dev"" >> /etc/udev/rules.d/70-persistent-net.rules
done
fi

# config bond-mode
cat > ifcfg-${bond_M}  << A
DEVICE=${bond_M}
ONBOOT=yes
BOOTPROTO=static
NETMASK=netMask
IPADDR=ipAddr
GATEWAY=gateWay
A

# config eth-init
cat > ifcfg-eth << B
DEVICE=ethn
ONBOOT=yes
MASTER=${bond_M}
SLAVE=yes
B
trap 'EXIT' 2

HELP()
{
        echo "Usage: bondConfig ip netmask gateway port1 port2 port3 "
        echo "E.g.: bondConfig 113.12.84.131  255.255.255.192 113.12.84.129 eth1 eth2 eth3"
}

EXIT()
{
	echo "process to discontinue."
	CLEAR
	exit
}

CLEAR()
{
	rm -rf ifcfg-eth
}

# config modprobe
if [ "$KERN" != "el7" ];then
	grep -qs "options ${bond_M}" $CONFIGFILE || echo -e "alias ${bond_M} bonding\noptions ${bond_M} mode=0 miimon=100 use_carrier=0 " >> $CONFIGFILE
fi

# input ip infos
read -p "please input IP address:	" IP
read -p "please input netmask:	" netmask
read -p "please input gateway:	" gateway
echo -e "$IP\n$netmask\n$gateway\n"
sed -i "s/ipAddr/$IP/;s/gateWay/$gateway/;s/netMask/$netmask/" ifcfg-${bond_M}

# input bound netcards
mv ifcfg-${bond_M} $CONFIGPATH

read -ep "please input port:E.g.: 0 1 2 3   " tmp
port=($tmp)
portNum=${#port[*]}
for((i=0;i<portNum;i++))
do
	mv $CONFIGPATH/ifcfg-eth${port[$i]} $CONFIGPATH/ifcfg-eth${port[$i]}.bak
	sed -i 's/yes/no/g' $CONFIGPATH/ifcfg-eth${port[$i]}.bak
	cp ifcfg-eth $CONFIGPATH/ifcfg-eth${port[$i]}
	sed -i "s/ethn/eth${port[$i]}/" $CONFIGPATH/ifcfg-eth${port[$i]}
	grep "HWADDR=" $CONFIGPATH/ifcfg-eth${port[$i]}.bak >>$CONFIGPATH/ifcfg-eth${port[$i]}
done

# extend configure
if [ "$KERN" == "el6" ];then
	ifup ${bond_M}
        slaveeth=''
        for((i=0;i<portNum;i++));do
                slaveeth="${slaveeth} eth${port[$i]}"
        done
        ifenslave ${bond_M} ${slaveeth}
        echo "ifenslave ${bond_M} ${slaveeth}" >>/etc/rc.local
	chkconfig --level 2345 NetworkManager off
	/etc/init.d/NetworkManager stop
	/etc/init.d/network restart
elif [ "$KERN" == "el7" ];then
	echo "BONDING_MASTER=yes" >> $CONFIGPATH/ifcfg-${bond_M}
	echo 'BONDING_OPTS="mode=0 miimon=100 use_carrier=0"' >> $CONFIGPATH/ifcfg-${bond_M}
	echo "NAME=${bond_M}" >> $CONFIGPATH/ifcfg-${bond_M}
	slaveeth=''
	for((i=0;i<portNum;i++));do
                slaveeth="${slaveeth} eth${port[$i]}"
        done
	echo ${slaveeth} | sed 's/[^a-z0-9]/\n/g' | while read ethdd; do echo -e "TYPE=Ethernet\nNAME=${ethdd}" >> $CONFIGPATH/ifcfg-$ethdd; done
	service network restart
fi
CLEAR
#	reboot
