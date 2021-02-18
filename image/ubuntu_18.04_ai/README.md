# Instrutions for building a Ubuntu 18.04 image


## Setup process
Deploy a ND96asr_v4 VM with Ubuntu 18.04 LTS. I used (Canonical:UbuntuServer:18_04-lts-gen2:latest)
 1. Run setup_00.sh (as root. Note: This will reboot the VM when finished)
 1. Log back into VM once rebooted
 1. Run setup_01.sh (as root)
 1. Run setup_02.sh (as root)
 1. (Optional) Run setup_03.sh (as root)
  - This will install nvtop and a few other useful packages

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

