#!/bin/bash
  
export MLX="0,1,2,3,4,5,6,7";
export cluster=azure;
DATE=`date +m%d.%H%M%S`;

source config_DGXA100_1x8x32x1.sh

CONT='/share/home/nvidia/training_results_v0.7/NVIDIA/benchmarks/bert/implementations/pytorch/language_model.sqsh' \
DATADIR=/share/home/nvidia/chopped_2048_balanced \
DATADIR_PHASE2=/share/home/nvidia/chopped_2048_balanced \
EVALDIR=/share/home/nvidia/hdf5 \
CHECKPOINTDIR=/share/home/nvidia/cks \
CHECKPOINTDIR_PHASE1=/share/home/nvidia/cks \
LOGDIR=/share/home/nvidia/training_results_v0.7/NVIDIA/benchmarks/bert/implementations/pytorch/results \

sbatch \
  -N${DGXNNODES} \
  --ntasks-per-node=${DGXNGPU} \
  --gpus-per-node=${DGXNGPU} \
  --time=${WALLTIME} \
  run.sub
