# NDv4 test suite
## Notes:
- This work leverages the nephele project found at https://github.com/NVIDIA/nephele to deploy the environment
- Once the environment is deployed, it uses containers obtained from https://ngc.nvidia.com/catalog/containers/

## Requirements
- Install nephele on your deployment machine
  - git clone https://github.com/NVIDIA/nephele.git
  - edit the nephele.conf file
    - update the azure section
    - update ...
  - ./nephele.sh init
- Configure nephele to deploy Standard_ND96asr_v4 VMs
  - More to follow
- Deploy nephele cluster
  - ./nephele.sh create
- Connect to the login node
  - ./nephele.sh connect

**** Special thanks to the Nvidia team for their help and support ****
