# Build NCCL tests
Note: Insure that the nccl-test-build.sh script points to the right location for HPCX (Located in /opt on the Azure HPC marketplace images)

```shell
cd /shared/data/azure/benchmarking/NDv4/cc-slurm-ngc/nccl/scripts
sbatch -N 1 -p <partition_name> nccl-test-build.sh
```

# Run Single VM NCCL test
Notes:
 - Insure that the scripts/nccl.sh script points to the right location for HPCX (Located in /opt on the Azure HPC marketplace images)
 - The output will be placed in logs/nccl_sub_<job_id>.log

To run a single VM NCCL OSU all_reduce_perf test.
- Expected values for size 8589934592 (B) is ~235 GB/s (Bus BW)

```shell
cd /shared/data/azure/benchmarking/NDv4/cc-slurm-ngc/nccl
sbatch -N 1 -p <partition_name> nccl.sub
```

# Run Multi VM NCCL test
To run a Multi VM NCCL OSU all_reduce_perf test.
- Expected values for size 8589934592 (B) on 2-32 VMs is 180-190 GB/s (Bus BW)

```shell
sbatch -N <# of VMs> -p <partition_name> nccl.sub
```
