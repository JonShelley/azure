#!/bin/bash

cd hpl-tests

rm -rf *.out

for x in `ls -1 *.log`
do
    node_name=`grep "SLURMD_NODENAME=" $x | cut -d "=" -f2`
    hpl_value=`grep -A 2 "Time                 Gflops" $x  | grep WR | awk '{print $7}'`
    echo "$x : $node_name : $hpl_value" >> hpl_results.out
done

cat hpl_results.out | sort -n -k 5 > hpl_report.out

cat hpl_report.out | head -n 20
