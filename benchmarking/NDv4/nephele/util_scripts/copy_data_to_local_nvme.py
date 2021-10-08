#!/opt/cycle/jetpack/system/embedded/bin/python3
##!/usr/bin/env python

import subprocess
import re
import shutil
import string
from pathlib import Path

# Variables
pdsh_cmd = "parallel-ssh"
pdsh_timeout = 7200
std_dir_path = "mlcommons/v1.1/sqsh_files"
copy_src = "<azure_blob_storage_path_to_files>"
copy_dst = "/mnt/resource_nvme/{}".format(std_dir_path)
partition = "hpc"



# Run sinfo and get idle VMs
cmd="sinfo"
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

# Run nccl job on each VM
dir_name = 'nccl-tests'
shutil.rmtree(dir_name)
Path( dir_name ).mkdir( parents=True, exist_ok=True )
vm_list = vms_values.split(',')
all_vms = []
for value in vm_list:
    if value.find("-") != -1:
        low,high = value.split("-")
        print("Low: {}, High: {}".format(low,high))
        vm_values = [ *range( int(low), int(high) + 1) ]
    else:
        vm_values = [ value ]

    all_vms += vm_values

print("VMs: {}".format(all_vms))

# Create host file for parallel ssh
hosts = []
hosts_filename = "pssh-{}.hosts".format(partition)
for vm in all_vms:
    hosts.append("{}{}".format(vms_prefix, vm))

#print("hosts: {}".format(hosts))
hosts_line = "\n".join(hosts)
#print("Hosts Line: {}".format(hosts_line))
hostfile = open(hosts_filename,"w")
hostfile.write("{}".format(hosts_line))
hostfile.close()

# Make destination dir
cmd = "{} -t {} -h {} mkdir -p {}".format(pdsh_cmd, pdsh_timeout, hosts_filename, copy_dst)
print ("CMD: {}".format(cmd))

# Run pssh
cmd = "{} -t {} -h {} azcopy cp \"{}\" {}".format(pdsh_cmd, pdsh_timeout, hosts_filename, copy_src, copy_dst)
print ("CMD: {}".format(cmd))
#status = subprocess.call(cmd, shell=True)

# Determine which VMs did not make the grade

