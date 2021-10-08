#!/bin/bash

mkdir -p /nfs/dcgm-results
hostname=`hostname`
echo "Hostname: $hostname"
dcgmi diag -r 3 &> /nfs/dcgm-results/${hostname}-dcgmi-diag-3.out
