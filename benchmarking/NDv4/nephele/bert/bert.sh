#!/bin/bash

case $1 in
    "1")
        echo "1-node BERT"
        source config_DGXA100_1x8x32x1.sh
        ;;
    "2")
        echo "2-node BERT"
        source config_DGXA100_2x8x27x1.sh
        ;;
    "32")
        echo "32-node BERT"
        source config_DGXA100_32x8x20x1.sh
        ;;
    "128")
        echo "128-node BERT"
        source config_DGXA100_128x8x10x1.sh
        ;;
    "256")
        echo "256-node BERT"
        source config_DGXA100_256x8x4x1.sh
        ;;
    *)
        echo "Invalid node count"
        exit
        ;;
esac

echo "Setting environment variables"

export MLX="0,1,2,3,4,5,6,7";
export cluster=azure;
DATE=`date +m%d.%H%M%S`;

# Set path to BERT MLPerf container
export CONT='/data/bert/language_model.sqsh'

# Set path to data (in this case /tmp/bert/train and /tmp/bert/eval)
export DATADIR='/tmp/bert/train'
export DATADIR_PHASE2='/tmp/bert/train'
export EVALDIR='/tmp/bert/eval'
export CHECKPOINTDIR='/data/bert/cks'
export CHECKPOINTDIR_PHASE1='/data/bert/cks'

# Make directory for logs from training
mkdir -p /data/bert/results/${1}N-${DATE}
export LOGDIR=/data/bert/results/${1}N-${DATE}

sbatch \
  -N${DGXNNODES} \
  --ntasks-per-node=${DGXNGPU} \
  --gpus-per-node=${DGXNGPU} \
  --time=${WALLTIME} \
  run.sub
