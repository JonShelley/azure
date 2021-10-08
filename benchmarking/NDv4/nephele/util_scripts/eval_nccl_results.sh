#!/bin/bash
OUTDIR="nccl-tests"

cd $OUTDIR
results_file=nccl_results.txt
rm -rf $results_file
for file in `ls -1 *.log`
do
    vms=`grep  "SLURM_NODELIST=" $file | cut -d "=" -f2`
    value=`grep -T 8589934592 $file | grep -v validation`
    echo "$vms : $value" | tee -a $results_file
done

cat $results_file | sort -n -k 12 > nccl_report.out

cat nccl_report.out | head -n 20

#    grep -T 8589934592 * | grep -v validation | sort -n -k 12 > nccl_results.txt


