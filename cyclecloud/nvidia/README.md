# Setup CycleCloud to run NGC containers using Slurm, Pyxis, and Enroot

## Requirements
* CycleCloud 8.1+

## Deploy the cyclecloud server and ssh into the VM
_Note: Please follow [Cycle Cloud Quickstart guide](https://docs.microsoft.com/en-us/azure/cyclecloud/qs-install-marketplace?view=cyclecloud-8) with the below recommendations_

__Recommendations:__
- Create a new resource group (i.e cc-manager) and then select your newly created resource group and create your cyclecloud server.
- Select Azure CycleCloud 8.1(or higher) and click create
    - Fill out the requested information and deploy your CycleCloud server.
- Server size: D4s_v4 (Recommended)
- Create a uniquely named storage account (i.e. cc-storage-name) in your newly created resource group.

Once deployed:
 - Go to the newly created Cycle Cloud server and record the ip address. 
 - Login to the Cycle Cloud server in your Web Browser and do the initial setup of your Cycle Cloud server
 - ssh into your cyclecloud server (i.e. ssh azureuser@<cc-srv-ip>) and follow the steps below

### Download and setup the project
- cyclecloud initialize
  - follow the command prompts
- wget https://bmhpcwus2.blob.core.windows.net/share/cc-slurm/slurm-custom-v0.6.tgz
- tar -xzvf slurm-custom-v0.6.tgz
- cd slurm-custom
- cyclecloud locker list ( To see what lockers you can upload to )
- cyclecloud project upload "\<your-cyclecloud-locker\>"
- cd templates
- cyclecloud import_template slurm-ngc -f ./slurm-custom.txt -c slurm --force
 

_Note:_ At this point you are ready to deploy your cyclecloud cluster

## Deploy your cyclecloud cluster
Open a web browser and go to your cyclecloud server (https://cc-srv-ip)

Once you have logged in to your cyclecloud server:
_Note:_ If this is your first time logging in you will need to fill out some information before you can proceed

Use the following link to learn more about creating a cluster (https://docs.microsoft.com/en-us/azure/cyclecloud/how-to/create-cluster?view=cyclecloud-8)

_Note: Only tested with Ubuntu-HPC 18.04 marketplace image_
 
 Tips: 
 - In the _Schedulers_ section, select slurm-ngc
 - Change HPC VM Type to use ND
   - In the SKU Search bar type ND then select either ND96asr\_v4, or ND96amsr_A100_v4.
  - Update value from Max HPC Cores to the desired # of VMs * # of cores/VM
 - In the "Advanced Settings" tab
   - Set the scheduler OS to use a custom image
     - microsoft-dsvm:ubuntu-hpc:1804:latest
   - Set the HPC OS to use a custom image
     - microsoft-dsvm:ubuntu-hpc:1804:latest
   - If you plan to use the HTC partitions, I would recommned that you use the same OS image as the others
 

 ## Testing out the deployment
 Once the Scheduler and Compute VMs have been provisioned, ssh into the scheduler and follow the instructions below
 - mkdir -p /shared/data
 - cd /shared/data
 - git clone https://github.com/JonShelley/azure
 
At this point the system should be ready to run some quick tests to verify that the system is working as expected
 - [HPL](https://github.com/JonShelley/azure/tree/master/benchmarking/NDv4/cc-slurm-ngc/hpl)
 - [NCCL - All Reduce](https://github.com/JonShelley/azure/tree/master/benchmarking/NDv4/cc-slurm-ngc/nccl)
 - [Utility scripts](https://github.com/JonShelley/azure/tree/master/benchmarking/NDv4/cc-slurm-ngc/util_scripts)

