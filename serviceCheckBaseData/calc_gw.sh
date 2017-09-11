#!/bin/bash
# find ip infos and calc gateway
# write gateways to file which will be used flush router scripts
# author : peng.xu
# date : 2017-9-5

# kernel
KERN=`uname -r | grep -oP "el\d+" | tr -d el`
[ -z "$KERN" ] && KERN=`grep -oP ' \d' /etc/redhat-release |tr -d " "`

# file path
GW_path='/etc/sysconfig/network-scripts/Gateway'
[ -f $GW_path ] && true > $GW_path

tmp_file='/tmp/InfoFile'
[ -f $tmp_file ] && rm -f $tmp_file

# tools
[ -z "which ipcalc" ] && yum install -y initscripts

# find ip and mask
find_info(){
if [ $KERN -lt 7 ]
then
    ifconfig | grep -E "^(eth|bond)[0-9]\.+" -A1 |grep -i mask | awk -F':' '{print $2,$NF}' | tr -d "Bcast" > $tmp_file
elif [ $KERN -eq 7 ]
then
    ifconfig | grep -E "^(eth|bond)[0-9]\.+" -A1 |grep -i mask | awk '{print $2,$4}' > $tmp_file
fi

}

# calc gw and write to file
calc_write(){
    while read ip nw
    do
        NetWork=`ipcalc -n $ip $nw | awk -F'=' '{print $NF}'`
        echo $NetWork | awk -F'.' '{print $1"."$2"."$3"."$NF+1}' >> $GW_path
    done < $tmp_file
    wait
    rm -f $tmp_file
    cat $GW_path
}

find_info
[ -s $tmp_file ] && calc_write || echo -e "\033[31m No Trunk GateWay found \033[0m"
