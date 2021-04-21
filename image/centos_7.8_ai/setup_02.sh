#!/bin/bash

# Install NCCL
cd /mnt/resource
git clone https://github.com/NVIDIA/nccl.git
cd nccl/
git checkout v2.8.4-1
git cherry-pick -x 99b8a0393ffa379f3b0b81f3d5c0baa6aad7abef
git cherry-pick -x ef5f37461fdbf11104cf0ee13da80d80b84b4cbc
make -j src.build
make pkg.redhat.build
rpm -i ./build/pkg/rpm/x86_64/libnccl-2.8.4-1+cuda11.2.x86_64.rpm
rpm -i ./build/pkg/rpm/x86_64/libnccl-devel-2.8.4-1+cuda11.2.x86_64.rpm
rpm -i ./build/pkg/rpm/x86_64/libnccl-static-2.8.4-1+cuda11.2.x86_64.rpm

# Install the nccl rdma sharp plugin
cd /mnt/resource
mkdir -p /usr/local/nccl-rdma-sharp-plugins
git clone https://github.com/Mellanox/nccl-rdma-sharp-plugins.git
cd nccl-rdma-sharp-plugins
git checkout v2.0.x-ar
./autogen.sh
./configure --prefix=/usr/local/nccl-rdma-sharp-plugins --with-cuda=/usr/local/cuda
make
sudo make install

# Build the nccl tests
cd /opt/msft
HPCX_DIR=hpcx-v
git clone https://github.com/NVIDIA/nccl-tests.git
. /opt/${HPCX_DIR}*/hpcx-init.sh
hpcx_load
cd nccl-tests
make MPI=1 MPI_HOME=${HPCX_MPI_DIR} CUDA_HOME=/usr/local/cuda

# Add 1 node nccl test
sudo bash -c "cat > /opt/msft/nccl-1n.sh" <<'EOF'
#!/bin/bash
  
. /opt/hpcx-v*/hpcx-init.sh
hpcx_load

mpirun -np 8 \
    --allow-run-as-root \
    --map-by ppr:8:node \
    -x LD_LIBRARY_PATH \
    -mca coll_hcoll_enable 0 \
    -x NCCL_IB_PCI_RELAXED_ORDERING=1 \
    -x UCX_IB_PCI_RELAXED_ORDERING=on \
    -x UCX_TLS=tcp \
    -x CUDA_DEVICE_ORDER=PCI_BUS_ID \
    -x NCCL_SOCKET_IFNAME=eth0 \
    -x NCCL_NET_GDR_LEVEL=5 \
    -x NCCL_TOPO_FILE=/opt/msft/topo.xml \
    /opt/msft/nccl-tests/build/all_reduce_perf -b1K -f2 -g1 -e 4G
EOF
sudo chmod 755 /opt/msft/nccl-1n.sh

# ADD 2 node nccl test
sudo bash -c "cat > /opt/msft/nccl-2n.sh" <<'EOF'
#!/bin/bash
  
NODE1=$1
NODE2=$2

. /opt/hpcx-v*/hpcx-init.sh
hpcx_load

#    -x NCCL_DEBUG=INFO \
mpirun -np 16 \
    --map-by ppr:8:node \
    -H $NODE1:8,$NODE2:8 \
    -x LD_LIBRARY_PATH \
    -mca coll_hcoll_enable 0 \
    -x NCCL_IB_PCI_RELAXED_ORDERING=1 \
    -x UCX_IB_PCI_RELAXED_ORDERING=on \
    -x UCX_TLS=tcp \
    -x CUDA_DEVICE_ORDER=PCI_BUS_ID \
    -x NCCL_SOCKET_IFNAME=eth0 \
    -x NCCL_NET_GDR_LEVEL=5 \
    -x NCCL_TOPO_FILE=/opt/msft/topo.xml \
    /opt/msft/nccl-tests/build/all_reduce_perf -b1K -f2 -g1 -e 4G
EOF
sudo chmod 755 /opt/msft/nccl-2n.sh

