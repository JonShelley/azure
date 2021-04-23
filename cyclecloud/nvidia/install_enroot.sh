#!/bin/bash
# Ref: https://github.com/NVIDIA/enroot/blob/master/doc/installation.md

# Debian-based distributions
set -ex
apt update
sudo apt install -y git gcc make libcap2-bin libtool automake
sudo apt install -y curl gawk jq squashfs-tools parallel

# Install fuse-overlayfs # NOTE: With Ubuntu 20.04 or later, you can install fuse-overlayfs by running ‘apt update && apt install fuse-overlayfs’ instead. 
# Install buildah (Prerequisite to fuse-overlayfs)
# Ref: https://github.com/containers/buildah/blob/master/install.md
sudo apt-get -y install software-properties-common
sudo add-apt-repository -y ppa:alexlarsson/flatpak
sudo add-apt-repository -y ppa:gophers/archive
sudo apt-add-repository -y ppa:projectatomic/ppa
sudo apt-get -y -qq update
sudo apt-get -y install bats btrfs-tools git libapparmor-dev libdevmapper-dev libglib2.0-dev libgpgme11-dev libseccomp-dev libselinux1-dev skopeo-containers go-md2man
sudo apt-get -y install golang-1.13 buildah

# Install fuse-overlayfs from source
# Ref: https://github.com/containers/fuse-overlayfs
cd /mnt
git clone https://github.com/containers/fuse-overlayfs.git
cd fuse-overlayfs
buildah bud -v $PWD:/build/fuse-overlayfs -t fuse-overlayfs -f ./Containerfile.static.ubuntu . # NOTE: Make sure to include '.' at the end. 
cp fuse-overlayfs /usr/bin/

# Install Nvidia container tools
# Ref: https://github.com/NVIDIA/libnvidia-container
DIST=$(. /etc/os-release; echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/libnvidia-container/gpgkey | apt-key add -
curl -s -L https://nvidia.github.io/libnvidia-container/$DIST/libnvidia-container.list | tee /etc/apt/sources.list.d/libnvidia-container.list
apt-get update
apt install -y libnvidia-container1 libnvidia-container-tools pigz squashfuse

# Install Enroot from packages
cd /mnt
arch=$(dpkg --print-architecture)
curl -fSsL -O https://github.com/NVIDIA/enroot/releases/download/v3.2.0/enroot_3.2.0-1_${arch}.deb
curl -fSsL -O https://github.com/NVIDIA/enroot/releases/download/v3.2.0/enroot+caps_3.2.0-1_${arch}.deb 
apt install -y ./*.deb
