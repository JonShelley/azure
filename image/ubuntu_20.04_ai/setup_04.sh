#!/bin/bash

### Install Docker
sudo apt install apt-transport-https ca-certificates curl gnupg-agent software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io -y

# configure docker to store images on /mnt/resource
sudo systemctl stop docker
sudo sed -i -e 's/docker:x:999:/docker:x:999:azureuser:hpcuser/g' /etc/group
sudo sh -c "echo '{  \"graph\": \"/mnt/resource/docker\", \"bip\": \"152.26.0.1/16\" }' > /etc/docker/daemon.json"
sudo systemctl start docker

# Setup nvidia docker
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
sudo apt update && sudo apt install -y nvidia-container-toolkit
sudo systemctl restart docker

# Debian-based distributions (Should we include this package with our image?)
arch=$(dpkg --print-architecture)
curl -fSsL -O https://github.com/NVIDIA/enroot/releases/download/v3.1.1/enroot_3.1.1-1_${arch}.deb
curl -fSsL -O https://github.com/NVIDIA/enroot/releases/download/v3.1.1/enroot+caps_3.1.1-1_${arch}.deb # optional
sudo apt install -y ./*.deb

# Install anaconda python3
cd /mnt
wget "https://repo.anaconda.com/archive/Anaconda3-2020.02-Linux-x86_64.sh"
chmod 755 Anaconda3-2020.02-Linux-x86_64.sh
./Anaconda3-2020.02-Linux-x86_64.sh -b -p /opt/anaconda3
. /opt/anaconda3/bin/activate base

# Install GO
cd /mnt
wget https://golang.org/dl/go1.15.5.linux-amd64.tar.gz
sudo tar -xvf go1.15.5.linux-amd64.tar.gz
sudo mv go /usr/local
cat >/etc/profile.d/go.sh <<EOL
#/bin/bash
export GOROOT=/usr/local/go
export GOPATH=\$GOROOT/work
export PATH=\$PATH:\$GOROOT/bin:\$GOPATH/bin
EOL
. /etc/profile.d/go.sh

# Install Singularity
go get -u github.com/golang/dep/cmd/dep
go get -d github.com/sylabs/singularity
cd $GOPATH/src/github.com/sylabs/singularity
git fetch
git checkout
./mconfig
make -C ./builddir
make -C ./builddir install
