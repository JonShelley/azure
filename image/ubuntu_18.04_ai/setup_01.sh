#!/bin/bash

# Required OS: Ubuntu 18.04 LTS

### Install OFED
DRIVER_URL=https://azhpcstor.blob.core.windows.net/azhpc-images-store/MLNX_OFED_LINUX-5.2-2.2.3.0-ubuntu18.04-x86_64.tgz
wget $DRIVER_URL
DRIVER_FILE=$(basename $DRIVER_URL) # Extract filename of tarball
tar xzf $DRIVER_FILE           # Extract tarball
DRIVER_ROOT=${DRIVER_FILE%.*}       # Extract root without .tgz

sudo ./$DRIVER_ROOT/mlnxofedinstall --add-kernel-support
sudo /etc/init.d/openibd restart

### Install HPC-X
cd /mnt
HPCX_URL=https://content.mellanox.com/hpc/hpc-x/v2.8.1/hpcx-v2.8.1-gcc-MLNX_OFED_LINUX-5.2-2.2.0.0-ubuntu18.04-x86_64.tbz
wget $HPCX_URL
HPCX_FILE=$(basename $HPCX_URL) # Extract filename of tarball
tar -xvf $HPCX_FILE
HPCX_DIR=$( echo $HPCX_FILE | rev | cut -f 2- -d '.' | rev  )
sudo mv $HPCX_DIR /opt

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
DRIVER_VERSION=460.32.03
wget https://us.download.nvidia.com/XFree86/Linux-x86_64/${DRIVER_VERSION}/NVIDIA-Linux-x86_64-${DRIVER_VERSION}.run
chmod 755 NVIDIA-Linux-x86_64-${DRIVER_VERSION}.run
sudo ./NVIDIA-Linux-x86_64-${DRIVER_VERSION}.run -s

# Install Cuda
mkdir -p /mnt/tmp
cd /mnt
wget https://developer.download.nvidia.com/compute/cuda/11.2.2/local_installers/cuda_11.2.2_460.32.03_linux.run
chmod +x cuda_11.*_linux.run
sudo ./cuda_11.*_linux.run --silent --toolkit --samples --tmpdir=/mnt/tmp --installpath=/usr/local/cuda
echo 'export PATH=$PATH:/usr/local/cuda/bin' | sudo tee -a /etc/bash.bashrc
echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda/lib64' | sudo tee -a /etc/bash.bashrc

### Install DCGM
DCGM_VERSION=2.0.10
wget --no-check-certificate https://developer.download.nvidia.com/compute/redist/dcgm/${DCGM_VERSION}/DEBS/datacenter-gpu-manager_${DCGM_VERSION}_amd64.deb
wget https://developer.download.nvidia.com/compute/redist/dcgm/${DCGM_VERSION}/DEBS/datacenter-gpu-manager_${DCGM_VERSION}_amd64.deb
sudo dpkg -i datacenter-gpu-manager_*.deb && \
sudo rm -f datacenter-gpu-manager_*.deb

# Create service for dcgm to launch on bootup
sudo bash -c "cat > /etc/systemd/system/dcgm.service" <<'EOF'
[Unit]
Description=DCGM service

[Service]
User=root
PrivateTmp=false
ExecStart=/usr/bin/nv-hostengine -n
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl enable dcgm
sudo systemctl start dcgm



### Install nvidia fabric manager (required for ND96asr_v4)
cd /mnt
wget http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/nvidia-fabricmanager-460_460.32.03-1_amd64.deb
sudo apt install -y ./nvidia-fabricmanager-460_460.32.03-1_amd64.deb
sudo systemctl enable nvidia-fabricmanager
sudo systemctl start nvidia-fabricmanager

# Install NV Peer Memory (GPU Direct RDMA)
sudo apt install -y dkms libnuma-dev
cd /mnt
git clone https://github.com/Mellanox/nv_peer_memory.git
cd nv_peer_memory*/
git checkout 1_1_0_Release
./build_module.sh 
cd /mnt
mv /tmp/nvidia-peer-memory_1.1.orig.tar.gz /mnt/nvidia-peer-memory_1.1.orig.tar.gz
tar zxf /mnt/nvidia-peer-memory_1.1.orig.tar.gz
cd nvidia-peer-memory-1.1/
dpkg-buildpackage -us -uc 
sudo dpkg -i ../nvidia-peer-memory_1.1-0_all.deb 
sudo dpkg -i ../nvidia-peer-memory-dkms_1.1-0_all.deb 
sudo modprobe nv_peer_mem
lsmod | grep nv

sudo bash -c "cat > /etc/modules-load.d/nv_peer_mem.conf" <<'EOF'
nv_peer_mem
EOF

# Install gdrcopy
sudo apt install -y check libsubunit0 libsubunit-dev build-essential devscripts debhelper check libsubunit-dev fakeroot
cd /mnt
git clone https://github.com/NVIDIA/gdrcopy.git
cd gdrcopy/packages/
CUDA=/usr/local/cuda ./build-deb-packages.sh 
sudo dpkg -i gdrdrv-dkms_2.2-1_amd64.deb 
sudo dpkg -i gdrcopy_2.2-1_amd64.deb 
cd ../tests/
make
sanity 
copybw
copylat
