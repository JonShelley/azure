# Setup CycleCloud to run NGC containers using Slurm, Pyxis, and Enroot

## Requirements
* CycleCloud 8.1+
* Ubuntu 18.04 (Will add 20.04 later)
* Python 3
* CentOS VM (Can be the cyclecloud srv) to build Slurm and Ubuntu 18.04 VM to convert the rpms to .deb files
* A bit of patience. :)

## Deploy the cyclecloud server and ssh into the VM
Go to the Azure portal and create your cyclecloud server. I recommend that you create a new resource group (i.e cc-manager) and then select your newly created resource group and create your cyclecloud server.
- Click the +Create button.
 - In the search box type "Azure CycleCloud" and click on it.
 - Select Azure CycleCloud 8.1 and click create
  - Fill out the requested information and deploy your CycleCloud server. 
Once deployed go to the new resource and record the ip address. Now ssh into your cyclecloud server (i.e. ssh azureuser@<cc-srv-ip>) and follow the steps below

### Install Python 3
- sudo yum install -y python3

### Download the project
- cyclecloud project fetch https://github.com/Azure/cyclecloud-slurm/releases/2.4.6 cc-slurm-nvidia
- cd cc-slurm-nvidia/specs/default/cluster-init/files
- Modify 00-build-slurm.sh
 - yum config-manager --set-enabled PowerTools (Line 29: powertools does not work and needs to be camel cased)
- Add the following after rpmbuild (line 41)
 - --define '_with_pmix --with-pmix=/opt/pmix/v3'
- Add the line below after rpmbuild (line 42)
 - exit 0

### Install packages required for PMIx
- yum groupinstall -y "Development Tools"

### Put the following lines in a script to build and install PMIx (build_pmix.sh)
#!/bin/bash
  
cd ~/
mkdir -p /opt/pmix/v3
apt install -y libevent-dev
mkdir -p pmix/build/v3 pmix/install/v3
cd pmix
git clone https://github.com/openpmix/openpmix.git source
cd source/
git branch -a
git checkout v3.1
git pull
./autogen.sh
cd ../build/v3/
../../source/configure --prefix=/opt/pmix/v3
make -j install >/dev/null
cd ../../install/v3/

### Install PMIx
- chmod 755 build_pmix.sh
- sudo ./build_pmix.sh

### Build Slurm
- cd cc-slurm-nvidia/specs/default/cluster-init/files
- sudo ./00-build-slurm.sh

## Deploy the Ubuntu 18.04 VM to convert the rpms to .debs
### Download the cli from the cyclecloud server
- sudo apt -y update (Ubuntu only)
- sudo apt install -y python3-venv (Ubuntu only)
- sudo apt install -y zip libtool build-essential flex libevent-dev (Ubuntu only)
- wget --no-check-certificate https://13.64.134.151/static/tools/cyclecloud-cli.zip
- unzip cyclecloud-cli.zip
- cd cyclecloud-cli-installer
- ./install.sh

### Initialized the cyclecloud cli
- cyclecloud initialize

### Fetch the cyclecloud project
- cyclecloud project fetch https://github.com/Azure/cyclecloud-slurm/releases/2.4.6 cc-slurm-nvidia

### Copy over the files from the CentOS CycleCloud Server to the Ubuntu Box
- sudo scp -r -i <id_rsa> /root/rpmbuild azureuser@<cyclecloud srv ip>:

### Convert rpms to .deb files
- cd ~/cc-slurm-nvidia/specs/default/cluster-init/files
- sudo ./01-build-debs.sh

### Copy the .deb files to correct directory and then upload them
- cp ~/rpmbuild/RPMS/x86\_64/\*.deb ~/cc-slurm-nvidia/blobs/.
- cyclecloud project upload <cc-storage-account>
 - To find the available cc-storage-accounts run
  - cyclecloud locker list

### Update the Slurm template files and upload them
_Note:_ 2.4.6 is the cyclecloud slurm release version used when the project was fetched.
- cd ~/cc-slurm-nvidia/templates
- sed -i "s/cyclecloud\/slurm:default/slurm:default:2.4.6/g" slurm.txt
- sed -i "s/cyclecloud\/slurm:scheduler/slurm:scheduler:2.4.6/g" slurm.txt
- sed -i "s/cyclecloud\/slurm:execute/slurm:execute:2.4.6/g" slurm.txt
- cyclecloud import\_template slurm-ngc -f ./slurm.txt -c slurm

_Note:_ At this point you are ready to deploy your cyclecloud cluster

## Deploy your cyclecloud cluster
Open a web browser and go to your cyclecloud server (https://cc-srv-ip)

Once you have logged in to your cyclecloud server:
_Note:_ If this is your first time logging in you will need to fill out some information before you can proceed
- Select the "+" button (in the bottom left corner) to create your new cluster- In the _Schedulers_ section, select slurm-ngc
 - About:
  - Add the desired cluster name
 - Required Settings:
  - Select the desired region
  - Change HPC VM Type to use GPUs
   - In the SKU Search bar type ND then select either ND40rs\_v2 or ND96asr\_v4
  - Update value from Max HPC Cores to the desired # of VMs * # of cores/VM
  - ....




