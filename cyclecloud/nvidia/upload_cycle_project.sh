#!/bin/bash
# Run this script from the Cycle Server.

# Initialize CycleCloud CLI
# Ref: https://docs.microsoft.com/en-us/azure/cyclecloud/how-to/install-cyclecloud-cli?view=cyclecloud-8#initialize-cyclecloud-cli # NOTE: You can use https://localhost for CycleServer URL during the initialization as you’re running it from CycleCloud server itself.
cd ~
cyclecloud initialize

# Create a new project
cyclecloud project init pyxis

# Create a cluster-init script to add CycleCloud user to docker group. 
cd ~/pyxis/specs/default/cluster-init/scripts/

cat << END > 01-docker_group.sh
#!/bin/bash
set -ex
apt-get install -y jq
for USER in \$( jetpack users --json | jq -r '.[].name' ); do 
    echo "Adding user: \${USER}"
    usermod -a -G docker \${USER};
done
newgrp docker
END

# Create a cluster-init script to install pyxis. 
cd ~/pyxis/specs/default/cluster-init/scripts/
cat << END1 > 02-install_pyxis.sh
#!/bin/bash

# Ref: https://github.com/NVIDIA/pyxis
set -ex
git clone https://github.com/NVIDIA/pyxis.git
cd pyxis
make install

# Add pyxis plug-in path to plugstack.conf, which is in the same directory as slurm.conf by default. 
# Ref: https://slurm.schedmd.com/spank.html
cat << END >> /etc/slurm/plugstack.conf
required /usr/local/lib/slurm/spank_pyxis.so
END
systemctl restart slurmd

# Configure Enroot runtime directories.
# Ref: https://github.com/NVIDIA/enroot/blob/master/doc/configuration.md
mkdir -p /mnt/scratch
chmod 1777 /mnt/scratch
cat << END >> /etc/enroot/enroot.conf
ENROOT_RUNTIME_PATH /mnt/scratch/\$(id -un)/run
ENROOT_CACHE_PATH /mnt/scratch/\$(id -un)/cache
ENROOT_DATA_PATH /mnt/scratch/\$(id -un)/data
ENROOT_TEMP_PATH /mnt/scratch/\$(id -un)
END
END1
 
# Upload the new project
cd ~/pyxis
LOCKER=`cyclecloud locker list | cut -d " " -f1`
cyclecloud project upload $LOCKER
