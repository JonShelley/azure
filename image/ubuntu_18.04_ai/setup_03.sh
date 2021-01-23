#!/bin/bash

# Required OS: Ubuntu 20.04 LTS
sudo apt-get update
sudo apt install build-essential -y

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
