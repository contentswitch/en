#!/bin/bash
#
#---------------------------------------------------------------------------|
#  @Program   : init_rrd.sh                                                 |  
#  @Company   : chinacache                                                  |
#  @Dep.      : inm                                                         |
#  @Writer    : senlin.zhang  <senlin.zhang@chinacache.com                  |
#  @Date      : 2011-05-20                                                  |
#---------------------------------------------------------------------------|
#
#Centos 5.5 install all packages
cd /root
#yum -y --skip-broken install lib*
yum -y install glibc-*
yum -y install openss*
yum -y install gcc*
yum -y install nmap
echo "OK!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
