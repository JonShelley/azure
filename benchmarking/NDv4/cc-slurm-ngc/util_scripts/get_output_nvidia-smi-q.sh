#!/bin/bash
  
mkdir -p /nfs/diags
sudo chmod 777 /nfs/diags

hostname=`hostname`
nvidia-smi -q &> /nfs/diags/${hostname}-nvidia-smi-q.txt
