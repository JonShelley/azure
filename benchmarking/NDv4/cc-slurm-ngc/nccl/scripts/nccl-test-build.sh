#!/bin/bash
  
CONT="nvcr.io#nvidia/pytorch:21.09-py3"
MOUNT="/shared/data/azure/benchmarking/NDv4/cc-slurm-ngc/nccl:/nccl,/opt/hpcx-v2.9.0-gcc-MLNX_OFED_LINUX-5.4-1.0.3.0-ubuntu18.04-x86_64:/opt/hpcx"

export OMPI_MCA_pml=ucx
export OMPI_MCA_btl=^openib

srun --ntasks=$SLURM_JOB_NUM_NODES \
    --container-image "${CONT}" \
    --container-name=nccl \
    --container-mounts="${MOUNT}" \
    --ntasks-per-node=1 \
    bash -c 'cd /nccl && git clone https://github.com/NVIDIA/nccl-tests.git && source /opt/hpcx/hpcx-init.sh && hpcx_load && cd nccl-tests && make MPI=1'
