#!/bin/bash

# Install Enroot from packages
# Ref: https://github.com/NVIDIA/enroot/blob/master/doc/installation.md
# For the latest version, refer to https://github.com/NVIDIA/enroot/blob/master/doc/installation.md#standard-flavor
# RHEL-based distributions
arch=$(uname -m)
sudo yum install -y epel-release # required on some distributions
sudo yum install -y https://github.com/NVIDIA/enroot/releases/download/v3.3.0/enroot-3.3.0-1.el7.${arch}.rpm
sudo yum install -y https://github.com/NVIDIA/enroot/releases/download/v3.3.0/enroot+caps-3.3.0-1.el7.${arch}.rpm # optional
enroot version

mkdir -m 1777 -p /mnt/resource/enroot
echo "@reboot mkdir -m 1777 -p /mnt/resource/enroot" | crontab
sudo crontab -l

# Setup the enroot config file
cat << END >> /etc/enroot/enroot.conf
ENROOT_RUNTIME_PATH    /mnt/resource/enroot/\$UID/run    # Default: /run/user/\$UID/enroot
ENROOT_CONFIG_PATH     \$HOME/.config/enroot    # Default: \$HOME/.config/enroot
ENROOT_CACHE_PATH      /mnt/resource/enroot/\$UID/.cache # Default: \$HOME/.cache/enroot
ENROOT_DATA_PATH       /mnt/resource/enroot/\$UID/.data  # Default: \$HOME/.local/share/enroot
ENROOT_TEMP_PATH       /mnt/resource/enroot              # Default: /tmp
ENROOT_ROOTFS_WRITABLE yes
END

# Install Pyxis
git clone https://github.com/NVIDIA/pyxis.git

cd pyxis
git checkout v0.11.0
make rpm
sudo rpm -i nvslurm-plugin-pyxis-*-1.el7.x86_64.rpm
sudo mkdir -p /etc/slurm/plugstack.conf.d
sudo ln -s /usr/share/pyxis/pyxis.conf /etc/slurm/plugstack.conf
sudo systemctl restart slurmd
cd ..

# Install Docker and NVIDIA Docker                                                       
#### Install Docker                                                       
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo  https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y docker-ce docker-ce-cli containerd.io
sudo systemctl start docker
sudo docker run hello-world

#### Install NV-DOCKER                                                       
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.repo | sudo tee /etc/yum.repos.d/nvidia-docker.repo                                                       
sudo yum clean expire-cache
sudo yum install -y nvidia-docker2
systemctl restart docker
sudo docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi

# Adjust the kernel settings 
echo 10 | sudo tee  /proc/sys/user/max_user_namespaces
echo 10 | sudo tee  /proc/sys/user/max_mnt_namespaces
