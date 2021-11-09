# HPL on NDv4

## Notes:
- To run HPL tests you need to configure enroot connect to NGC using your credentials. 
  ```shell
  mkdir -p ~/.config/enroot
  echo "machine nvcr.io login $oauthtoken password \<your specific oauthtoken password for nvcr.io\>" > ~/.config/enroot/.credentials 
  ```
  - [To setup your nvcr.io key](https://www.pugetsystems.com/labs/hpc/How-To-Setup-NVIDIA-Docker-and-NGC-Registry-on-your-Workstation---Part-4-Accessing-the-NGC-Registry-1115)
- The HPL test is not to be used for offical benchmarking results. It uses a container and parameters that give good results but not optimal results. The dat files were originally setup for the A100 40GB GPUs.
- To make new input files for larger than 16 VMs refer to https://github.com/ctierneynv/deepops/blob/master/workloads/burn-in/calculate_N.py 
