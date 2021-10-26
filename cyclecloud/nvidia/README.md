# Setup CycleCloud to run NGC containers using Slurm, Pyxis, and Enroot

## Requirements
* CycleCloud 8.1+
* Ubuntu 18.04 for the deployed cluster (Will add 20.04 later)
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

### Download and setup the project
- wget https://bmhpcwus2.blob.core.windows.net/share/cc-slurm/slurm-custom-v0.6.tgz
- tar -xzvf slurm-custom-v0.6.tgz
- cd slurm-custom
- cyclecloud locker list ( To see what lockers you can upload to )
- cyclecloud project upload <your-cyclecloud-locker>
- cd templates
- cyclecloud import_template slurm-ngc -f ./slurm-custom.txt -c slurm --force
 

_Note:_ At this point you are ready to deploy your cyclecloud cluster

## Deploy your cyclecloud cluster
Open a web browser and go to your cyclecloud server (https://cc-srv-ip)

Once you have logged in to your cyclecloud server:
_Note:_ If this is your first time logging in you will need to fill out some information before you can proceed

Use the following link to learn more about creating a cluster (https://docs.microsoft.com/en-us/azure/cyclecloud/how-to/create-cluster?view=cyclecloud-8) 
 Tips: 
 - In the _Schedulers_ section, select slurm-ngc
 - Change HPC VM Type to use GPUs
   - In the SKU Search bar type ND then select either ND96asr\_v4, or ND96amsr_A100_v4.
  - Update value from Max HPC Cores to the desired # of VMs * # of cores/VM

 ## Update the VMs once provisioned
 Once the Scheduler and Compute VMs have been provisioned
 - mkdir -p /shared/data
 - cd /shared/data
 - git clone https://github.com/JonShelley/azure
 
At this point the system should be ready to run some quick tests to verify that the system is working as expected
 - [HPL](https://github.com/JonShelley/azure/tree/master/benchmarking/NDv4/cc-slurm-ngc/hpl)
 - [NCCL - All Reduce](https://github.com/JonShelley/azure/tree/master/benchmarking/NDv4/cc-slurm-ngc/nccl)
 - [Utility scripts](https://github.com/JonShelley/azure/tree/master/benchmarking/NDv4/cc-slurm-ngc/util_scripts)

