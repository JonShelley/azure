## Run HPCX MPI tests in batch with a ANF file system

### Requirements
1. az cli is installed on your host or you will need to use the azure cloud shell from the portal.
 1. Install git on your host if it is not present
  * sudo yum install -y git
1. Request and receive access to Azure NetApp Files using [request form](https://forms.office.com/Pages/ResponsePage.aspx?id=v4j5cvGGr0GRqy180BHbR8cq17Xv9yVBtRCSlcD_gdVUNUpUWEpLNERIM1NOVzA5MzczQ0dQR1ZTSS4u). The request is typically turned around in a day. Once approved you can proceed with the prepartation phase

### Preparation
1. Clone the repo from github to your local machine
   1. cd ~/ 
   1. git clone https://github.com/JonShelley/azure.git
1. cd ~/azure/blog-files/batch/examples/anf
1. Set the variables in the top section of setup_batch_with_anf.sh to the desired values
1. bash setup_batch_with_anf.sh (wait for it to complete before going on to the next step)
1. Login to newly created jump host in $infra_rg resource group (default name batchex${region}-jb)
1. On the jump host execute the following command
   1. cd ~/
   1. git clone https://github.com/JonShelley/azure.git
   1. cd ~/azure/blog-files/batch/tutorials
   1. mkdir -p /scratch/ex1
   1. cp run_hpcx_mpi_tests.sh /scratch/ex1/.

#### Optional
To create jobs and tasks from the jump host, follow the [az cli install instructions](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-yum?view=azure-cli-latest) Once this is completed, you will need to do
* sub_id="Replace with subscription id"
* az account set -s $sub_id
* az batch login

### Create job and task
From the machine that was setup with the az cli:
1. cd ~/azure/blog-files/batch/tutorials/anf_mpi_test
1. Edit the variables at the top of the submit_batch_tasks.sh file to match what was used in setup_batch_with_anf.sh
1. bash submit_batch_tasks.sh