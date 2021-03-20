# oct
OCT is a command line tool to simplify the process of building and destroying OKD/Openshift clusters in vSphere. It utilizes the govc command line tool to communicate with vSphere. 

Being a community project, OKD benefits greatly from from repeated testing of installation and functionality. In an effort to simplify the process of conducting repeated OKD installs on vSphere UPI, I developed this script to handle each step of the installation process— from downloading the installer to cleaning up after the installer complete. The script is modular in the sense that each task is a separate function in the script. This allows youk to arrange tasks in different combinations by calling them in a wrapper script. For an example, see the page [Implementing an Automated Testing Solution for OKD Installs on vSphere with User Provisioned Infrastructure (UPI)](https://github.com/JaimeMagiera/oct/blob/master/automated-testing.md).

## The Command Line Arguments of oct
### -h|-\?|--help

### --auto-secret

  Automatically use the "dummy" pull secret instead of prompting for one.

### --install-tools

  Calls the install_cluster_tools() function. This flag should be used in conjunction with the --release flag.
  
### --release  
  The release version you wish to install the OKD/OpenShift tools for. This can be the complete release version (e.g. "4.7.0-0.okd-2021-03-07-090821") or the just the major.minor version, in which case the latest build of that version will be used (e.g. "4.7")


### --prerun 

  Call the launch_prerun() function. 

### --build

  Calls the build_cluster() function. This flag should be accompanied by the --template-name, --library, --cluster-name, --cluster-folder, --network-name, --installation-folder, --master-node-count, and --worker-node-count flags with their appropriate values.

### --destroy

  Calls the destroy-cluster() function. This should be accompanied by the --cluster-name, --master-node-count, and --worker-node-count flags with their appropriate values.

--clean

--cluster-power

--library

--template-name

--cluster-name

--cluster-folder

--network-name

--installation-folder

--master-node-count

--worker-node-count

-v|--verbose 

## The Functions of oct

### check_oc()

This function checks for the availability of the *oc* command within the user's path. If the command is not found, the script asks the user if they wish to download it. If yes, the latest binary is downloaded from the OpenShfit public http server.

### check_govc()

This function checks for the availability of the *govc* command within the user's path. If the command is not found, the script asks the user if they wish to download it. If yes, the latest binary is downloaded from the govc public repository.

### install_cluster_tools()

This function downloads the *oc*, *kubectl*, and *openshift-installer* binaries for a desired release version. Users can select a particular version by using the "--release" flag with the appropriate release identifier (e.g. 4.7.0-0.okd-2021-03-07-090821). If you wish to simply install the latest version of a particular major.minor release, simply use that instead (e.g. 4.7). The binaries are installed into a bin folder in your current working directory. 

### launch_prerun()

This function makes a copy of a install-confit.yaml.template file, inserts a pull secret, runs "openshift-installer create manifests" command with that new config file. It then modifies the resulting manifests appropriately for an OKD cluster by, for example, disabling scheduling on the control plane nodes. The script then runs the "openshift-installer create ignition-configs" to general the igition files for the masters and workers. Finally, it copies the bootstrap-append.yaml file to the /var/www/html folder of the deployment controller machine to make it available to the bootstrap node via http. 

Note: The openshift-installer injests and deletes the install configuration file. That's why oct makes a copy of a template you've created to pass to the installer. For more details on the format of the instal-config.yaml file, please see the section [Sample install-config.yaml file for VMware vSphere](https://docs.okd.io/latest/installing/installing_vsphere/installing-vsphere.html#installation-vsphere-config-yaml_installing-vsphere) of the OKD documentention

### deploy_node()

This function calls the govc binary to duplicate a VM template and set desired cpu, memory, and storage values. It can optionally add Afterburn kernel arguments such as static IP configuration and set the mac address of the VM. The function uses the presence of the --boot flag to determine if the completed node should be booted or not after being configured. 

### build_cluster()

This function makes calls to deploy_node() to deploy a bootstrap node, then iteratively deploy master and worker nodes– all with the appropriate ignition configuration file. 

### destroy-cluster()

This function iterately deletes each VM of the cluster by using the --cluster-name, --master-node-count, and --worker-node-count values to construct its name. 

### manage_power()

This function uses the --cluster-name, --master-node-count, and --worker-node-count to iterivately construct node names, reaching out to each to perform either power on or power off based on the --cluster-power flag. 

### clean()

This function removes the remaining configuration and log files of the current working directory after running the openshift-installer. That includes: the master.ign, worker.ign metadata.json, bootstrap.ign, .openshift_install* logs, and the auth folder. 
