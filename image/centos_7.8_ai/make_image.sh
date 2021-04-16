#!/bin/bash

VM=<vm_name>
rg=<vm_resource_group>
image_name=<new_image_name>

az vm deallocate --resource-group $rg    --name $VM
az vm generalize --resource-group $rg    --name $VM
az image create --hyper-v-generation V2 --resource-group $rg --source $VM --name $image_name
