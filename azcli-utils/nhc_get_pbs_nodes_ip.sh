#!/bin/bash

vmss=${1:-compute1}

/opt/pbs/bin/pbsnodes -avS |grep free | grep $vmss | awk '{print $1}' > freenodes.$vmss

for x in `cat freenodes.$vmss`;do
    ip=`nslookup $x | tail -n 2 | grep Address | awk '{print $2}'`
    echo "$x $ip"
done
