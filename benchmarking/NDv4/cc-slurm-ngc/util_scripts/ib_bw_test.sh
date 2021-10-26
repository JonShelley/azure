#!/bin/bash
  
  host1=$1
  host2=$2

  module load mpi/hpcx

  export OMPI_MCA_coll_hcoll_enable=0
  #mpirun -n 2 --host $host1,$host2  --map-by node -x LD_LIBRARY_PATH -x UCX_RNDV_THRESH=1024 $HPCX_OSU_CUDA_DIR/osu_bw 
  D D
  #exit 0

  vmId=`ssh $host1 curl -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2019-06-04" | jq '.compute.vmId'`
  echo "VM ID: $vmId" 

  for x in  0 1 2 3 4 5 6 7
  do 
     echo -n "IB${x}: "
        mpirun -n 2 --host $host1,$host2 -x UCX_NET_DEVICES=mlx5_ib$x:1 -x CUDA_VISIBLE_DEVICES=$x --map-by node -x LD_LIBRARY_PATH -x UCX_RNDV_THRESH=1024 $HPCX_OSU_CUDA_DIR/osu_bw D D | grep ^4194304
        done

