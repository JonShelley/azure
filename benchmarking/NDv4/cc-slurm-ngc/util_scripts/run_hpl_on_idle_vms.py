#!/opt/cycle/jetpack/system/embedded/bin/python3
##!/usr/bin/env python

import subprocess
import re
import shutil
from pathlib import Path

# Run sinfo and get idle VMs
cmd="sinfo"
partition="hpc"
output = subprocess.run([cmd], stdout=subprocess.PIPE).stdout.decode('utf-8')

lines = output.split("\n")
vms = "empty"
for line in lines:
    if line.find(partition) != -1 and line.find("idle ") != -1:
        vms = line.split()[-1]
        vms_prefix = vms.split("[")[0]
        tmp = re.search(r"\[([A-Za-z0-9_,-]+)\]", vms)
        vms_values = str(tmp.group(1))

print("VMs: {}".format(vms))
print("VMs prefix: {}".format(vms_prefix))
print("VMs values: {}".format(vms_values))

# Run hpl job on each VM
dir_name = 'hpl-tests'
shutil.rmtree(dir_name)
Path( dir_name ).mkdir( parents=True, exist_ok=True )

vm_list = vms_values.split(',')
for value in vm_list:
    if value.find("-") != -1:
        low,high = value.split("-")
        print("Low: {}, High: {}".format(low,high))
        vm_values = [ *range( int(low), int(high) + 1) ]
    else:
        vm_values = [ value ]
	    
    print("VMs: {}".format(vm_values))
    for val in vm_values:
        cmd = "sbatch -p {} -N 1 -w {}{} -o {}/%j.log ../hpl/hpl.sub".format(partition, vms_prefix, val, dir_name)
        print("Slurm cmd: {}".format(cmd))
        status = subprocess.call(cmd, shell=True)

# Determine which VMs did not make the grade

