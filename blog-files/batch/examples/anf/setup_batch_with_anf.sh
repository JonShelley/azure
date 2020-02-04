#!/bin/bash

# General variables
region=westus2
batch_rg=ex-batch-${region}
infra_rg=ex-infra-${region}
sub_id="<Replace with subscription id>"
vnet_2_octets="10.2"

# Batch variables
# Note: batch_name can only have 3-24 lowercase alphanumeric characters
batch_name=batchex${region}
storage_account_name=${batch_name}storage
storage_blob=batch
pool_id=HC
pool_vm_size=Standard_HC44rs

# ANF variables
anf_account_name="anf-ex-${region}"
anf_pool_name="anf-pools-${region}"
service_lvl="Premium"
apps_path=ex-apps
data_path=ex-data
scratch_path=ex-scratch

# Set az to the correct subscription
az account set -s $sub_id

# Create batch rg
az group create -l $region -n $batch_rg
az group create -l $region -n $infra_rg


#
# Setup storage account for batch
#
# Note: storage name can only have lowercase alphanumeric characters
az storage account create \
  -n $storage_account_name \
  -g $batch_rg \
  -l $region \
  --sku Standard_LRS \
  --encryption-services blob

# Find storage key
storage_key=$( az storage account keys list --account-name $storage_account_name --resource-group $batch_rg --query [0].value  --output tsv )
echo $storage_key

# Create storage container
az storage container create \
  --name batch \
  --account-name $storage_account_name \
  --account-key $storage_key


#
# Setup network
#
az network vnet create -g $infra_rg -n hpcvnet --address-prefix ${vnet_2_octets}.0.0/16 \
  --subnet-name default --subnet-prefix ${vnet_2_octets}.0.0/24
az network vnet subnet create -g $infra_rg --vnet-name hpcvnet -n compute \
  --address-prefixes ${vnet_2_octets}.2.0/24
az network vnet subnet create -g $infra_rg --vnet-name hpcvnet -n anf \
  --address-prefixes ${vnet_2_octets}.26.0/24 --delegations "Microsoft.Netapp/volumes"


#
# Setup ANF
#

az netappfiles account create \
  --resource-group $infra_rg \
  --account-name $anf_account_name \
  --location $region \
  --output table

# create pool
az netappfiles pool create \
  --resource-group $infra_rg \
  --account-name $anf_account_name \
  --location $region \
  --service-level $service_lvl \
  --size 4 \
  --pool-name $anf_pool_name \
  --output table

az netappfiles volume create \
  --resource-group $infra_rg \
  --account-name $anf_account_name \
  --location $region \
  --service-level $service_lvl \
  --usage-threshold 1000 \
  --file-path $apps_path \
  --pool-name $anf_pool_name \
  --volume-name apps \
  --vnet hpcvnet \
  --subnet anf  \
  --output table

az netappfiles volume create \
  --resource-group $infra_rg \
  --account-name $anf_account_name \
  --location $region \
  --service-level $service_lvl \
  --usage-threshold 2000 \
  --file-path $data_path \
  --pool-name $anf_pool_name \
  --volume-name data \
  --vnet hpcvnet \
  --subnet anf  \
  --output table

az netappfiles volume create \
  --resource-group $infra_rg \
  --account-name $anf_account_name \
  --location $region \
  --service-level $service_lvl \
  --usage-threshold 1000 \
  --file-path $scratch_path \
  --pool-name $anf_pool_name \
  --volume-name scratch \
  --vnet hpcvnet \
  --subnet anf  \
  --output table

anf_apps_ip=$( az netappfiles list-mount-targets \
  --resource-group $infra_rg \
  --account-name $anf_account_name \
  --pool-name $anf_pool_name \
  --volume-name apps \
  --query [0].ipAddress \
  --output tsv )

anf_data_ip=$( az netappfiles list-mount-targets \
  --resource-group $infra_rg \
  --account-name $anf_account_name \
  --pool-name $anf_pool_name \
  --volume-name data \
  --query [0].ipAddress \
  --output tsv )

anf_scratch_ip=$( az netappfiles list-mount-targets \
  --resource-group $infra_rg \
  --account-name $anf_account_name \
  --pool-name $anf_pool_name \
  --volume-name scratch \
  --query [0].ipAddress \
  --output tsv )

compute_subnet_id=$(az network vnet subnet list \
  -g $infra_rg \
  --vnet-name hpcvnet \
  --output tsv | grep compute | awk '{print $5}')

#
# Create a jump box with ANF mounted
#
cat << EOF > jb-init.txt
#!/bin/bash

#############################
# Cloud init script
#############################

yum install -y nfs-utils git

# Setup NFS
mkdir -p /apps
mkdir -p /data
mkdir -p /scratch
echo "${anf_apps_ip}:/$apps_path    /apps   nfs defaults 0 0" >> /etc/fstab
echo "${anf_data_ip}:/$data_path    /data   nfs defaults 0 0" >> /etc/fstab
echo "${anf_scratch_ip}:/$scratch_path       /scratch   nfs defaults 0 0" >> /etc/fstab
mount -a

# Configure ssh to not check hosts
echo "Host *" >> /etc/ssh/ssh_config
echo "    StrictHostKeyChecking no" >> /etc/ssh/ssh_config
echo "    UserKnownHostsFile /dev/null" >> /etc/ssh/ssh_config
echo "    LogLevel ERROR" >> /etc/ssh/ssh_config
echo "    ServerAliveInterval 60" >> /etc/ssh/ssh_config
echo "    ServerAliveCountMax 2" >> /etc/ssh/ssh_config
EOF

az vm create \
  -n ${batch_name}-jb \
  -g ${infra_rg} \
  --image OpenLogic:CentOS-CI:7-CI:latest \
  --size Standard_D16s_v3 \
  --ssh-key-value ~/.ssh/id_rsa.pub \
  --vnet-name hpcvnet \
  --subnet compute \
  --admin-username hpcuser \
  --custom-data jb-init.txt

#
# Setup key vault
#
az keyvault create \
  --location $region \
  --name ${batch_name}keyvault \
  --resource-group $batch_rg \
  --enabled-for-deployment true \
  --enabled-for-template-deployment true

# Add batch service to the keyvault policies
az keyvault set-policy \
  --name ${batch_name}keyvault \
  --resource-group $batch_rg \
  --secret-permissions get list set delete \
  --spn MicrosoftAzureBatch

#
# Setup batch account
#
az batch account create \
  -l $region \
  -n $batch_name \
  -g $batch_rg \
  --tags 'creator=joshelle' \
  --keyvault ${batch_name}keyvault \
  --storage-account $storage_account_name

# Login to batch account
az batch account login \
--name $batch_name \
--resource-group $batch_rg 

# Define start task
read -r -d '' START_TASK << EOM
bash -c \"#!/bin/bash\nhostname\nenv\npwd\"
EOM

# Define the batch pool
cat << EOF >  batchpool_create_${pool_id}.json
{
  "id": "$pool_id",
  "vmSize": "$pool_vm_size",
  "virtualMachineConfiguration": {
       "imageReference": {
            "publisher": "openlogic",
            "offer": "centos-hpc",
            "sku": "7.7",
            "version": "latest"
        },
        "nodeAgentSkuId": "batch.node.centos 7"
    },
  "targetDedicatedNodes": 3,
  "enableInterNodeCommunication": true,
  "networkConfiguration": {
    "subnetId": "$compute_subnet_id"
  },
  "maxTasksPerNode": 1,
  "taskSchedulingPolicy": {
    "nodeFillType": "Pack"
  },
  "mountConfiguration": [
      {
          "nfsMountConfiguration": {
              "source": "$anf_apps_ip:/${apps_path}",
              "relativeMountPath": "apps",
              "mountOptions": "-o rw,hard,rsize=65536,wsize=65536,vers=3,tcp"
          }
      },
      {
          "nfsMountConfiguration": {
              "source": "$anf_data_ip:/${data_path}",
              "relativeMountPath": "data",
              "mountOptions": "-o rw,hard,rsize=65536,wsize=65536,vers=3,tcp"
          }
      },
      {
          "nfsMountConfiguration": {
              "source": "$anf_scratch_ip:/${scratch_path}",
              "relativeMountPath": "scratch",
              "mountOptions": "-o rw,hard,rsize=65536,wsize=65536,vers=3,tcp"
          }
      }
  ],
  "startTask": {
    "commandLine":"${START_TASK}",
    "userIdentity": {
        "autoUser": {
          "scope":"pool",
          "elevationLevel":"admin"
        }
    },
    "maxTaskRetryCount":1,
    "waitForSuccess":true
  }
}
EOF

# Create the batch pool
az batch pool create \
--json-file batchpool_create_${pool_id}.json
