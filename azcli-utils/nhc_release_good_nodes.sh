#!/bin/bash

resource_group=$1
cfg=${2:-config.json}
vmss=${3:-compute1}
headnode=${4:-headnode}
user=${5:-hpcadmin}

#freenodes=$(mktemp freenodes.XXXXXX)
freenodes=freenodes.out
private_ips=$(mktemp private_ips.XXXXXX)

azhpc-run -c $cfg -u $user -n $headnode "mkdir -p /apps/fleet-health"
azhpc-scp ~/util_scripts/nhc_get_pbs_nodes_ip.sh  hpcuser@headnode:/apps/fleet-health/nhc_get_pbs_nodes_ip.sh
azhpc-run -c $cfg -u $user -n $headnode /apps/fleet-health/nhc_get_pbs_nodes_ip.sh $vmss > $freenodes
az vmss nic list --vmss-name $vmss --resource-group $resource_group --query [].[virtualMachine.id,ipConfigurations[0].privateIpAddress] --output tsv > $private_ips

todel=()
del_nodes=()
while read -r node ip; do
    echo "Node: $node, IP: $ip"
    path=$(grep -w $ip $private_ips) 
    instance=$(basename $path)
    del_nodes+=($node)
    todel+=($instance)
done < $freenodes

echo "VMSS IDs: ${todel[@]}"
echo "Node Names: ${del_nodes[@]}"
az vmss delete-instances --resource-group $resource_group --name $vmss --instance-ids "${todel[@]}"

unset del_nodes[0]
azhpc-run -c $cfg -u hpcuser -n $headnode "for x in ${del_nodes[@]} ;do echo \$x;/opt/pbs/bin/qmgr -c \"d n \$x\";done"
