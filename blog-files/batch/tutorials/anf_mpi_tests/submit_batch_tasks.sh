#!/bin/bash

# Variables
# Note: pool_id must match what was set in the setup_batch_with_anf.sh file
pool_id=HC
task_id=test
nodes=2
ppn=44
DATE=$(date +"%Y%m%d-%H%M%S-%N")

# Create a batch job if it doesn't already exist
az batch job show --job-id myjobs-${pool_id}
if [ "$?" = "0" ]; then
   echo "myjobs-${pool_id} already exists"
else
   az batch job create \
     --id myjobs-${pool_id} \
     --pool-id $pool_id
fi

# Define task template
cat << EOF >  ${pool_id}_${task_id}.json
{
    "id": "${task_id}-${DATE}",
    "commandLine": "bash -c '\$AZ_BATCH_NODE_MOUNTS_DIR/scratch/ex1/run_hpcx_mpi_tests.sh'",
    "multiInstanceSettings": {
        "numberOfInstances": "2",
        "coordinationCommandLine": "bash -c hostname"
    },
    "userIdentity": {
        "autoUser": {
            "scope": "pool",
            "elevationLevel": "nonadmin"
        }
    },
    "applicationPackageReferences": [
    ],
    "environmentSettings" : [
        {
            "name": "APPLICATION",
            "value": "MPI-Tests"
        },
        {
            "name": "NODES",
            "value": "$nodes"
        },
        {
            "name": "PPN",
            "value": "$ppn"
        }
    ]
}
EOF

# Submit task
az batch task create \
  --job-id myjobs-${pool_id} \
  --json-file ${pool_id}_${task_id}.json
