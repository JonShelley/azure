#!/bin/bash

# This must be done manually since you need to download NCCL from NVIDIA
if [ ! -f "/mnt/nccl-repo-ubuntu1804-2.8.3-ga-cuda11.0_1-1_amd64.deb" ]
then
    echo "Please run this after you have download nccl-repo-ubuntu1804-2.8.3-ga-cuda11.0_1-1_amd64.deb in /mnt"
    echo "You can find it at https://developer.nvidia.com/nccl/nccl-download"
    exit -1
fi



# Install NCCL
cd /mnt
sudo dpkg -i nccl-repo-ubuntu1804-2.8.3-ga-cuda11.0_1-1_amd64.deb
sudo apt-key add /var/nccl-repo-2.8.3-ga-cuda11.0/7fa2af80.pub
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

# Build the nccl tests
cd /opt/msft
HPCX_DIR=hpcx-v
git clone https://github.com/NVIDIA/nccl-tests.git
. /opt/${HPCX_DIR}*/hpcx-init.sh
hpcx_load
cd nccl-tests
make MPI=1
