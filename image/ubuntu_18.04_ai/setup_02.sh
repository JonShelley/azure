#!/bin/bash

# This must be done manually since you need to download NCCL from NVIDIA
if [ ! -f "/mnt/nccl-repo-ubuntu1804-2.7.8-ga-cuda11.0_1-1_amd64.deb" ]
then
    echo "Please run this after you have download nccl-repo-ubuntu1804-2.7.8-ga-cuda11.0_1-1_amd64.deb in /mnt"
    exit -1
fi



# Install NCCL
cd /mnt
sudo dpkg -i nccl-repo-ubuntu1804-2.7.8-ga-cuda11.0_1-1_amd64.deb
sudo apt-key add /var/nccl-repo-2.7.8-ga-cuda11.0/7fa2af80.pub
sudo apt update
sudo apt install libnccl2 libnccl-dev

# Install the nccl rdma sharp plugin
cd /mnt
mkdir -p /usr/local/nccl-rdma-sharp-plugins
sudo apt install -y zlib1g-dev
git clone https://github.com/Mellanox/nccl-rdma-sharp-plugins.git
cd nccl-rdma-sharp-plugins
git checkout v2.0.x-ar
./autogen.sh
./configure --prefix=/usr/local/nccl-rdma-sharp-plugins --with-cuda=/usr/local/cuda
make
sudo make install
