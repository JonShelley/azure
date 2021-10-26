#!/bin/bash
## Note: Before you can run this script you need to build gpu-bwtest and copy the binary to BASE_DIR
##       To build it you need to go to a NDv[2+] VM and if you are using a HPC marketplace image go then
##       cd /usr/local/cuda/samples/1_Utilities/bandwidthTest/ and run "sudo make". 
##       Then copy bandwidthTest to $BASE_DIR/gpu-bwtest
##       

BASE_DIR=/shared/data/tools

vmId=`curl -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2019-06-04" | jq '.compute.vmId'`
echo "VM ID: $vmId"

echo "Device: DtoH : HtoD"
for device in {0..7}
do
    dtoh=`CUDA_VISIBLE_DEVICES=$device numactl -N$(( device / 2 )) -m$(( device / 2 )) ${BASE_DIR}/gpu-bwtest -dtoh | 
    grep 32000000 | awk '{print $2}'`
        htod=`CUDA_VISIBLE_DEVICES=$device numactl -N$(( device / 2 )) -m$(( device / 2 )) ${BASE_DIR}/gpu-bwtest -htod | grep 32000000 | awk '{print $2}'`
            echo "${device} : ${dtoh} : ${htod}"
            done
