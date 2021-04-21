#!/bin/bash

# Required OS: CentOS 7.8
sudo yum install -y epel-release
sudo yum install -y git
cd /mnt/resource

### Install OFED
yum install -y createrepo
MLNX_OFED_DOWNLOAD_URL=https://azhpcstor.blob.core.windows.net/azhpc-images-store/MLNX_OFED_LINUX-5.2-2.2.3.0-rhel7.8-x86_64.tgz
TARBALL=$(basename ${MLNX_OFED_DOWNLOAD_URL})
MOFED_FOLDER=$(basename ${MLNX_OFED_DOWNLOAD_URL} .tgz)
wget $MLNX_OFED_DOWNLOAD_URL
tar zxvf ${TARBALL}

KERNEL=( $(rpm -q kernel | sed 's/kernel\-//g') )
KERNEL=${KERNEL[-1]}
# Uncomment the lines below if you are running this on a VM
RELEASE=( $(cat /etc/centos-release | awk '{print $4}') )
yum -y install http://olcentgbl.trafficmanager.net/centos/${RELEASE}/updates/x86_64/kernel-devel-${KERNEL}.rpm
yum install -y python-devel redhat-rpm-config rpm-build gcc
yum install -y kernel-devel-${KERNEL}
yum groupinstall -y "Development Tools"
yum install -y numactl \
    numactl-devel \
    libxml2-devel \
    byacc \
    environment-modules \
    python-devel \
    python-setuptools \
    gtk2 \
    atk \
    cairo \
    tcl \
    tk \
    m4 \
    texinfo \
    glibc-devel \
    glibc-static \
    libudev-devel \
    binutils \
    binutils-devel \
    selinux-policy-devel \
    kernel-headers \
    nfs-utils \
    fuse-libs \
    libpciaccess \
    cmake \
    libnl3-devel
./${MOFED_FOLDER}/mlnxofedinstall --kernel $KERNEL --kernel-sources /usr/src/kernels/${KERNEL} --add-kernel-support --skip-repo
sudo /etc/init.d/openibd restart

### Install HPC-X
cd /mnt
HPCX_URL=https://content.mellanox.com/hpc/hpc-x/v2.8.1/hpcx-v2.8.1-gcc-MLNX_OFED_LINUX-5.2-2.2.0.0-redhat7.8-x86_64.tbz
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
sudo systemctl restart waagent

# Install Cuda
mkdir /mnt/resource/tmp
cd /mnt/resource
wget https://developer.download.nvidia.com/compute/cuda/11.2.2/local_installers/cuda_11.2.2_460.32.03_linux.run
chmod +x cuda_11.2.2_460.32.03_linux.run
sudo ./cuda_11.2.2_460.32.03_linux.run --silent --tmpdir=/mnt/resource/tmp
echo 'export PATH=$PATH:/usr/local/cuda/bin' | sudo tee -a /etc/bash.bashrc
echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda/lib64' | sudo tee -a /etc/bash.bashrc

# Install the Nvidia driver and follow the prompts
cd /mnt/resource
NVIDIA_DRIVER_URL=https://download.nvidia.com/XFree86/Linux-x86_64/460.32.03/NVIDIA-Linux-x86_64-460.32.03.run
wget $NVIDIA_DRIVER_URL
chmod 755 NVIDIA-Linux-x86_64-460.32.03.run
sudo ./NVIDIA-Linux-x86_64-460.32.03.run --silent

### Install nvidia fabric manager (required for ND96asr_v4)
cd /mnt/resource
NVIDIA_FABRIC_MNGR_URL=http://developer.download.nvidia.com/compute/cuda/repos/rhel7/x86_64/nvidia-fabricmanager-460-460.32.03-1.x86_64.rpm
wget $NVIDIA_FABRIC_MNGR_URL
yum install -y nvidia-fabricmanager-460-460.32.03-1.x86_64.rpm
sudo systemctl enable nvidia-fabricmanager.service
sudo systemctl start nvidia-fabricmanager.service

# Install NV Peer Memory (GPU Direct RDMA)
cd /mnt/resource
git clone https://github.com/Mellanox/nv_peer_memory.git
cd nv_peer_memory*/
git checkout 1_1_0_Release
./build_module.sh 
rpmbuild --rebuild /tmp/nvidia_peer_memory-1.1-0.src.rpm
rpm -ivh /root/rpmbuild/RPMS/x86_64/nvidia_peer_memory-1.1-0.x86_64.rpm
sudo modprobe nv_peer_mem
lsmod | grep nv

sudo bash -c "cat > /etc/modules-load.d/nv_peer_mem.conf" <<'EOF'
nv_peer_mem
EOF

# Install gdrcopy
cd /mnt/resource
git clone https://github.com/NVIDIA/gdrcopy.git
sudo yum -y groupinstall 'Development Tools'
sudo yum -y install dkms rpm-build make check check-devel subunit subunit-devel
cd gdrcopy/packages
CUDA=/usr/local/cuda ./build-rpm-packages.sh
sudo rpm -Uvh gdrcopy-kmod-2.2-1dkms.noarch.rpm
sudo rpm -Uvh gdrcopy-2.2-1.x86_64.rpm
sudo rpm -Uvh gdrcopy-devel-2.2-1.noarch.rpm
cd ../tests/
make
sanity 
copybw
copylat

### Install DCGM
yum install -y dnf
dnf install -y 'dnf-command(config-manager)'
sudo dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel7/x86_64/cuda-rhel7.repo
sudo dnf clean expire-cache 
sudo dnf install -y datacenter-gpu-manager
sudo systemctl --now enable nvidia-dcgm
sudo systemctl status nvidia-dcgm
sudo nvidia-smi -pm 1

