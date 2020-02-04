#!/bin/bash

if [ -f /etc/bashrc ]; then
        . /etc/bashrc
fi

module load gcc-9.2.0
module load mpi/hpcx

# Create host file
batch_hosts=hosts.batch
rm -rf $batch_hosts
IFS=';' read -ra ADDR <<< "$AZ_BATCH_NODE_LIST"
for i in "${ADDR[@]}"; do echo $i >> $batch_hosts;done

# Determine hosts to run on 
src=$(tail -n1 $batch_hosts)
dst=$(head -n1 $batch_hosts)
echo "Src: $src"
echo "Dst: $dst"

# Run two node MPI tests
mpirun -np 2 --host $src,$dst --map-by node $HPCX_OSU_DIR/osu_latency
mpirun -np 2 --host $src,$dst --map-by node $HPCX_OSU_DIR/osu_bibw