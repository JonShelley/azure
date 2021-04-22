#!/bin/bash
# Ref: https://docs.docker.com/engine/install/ubuntu/

set -ex
apt-get remove docker docker-engine docker.io containerd runc
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io
docker info
apt autoremove -y

# configure docker to store images on /mnt/resource
sudo mkdir -p /mnt/resource/docker
sudo systemctl stop docker
sudo sh -c "echo '{  \"graph\": \"/mnt/resource/docker\", \"bip\": \"152.26.0.1/16\" }' > /etc/docker/daemon.json"
sudo systemctl start docker
