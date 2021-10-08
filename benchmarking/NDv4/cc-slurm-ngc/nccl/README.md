# Download HPCX
cd \<desired location for HPC-X\>

wget https://content.mellanox.com/hpc/hpc-x/v2.7.4/hpcx-v2.7.4-gcc-MLNX_OFED_LINUX-5.1-0.6.6.0-ubuntu18.04-x86_64.tbz

tar -xjf hpcx-v2.7.4-gcc-MLNX_OFED_LINUX-5.1-0.6.6.0-ubuntu18.04-x86_64.tbz

rm -rf hpcx-v2.7.4-gcc-MLNX_OFED_LINUX-5.1-0.6.6.0-ubuntu18.04-x86_64.tbz

# Build NCCL tests
cd scripts

sbatch -N 1 nccl-test-build.sh

# Run Single VM NCCL test
sbatch -N 1 nccl.sub

# Run Multi VM NCCL test
## Replace \<x\> with the desired number of VMs
sbatch -N \<x\> nccl.sub
