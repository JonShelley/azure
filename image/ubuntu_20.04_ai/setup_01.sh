#!/bin/bash

# Required OS: Ubuntu 20.04 LTS
sudo apt-get update
sudo apt install build-essential -y

### Install IB
#DRIVER_URL=https://content.mellanox.com/ofed/MLNX_OFED-5.1-2.5.8.0/MLNX_OFED_LINUX-5.1-2.5.8.0-ubuntu20.04-x86_64.tgz
DRIVER_URL=https://content.mellanox.com/ofed/MLNX_OFED-5.2-1.0.4.0/MLNX_OFED_LINUX-5.2-1.0.4.0-ubuntu20.04-x86_64.tgz
wget $DRIVER_URL
DRIVER_FILE=$(basename $DRIVER_URL) # Extract filename of tarball
tar xzf $DRIVER_FILE           # Extract tarball
DRIVER_ROOT=${DRIVER_FILE%.*}       # Extract root without .tgz

sudo ./$DRIVER_ROOT/mlnxofedinstall --add-kernel-support
sudo /etc/init.d/openibd restart

# Enable RDMA in waagent
sudo sed -i -e 's/# OS.EnableRDMA=y/OS.EnableRDMA=y/g' /etc/waagent.conf
echo "Extensions.GoalStatePeriod=300" | sudo tee -a /etc/waagent.conf
echo "OS.EnableFirewallPeriod=300" | sudo tee -a /etc/waagent.conf
echo "OS.RemovePersistentNetRulesPeriod=300" | sudo tee -a /etc/waagent.conf
echo "OS.RootDeviceScsiTimeoutPeriod=300" | sudo tee -a /etc/waagent.conf
echo "OS.MonitorDhcpClientRestartPeriod=60" | sudo tee -a /etc/waagent.conf
echo "Provisioning.MonitorHostNamePeriod=60" | sudo tee -a /etc/waagent.conf
sudo systemctl restart walinuxagent

# Install the Nvidia driver and follow the prompts
sudo apt install -y nvidia-driver-450

# Install Cuda
wget https://developer.download.nvidia.com/compute/cuda/11.0.3/local_installers/cuda_11.0.3_450.51.06_linux.run
chmod +x cuda_11.0.3_450.51.06_linux.run
sudo ./cuda_11.0.3_450.51.06_linux.run --silent --toolkit --samples  #(Make sure not to install the nvidia driver otherwise the fabric manager will not work)
echo 'export PATH=$PATH:/usr/local/cuda/bin' | sudo tee -a /etc/bash.bashrc
echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda/lib64' | sudo tee -a /etc/bash.bashrc

### Install DCGM
DCGM_VERSION=2.0.10
wget --no-check-certificate https://developer.download.nvidia.com/compute/redist/dcgm/${DCGM_VERSION}/DEBS/datacenter-gpu-manager_${DCGM_VERSION}_amd64.deb
wget https://developer.download.nvidia.com/compute/redist/dcgm/${DCGM_VERSION}/DEBS/datacenter-gpu-manager_${DCGM_VERSION}_amd64.deb
sudo dpkg -i datacenter-gpu-manager_*.deb && \
sudo rm -f datacenter-gpu-manager_*.deb

### Install HPC-X
cd /tmp
#HPCX_URL=https://bmhpcwus2.blob.core.windows.net/share/hpcx/hpcx-v2.7.3-gcc-MLNX_OFED_LINUX-5.1-2.4.6.0-ubuntu20.04-x86_64.tbz
HPCX_URL=https://content.mellanox.com/hpc/hpc-x/v2.8/hpcx-v2.8.0-gcc-MLNX_OFED_LINUX-5.2-1.0.4.0-ubuntu20.04-x86_64.tbz
wget $HPCX_URL
HPCX_FILE=$(basename $HPCX_URL) # Extract filename of tarball
tar -xjvf $HPCX_FILE
HPCX_DIR=$( echo $HPCX_FILE | rev | cut -f 2- -d '.' | rev  )
sudo mv $HPCX_DIR /opt

