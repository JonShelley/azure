#!/bin/bash

# Required OS: CentOS 7.8
sudo apt-get update
sudo apt install build-essential -y

### Install NVtop
cd /mnt/resource
wget https://cmake.org/files/v3.6/cmake-3.6.2.tar.gz
tar -zxvf cmake-3.6.2.tar.gz
cd cmake-3.6.2
sudo ./bootstrap --prefix=/usr/local
sudo make
sudo make install
#sudo apt install -y cmake libncurses5-dev libncursesw5-dev git
cd /mnt/resource
sudo dnf install -y cmake ncurses-devel git
git clone https://github.com/Syllo/nvtop.git
mkdir -p nvtop/build && cd nvtop/build
cmake ..
make
sudo make install

### Install Linux tools
sudo yum install -y hwloc numactl iperf fio
