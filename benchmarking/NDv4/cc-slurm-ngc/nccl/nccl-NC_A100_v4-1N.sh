#!/bin/bash

module load mpi/hpcx

mpirun -np 4 --bind-to numa --map-by ppr:4:node -mca coll_hcoll_enable 0 -x LD_LIBRARY_PATH -x UCX_TLS=tcp -x UCX_NET_DEVICES=eth0 -x NCCL_SOCKET_IFNAME=eth0 -x NCCL_DEBUG=WARN -x NCCL_TOPO_FILE=/opt/microsoft/ncv4/topo.xml -x NCCL_GRAPH_FILE=/opt/microsoft/ncv4/graph.xml -x NCCL_ALGO=Tree -x NCCL_SHM_USE_CUDA_MEMCPY=1 -x CUDA_DEVICE_MAX_CONNECTIONS=32 -x NCCL_CREATE_THREAD_CONTEXT=1 /opt/nccl-tests/build/all_reduce_perf -b1K -f2 -g1 -e 4G
