#!/bin/bash

# Required OS: Ubuntu 20.04 LTS
sudo apt-get update
sudo apt install build-essential -y

# Install NV Peer Memory (GPU Direct RDMA)
sudo apt install -y dkms
cd /mnt
git clone https://github.com/Mellanox/nv_peer_memory.git
cd nv_peer_memory*/
./build_module.sh
cd /mnt
mv /tmp/nvidia-peer-memory_1.1.orig.tar.gz nvidia-peer-memory_1.1.orig.tar.gz
tar zxf nvidia-peer-memory_1.1.orig.tar.gz
cd nvidia-peer-memory-1.1/
dpkg-buildpackage -us -uc
sudo dpkg -i ../nvidia-peer-memory_1.1-0_all.deb
sudo dpkg -i ../nvidia-peer-memory-dkms_1.1-0_all.deb
lsmod | grep nv
echo "nv_peer_mem" | sudo tee -a /etc/modules

# Install gdrcopy
sudo apt install -y check libsubunit0 libsubunit-dev build-essential devscripts debhelper check libsubunit-dev fakeroot
cd /tmp
git clone https://github.com/NVIDIA/gdrcopy.git
cd gdrcopy/packages/
#wget http://developer.download.nvidia.com/compute/cuda/11.0.2/local_installers/cuda_11.0.2_450.51.05_linux.run
#chmod +x cuda_11.0.2_450.51.05_linux.run
#sudo ./cuda_11.0.2_450.51.05_linux.run
CUDA=/usr/local/cuda ./build-deb-packages.sh
sudo dpkg -i gdrdrv-dkms_2.1-1_amd64.deb
sudo dpkg -i gdrcopy_2.1-1_amd64.deb
cd ../tests/
make
sanity
copybw
copylat

### Install NVtop
sudo apt install -y cmake libncurses5-dev libncursesw5-dev git
cd /mnt
git clone https://github.com/Syllo/nvtop.git
mkdir -p nvtop/build && cd nvtop/build
cmake ..
make
sudo make install

### Install Linux tools
sudo apt install -y hwloc numactl iperf fio
