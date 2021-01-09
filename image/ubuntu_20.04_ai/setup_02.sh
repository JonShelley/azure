#!/bin/bash

# Required OS: Ubuntu 20.04 LTS
sudo apt-get update
sudo apt install build-essential -y

### Install nvidia fabric manager (required for ND96asr_v4)
# <Download package from nvidia>
sudo apt install -y ./nvidia-fabricmanager-450_450.80.02-1_amd64.deb
sudo systemctl enable nvidia-fabricmanager
sudo systemctl start nvidia-fabricmanager

# Install NCCL
# <Download package from nvidia>
sudo dpkg -i nccl-repo-ubuntu2004-2.8.3-ga-cuda11.0_1-1_amd64.deb
sudo apt-key add /var/nccl-repo-2.8.3-ga-cuda11.0/7fa2af80.pub
sudo apt update
sudo apt install libnccl2 libnccl-dev

# Build the nccl tests
cd /opt/msft
HPCX_DIR=hpcx-v
git clone https://github.com/NVIDIA/nccl-tests.git
. /opt/${HPCX_DIR}*/hpcx-init.sh
hpcx_load
cd nccl-tests
make MPI=1 
