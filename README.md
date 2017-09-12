使用说明

1. 搭建一个nginx环境 (假设ip: 192.168.32.222 文件下载目录: /tmp/hls)

a. 下载content.tar.gz后, 解压到/tmp/hls 

b. 使能nginx服务使外面可以访问到, 访问方法:  wget http://isssource/content/serviceCheckBaseData/BASE/serviceCheck_Base.sh

nginx服务器搭建方法 (待续)


2. 在新机器(待安装机器)上执行

a. 下载content.tar.gz后, 解压到/root

b. 执行bash content/serviceCheckBaseData/BASE/serviceCheck_Base.sh 

hostname参考:
https://github.com/contentswitch/environment/blob/master/hostname_refer

c. 执行bash content/serviceCheckInstallFCData/FC/serviceCheck_installFC.sh

d. 执行bash content/serviceCheckInstallLDCData/serviceCheck_installLDC.sh (不要安装iptables)


3. 安装并启动FC

https://github.com/contentswitch/environment/blob/master/fcConcern/fc_from_zero

4. 安装并启动SMS

https://github.com/contentswitch/environment/blob/master/smsConcern/sms_from_zero

