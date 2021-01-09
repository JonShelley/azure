# Instrutions for building a Ubuntu 20.04 image

## Requirements:
The following files must be on the machine (obtain from nvidia) for the setup_02.sh script to work
- nvidia-fabricmanager-450_450.80.02-1_amd64.deb
- nccl-repo-ubuntu2004-2.8.3-ga-cuda11.0_1-1_amd64.deb

## Setup process
Deploy a ND96asr_v4 VM with Ubuntu 20.04 LTS. I used (Canonical:0001-com-ubuntu-server-focal:20_04-lts-gen2:latest)
1. Run setup_00.sh (This will reboot the VM when finished)
2. Log back into VM once rebooted
3. Run setup_01.sh and setup_02.sh (as root)
4. (Optional) Run setup_03.sh and setup_04.sh (as root)

## Create an image
On the VM:
1. sudo waagent -deprovision+user

On a bash terminal that is setup to use az cli for your subscription
1. Replace the following variable values in make_image.sh
VM=<vm_name>
rg=<vm_resource_group>
image_name=<new_image_name>

2. Run script
- ./make_image.sh

