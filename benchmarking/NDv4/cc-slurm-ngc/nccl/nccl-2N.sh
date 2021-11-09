#!/bin/bash

host1=$1
host2=$2

module load mpi/hpcx

export OMPI_MCA_pml=ucx
export OMPI_MCA_btl=^openib
export UCX_NET_DEVICES=mlx5_ib0:1,mlx5_ib1:1,mlx5_ib2:1,mlx5_ib3:1,mlx5_ib4:1,mlx5_ib5:1,mlx5_ib6:1,mlx5_ib7:1
export  CUDA_VISIBLE_DEVICES=2,3,0,1,6,7,4,5

mpirun \
    -n 16 \
    --map-by ppr:8:node \
    -H $host1:8,$host2:8 \
    -x LD_LIBRARY_PATH \
    -mca coll_hcoll_enable 0 \
    -x NCCL_IB_PCI_RELAXED_ORDERING=1 \
    -x UCX_IB_PCI_RELAXED_ORDERING=on \
    -x UCX_TLS=rc \
    -x CUDA_DEVICE_ORDER=PCI_BUS_ID \
    -x NCCL_SOCKET_IFNAME=eth0 \
    -x NCCL_NET_GDR_LEVEL=5 \
    -x NCCL_TOPO_FILE=/opt/microsoft/ndv4-topo.xml \
    /shared/data/azure/benchmarking/NDv4/cc-slurm-ngc/nccl/nccl-tests/build/all_reduce_perf -b8 -f 2 -g 1 -e 8G
