#!/bin/bash
# Rename the cluster and add the new project to the Slurm cluster template:
cd ~/pyxis/templates
curl -L -o slurm-pyxis.txt -O 'https://raw.githubusercontent.com/Azure/cyclecloud-slurm/master/templates/slurm.txt'
sed -i 's/^.*\[cluster Slurm\]/[cluster Slurm-pyxis]/' slurm-pyxis.txt
sed -i '/^.*\[\[\[cluster-init cyclecloud\/slurm:default\]\]\]/i [[[cluster-init pyxis:default:1.0.0]]]' slurm-pyxis.txt

# Upload the template
cd ~/pyxis
cyclecloud import_template -f templates/slurm-pyxis.txt --force
