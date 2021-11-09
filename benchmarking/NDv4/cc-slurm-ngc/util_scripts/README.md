# The following scripts are to help verify that the NDv4 platform is working as expected.

## Check GPU Bandwidth
_Note: This test needs to be run on the individual VMs. Before this test can be run you will need to compile the NVIDIA GPU BW code_
```shell
# Compile and move the executable to the correct location
cd /usr/local/cuda/samples/1_Utilities/bandwidthTest/
sudo make
cp bandwidthTest /shared/data/azure/benchmarking/NDv4/cc-slurm-ngc/util_scripts/gpu-bwtest
```
Once the above setup is complete, run the test
```shell
./check-vm-gpu-bw.sh
```
