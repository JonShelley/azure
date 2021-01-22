#!/bin/bash

export UCX_IB_ENABLE_CUDA_AFFINITY=n \
       UCX_IB_PCI_RELAXED_ORDERING=on \
       UCX_TLS=rc \
       UCX_NET_DEVICES=mlx5_0:1 \
       NCCL_DEBUG=INFO \
       CUDA_DEVICE_ORDER=PCI_BUS_ID \
       NCCL_IB_PCI_RELAXED_ORDERING=1 \
       NCCL_SOCKET_IFNAME=eth0 \
       NCCL_TOPO_FILE=/nccl-tests/topo.xml

CONT="nvcr.io/nvidia/pytorch:20.10-py3"
MOUNT="/share/home/nvidia/nccl:/nccl-tests,/apps/hpcx-v2.7.3-gcc-MLNX_OFED_LINUX-5.1-2.4.6.0-ubuntu18.04-x86_64:/opt/hpcx"

export OMPI_MCA_pml=ucx
export OMPI_MCA_btl=^openib

srun --ntasks=$SLURM_JOB_NUM_NODES \
    --container-image "${CONT}" \
    --container-name=nccl \
    --container-mounts="${MOUNT}" \
    --ntasks-per-node=1 \
    bash -c "apt update && apt-get install -y infiniband-diags && bash /nccl-tests/scripts/gentopo.sh > ${NCCL_TOPO_FILE}"

srun --gpus-per-node=8 \
    --ntasks-per-node=8 \
    --container-name=nccl \
    --container-mounts "${MOUNT}" \
    bash -c 'source /opt/hpcx/hpcx-init.sh && hpcx_load && /nccl-tests/nccl-tests/build/all_reduce_perf -b8 -f 2 -g 1 -e 4G'
