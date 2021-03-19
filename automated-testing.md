# Implementing an Automated Testing Solution for OKD Installs on vSphere with User Provisioned Infrastructure (UPI)

## Introduction 

Being a community project, OKD benefits greatly from from repeated testing of installation and functionality. In an effort to simplify the process of conducting repeated OKD installs on vSphere UPI, I developed a script that handles each step of the installation process— from downloading the installer to cleaning up after the installer complete. The script is modular in the sense that each task is a separate function in the script. This allows youk to arrange tasks in different combinations by calling them in a wrapper script. 

## Prerequisites

### DNS
### DHCP
### Load Balancer
### Proxy

## The Functions of OCT

### check_oc()

This function checks for the availability of the *oc* command within the user's path. If the command is not found, the script asks the user if they wish to download it. If yes, the latest binary is downloaded from the OpenShfit public http server.

### check_govc()

This function checks for the availability of the *govc* command within the user's path. If the command is not found, the script asks the user if they wish to download it. If yes, the latest binary is downloaded from the govc public repository.

### install_cluster_tools()

This function downloads the *oc*, *kubectl*, and *openshift-installer* binaries for a desired release version. Users can select a particular version by using the "--release" flag with the appropriate release identifier (e.g. 4.7.0-0.okd-2021-03-07-090821). If you wish to simply install the latest version of a particular major.minor release, simply use that instead (e.g. 4.7). The binaries are installed into a bin folder in your current working directory. 

### launch_prerun()

This function makes a copy of the install-confit.yaml.template file, inserts a pull secret, runs "openshift-installer create manifests" command with that new config file. It then modifies the resulting manifests appropriately for an OKD cluster by, for example, disabling scheduling on the control plane nodes. The script then runs the "openshift-installer create ignition-configs" to general the igition files for the masters and workers. Finally, it copies the bootstrap-append.yaml file to the /var/www/html folder of the deployment controller machine to make it available to the bootstrap node via http. 

### deploy_node()

This function calls the govc binary to duplicate a VM template and set desired cpu, memory, and storage values. It can optionally add Afterburn kernel arguments such as static IP configuration and set the mac address of the VM. The function uses the presence of the --boot flag to determine if the completed node should be booted or not after being configured. 

### build_cluster()

This function makes calls to deploy_node() to deploy a bootstrap node, then iteratively deploy master and worker nodes– all with the appropriate ignition configuration file. 

### destroy-cluster()

This function iterately deletes each VM of the cluster by using the --cluster-name, --master-node-count, and --worker-node-count values to construct its name. 

### manage_power()

This function uses the --cluster-name, --master-node-count, and --worker-node-count to iterivately construct node names, reaching out to each to perform either power on or power off based on the --cluster-power flag. 

### clean()

This function removes the remaining configuration and log files of the current working directory after running the openshift-installer. 

## Creating a Wrapper Script

## Extending the Setup
