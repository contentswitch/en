#Centos 5.5 install all packages
#/bin/bash
cd /root
wget -O /etc/yum.repos.d/CentOS-Base.repo http://223.203.98.51/CentOS-Base.repo
if [ $? -ne 0 ];then
	wget -O /etc/yum.repos.d/CentOS-Base.repo http://202.108.251.10/CentOS-Base.repo
fi
echo "nameserver 202.106.0.20">/etc/resolv.conf
echo "nameserver 8.8.8.8">>/etc/resolv.conf
yum -y install lib*
yum -y install openss*
yum -y install gcc*
yum -y install nmap
echo "OK!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
