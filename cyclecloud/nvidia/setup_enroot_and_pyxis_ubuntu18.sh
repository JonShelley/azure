#!/bin/bash

# Create base directory
mkdir -m 1777 -p /mnt/resource
cd /mnt/resource

# Install Enroot from packages
# Ref: https://github.com/NVIDIA/enroot/blob/master/doc/installation.md
# For the latest version, refer to https://github.com/NVIDIA/enroot/blob/master/doc/installation.md#standard-flavor
# Debian-based distributions
arch=$(dpkg --print-architecture)
curl -fSsL -O https://github.com/NVIDIA/enroot/releases/download/v3.3.0/enroot_3.3.0-1_${arch}.deb
curl -fSsL -O https://github.com/NVIDIA/enroot/releases/download/v3.3.0/enroot+caps_3.3.0-1_${arch}.deb # optional
sudo apt install -y ./*.deb
enroot version

mkdir -m 1777 -p /mnt/resource/enroot/tmp
echo "@reboot mkdir -m 1777 -p /mnt/resource/enroot" | crontab
sudo crontab -l

# Setup the enroot config file
cat << END >> /etc/enroot/enroot.conf
ENROOT_RUNTIME_PATH=/mnt/resource/enroot/\$UID/run    # Default: /run/user/\$UID/enroot
ENROOT_CACHE_PATH=/mnt/resource/enroot/\$UID/.cache # Default: \$HOME/.cache/enroot
ENROOT_DATA_PATH=/mnt/resource/enroot/\$UID/.data  # Default: \$HOME/.local/share/enroot
ENROOT_TEMP_PATH=/mnt/resource/enroot/tmp              # Default: /tmp
ENROOT_SQUASH_OPTIONS="-noI -noD -noF -noX -no-duplicates"
ENROOT_MOUNT_HOME=yes
ENROOT_RESTRICT_DEV=yes
ENROOT_ROOTFS_WRITABLE yes
END

# Install Pyxis
cd /mnt/resource
git clone https://github.com/NVIDIA/pyxis.git
cd pyxis
git checkout v0.11.0
make orig
make deb
sudo dpkg -i ../nvslurm-plugin-pyxis_*_amd64.deb
sudo ln -s /usr/share/pyxis/pyxis.conf /etc/slurm-llnl/plugstack.conf.d/pyxis.conf
sudo systemctl restart slurmd
cd ..

# Install pmix
cd /mnt/resource
mkdir -p /opt/pmix/v3
apt install -y libevent-dev
mkdir -p pmix/build/v3 pmix/install/v3
cd pmix
git clone https://github.com/openpmix/openpmix.git source
cd source/
git branch -a
git checkout v3.1
git pull
./autogen.sh
cd ../build/v3/
../../source/configure --prefix=/opt/pmix/v3
make -j install >/dev/null
cd ../../install/v3/

# Install Docker and NVIDIA Docker                                                       
#### Install Docker                                                       
cd /mnt/resource
sudo apt install -y docker.io
sudo systemctl start docker
sudo docker run hello-world

#### Install NV-DOCKER                                                       
cd /mnt/resource
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add - distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
sudo apt-get update
sudo apt-get install -y nvidia-docker2
sudo pkill -SIGHUP dockerd
sudo docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi

# Adjust the kernel settings 
#echo 10 | sudo tee  /proc/sys/user/max_user_namespaces
#echo 10 | sudo tee  /proc/sys/user/max_mnt_namespaces
