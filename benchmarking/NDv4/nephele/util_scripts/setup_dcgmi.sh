#!/bin/bash

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

