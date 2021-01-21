#!/bin/bash

# Required OS: Ubuntu 18.04 LTS

### Install OFED
DRIVER_URL=http://content.mellanox.com/ofed/MLNX_OFED-5.1-2.5.8.0/MLNX_OFED_LINUX-5.1-2.5.8.0-ubuntu18.04-x86_64.tgz
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
cd /mnt
wget https://us.download.nvidia.com/XFree86/Linux-x86_64/450.80.02/NVIDIA-Linux-x86_64-450.80.02.run
chmod 755 NVIDIA-Linux-x86_64-450.80.02.run
sudo ./NVIDIA-Linux-x86_64-450.80.02.run -s

# Install Cuda
cd /mnt
wget https://developer.download.nvidia.com/compute/cuda/11.0.3/local_installers/cuda_11.0.3_450.51.06_linux.run
chmod +x cuda_11.0.3_450.51.06_linux.run
sudo ./cuda_11.0.3_450.51.06_linux.run --silent --toolkit --samples
echo 'export PATH=$PATH:/usr/local/cuda/bin' | sudo tee -a /etc/bash.bashrc
echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda/lib64' | sudo tee -a /etc/bash.bashrc

### Install DCGM
DCGM_VERSION=2.0.10
wget --no-check-certificate https://developer.download.nvidia.com/compute/redist/dcgm/${DCGM_VERSION}/DEBS/datacenter-gpu-manager_${DCGM_VERSION}_amd64.deb
wget https://developer.download.nvidia.com/compute/redist/dcgm/${DCGM_VERSION}/DEBS/datacenter-gpu-manager_${DCGM_VERSION}_amd64.deb
sudo dpkg -i datacenter-gpu-manager_*.deb && \
sudo rm -f datacenter-gpu-manager_*.deb


### Install nvidia fabric manager (required for ND96asr_v4)
cd /mnt
wget http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/nvidia-fabricmanager-450_450.80.02-1_amd64.deb
sudo apt install -y ./nvidia-fabricmanager-450_450.80.02-1_amd64.deb
sudo systemctl enable nvidia-fabricmanager
sudo systemctl start nvidia-fabricmanager

### Install HPC-X
cd /mnt
HPCX_URL=https://bmhpcwus2.blob.core.windows.net/share/hpcx/hpcx-v2.7.3-gcc-MLNX_OFED_LINUX-5.1-2.4.6.0-ubuntu18.04-x86_64.tbz
wget $HPCX_URL
HPCX_FILE=$(basename $HPCX_URL) # Extract filename of tarball
tar -xvf $HPCX_FILE
HPCX_DIR=$( echo $HPCX_FILE | rev | cut -f 2- -d '.' | rev  )
sudo mv $HPCX_DIR /opt

# Install NV Peer Memory (GPU Direct RDMA)
sudo apt install -y dkms
cd /mnt
git clone https://github.com/Mellanox/nv_peer_memory.git
cd nv_peer_memory*/
./build_module.sh 
cd /mnt
mv /tmp/nvidia-peer-memory_1.1.orig.tar.gz /mnt/nvidia-peer-memory_1.1.orig.tar.gz
tar zxf /mnt/nvidia-peer-memory_1.1.orig.tar.gz
cd nvidia-peer-memory-1.1/
dpkg-buildpackage -us -uc 
sudo dpkg -i ../nvidia-peer-memory_1.1-0_all.deb 
sudo dpkg -i ../nvidia-peer-memory-dkms_1.1-0_all.deb 
lsmod | grep nv

# Install gdrcopy
sudo apt install -y check libsubunit0 libsubunit-dev build-essential devscripts debhelper check libsubunit-dev fakeroot
cd /mnt
git clone https://github.com/NVIDIA/gdrcopy.git
cd gdrcopy/packages/
CUDA=/usr/local/cuda ./build-deb-packages.sh 
sudo dpkg -i gdrdrv-dkms_2.1-1_amd64.deb 
sudo dpkg -i gdrcopy_2.1-1_amd64.deb 
cd ../tests/
make
sanity 
copybw
copylat
