#!/bin/bash

#### 
# Requirements: Ubuntu 18.04
####

# Create base directory
chmod -R 1777 /mnt
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
if [ ! -d "/mnt/resource/pyxis" ]; then
    cd /mnt/resource
    git clone https://github.com/NVIDIA/pyxis.git
    cd pyxis
    #git checkout v0.11.0
    git checkout v0.9.1
    sed -i "s/, libslurm-dev//g" debian/control
    make orig
    make deb
fi
sudo dpkg -i /mnt/resource/nvslurm-plugin-pyxis_*_amd64.deb
sudo mkdir -p /etc/slurm/plugstack.conf.d
echo "include /etc/slurm/plugstack.conf.d/*.conf" | sudo tee -a /etc/slurm/plugstack.conf
sudo ln -s /usr/share/pyxis/pyxis.conf /etc/slurm/plugstack.conf.d/pyxis.conf

# pyxis fstab
echo "/usr/share/pyxis/entrypoint /etc/rc.local none x-create=file,bind,ro,nosuid,nodev,noexec,nofail,silent" | sudo tee /etc/enroot/mounts.d/90-pyxis.fstab

# write entrypoint file
cat << END > /usr/share/pyxis/entrypoint
#! /bin/sh

# Copyright (c) 2020, NVIDIA CORPORATION. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -eu
exec "\$@"
END

sudo chmod 755 /usr/share/pyxis/entrypoint


cd -

# Install pmix
#cd /mnt/resource
#mkdir -p /opt/pmix/v3
#apt install -y libevent-dev
#mkdir -p pmix/build/v3 pmix/install/v3
#cd pmix
#git clone https://github.com/openpmix/openpmix.git source
#cd source/
#git branch -a
#git checkout v3.1
#git pull
#./autogen.sh
#cd ../build/v3/
#../../source/configure --prefix=/opt/pmix/v3
#make -j install >/dev/null
#cd ../../install/v3/

# Build PMIx
mkdir -p -m 1777 /shared/src
if [ ! -d /shared/src/pmix ]; then
    apt-get -y update && apt-get -y install --no-install-recommends \
        ca-certificates \
        devscripts      \
        fakeroot        \
        gnupg2

    mkdir -p /shared/src/pmix && cd /shared/src/pmix

    echo 'deb-src http://old-releases.ubuntu.com/ubuntu disco universe' > /etc/apt/sources.list.d/disco.list
    apt-get -y update && apt-get -y build-dep pmix
    apt-get -y source pmix

    cd pmix*/ && debuild -us -uc -G -i -tc

    cd ..
]
fi

# Install PMIx
apt install -y /shared/src/pmix/libpmix2_3.1.2-3_amd64.deb



# Install Docker and NVIDIA Docker                                                       
#### Install Docker                                                       
cd /mnt/resource
sudo apt install -y docker.io
sudo systemctl start docker
sudo docker run hello-world

#### Install NV-DOCKER                                                       
cd /mnt/resource
# If you have nvidia-docker 1.0 installed: we need to remove it and all existing GPU containers
docker volume ls -q -f driver=nvidia-docker | xargs -r -I{} -n1 docker ps -q -a -f volume={} | xargs -r docker rm -f
sudo apt-get purge -y nvidia-docker

# Add the package repositories
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | \
  sudo apt-key add -
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
  sudo tee /etc/apt/sources.list.d/nvidia-docker.list
sudo apt-get update
sudo apt-get install -y nvidia-docker2
sudo pkill -SIGHUP dockerd
sudo docker run --runtime=nvidia --rm nvidia/cuda:11.0-base nvidia-smi

# Adjust the kernel settings 
#echo 10 | sudo tee  /proc/sys/user/max_user_namespaces
#echo 10 | sudo tee  /proc/sys/user/max_mnt_namespaces

# Get the nephele project
if [ ! -d /mnt/resource/nephele ]; then
   cd /mnt/resource
   git clone https://github.com/NVIDIA/nephele.git
   cd nephele
   git checkout ubuntu-18.04
fi

# Configure SLURM
mkdir -m 1777 -p /mnt/resource/slurm

# Write PMIx settings for slurm
if [ -d "/etc/sysconfig" ]; then
cat << END >> /etc/sysconfig/slurmd

PMIX_MCA_ptl=^usock
PMIX_MCA_psec=none
PMIX_SYSTEM_TMPDIR=/var/empty
PMIX_MCA_gds=hash
HWLOC_COMPONENTS=-opencl
END
fi

# Update the config file to use prologues and epilogs.
sed -i "s/SchedulerParameters=max_switch_wait=24:00:00/SchedulerParameters=max_switch_wait=24:00:00,nohold_on_prolog_fail,Ignore_NUMA,enable_user_top/g" /etc/slurm/slurm.conf
sed -i "s/MpiDefault=none//g" /etc/slurm/slurm.conf
cat << END >> /etc/slurm/slurm.conf

### Updates for NGC integration

# MPI
MpiDefault=pmix
TmpFS=/mnt/resource/slurm

# Additional Scripts
Prolog=/sched/prolog.sh
Epilog=/sched/epilog.sh
UnkillableStepProgram=/sched/unkillable.sh

# HEALTHCHECKS
HealthCheckNodeState=IDLE
HealthCheckProgram=/sched/healthcheck.sh
HealthCheckInterval=3600
END

# Setup the additional scripts for Slurm
if [ ! -d /sched/prolog.d ]; then
    cp /mnt/resource/nephele/ansible/roles/slurm/templates/usr/lib/slurm/* /sched/.
    cp -r /mnt/resource/nephele/ansible/roles/slurm/templates/etc/slurm/prolog.d /sched/.
    cp -r /mnt/resource/nephele/ansible/roles/slurm/templates/etc/slurm/epilog.d /sched/.
fi

# Setup links for the prolog and epilog directories
ln -s /sched/prolog.d /etc/slurm/prolog.d
ln -s /sched/epilog.d /etc/slurm/epilog.d


# Restart Slurm
sudo systemctl restart slurmd
sudo systemctl restart slurmctld

