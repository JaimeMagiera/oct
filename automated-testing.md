# Implementing an Automated Testing Solution for OKD Installs on vSphere with User Provisioned Infrastructure (UPI)

## Introduction 

Being a community project, OKD benefits greatly from from repeated testing of installation and functionality. In an effort to simplify the process of conducting repeated OKD installs on vSphere UPI, I developed a script that handles each step of the installation process— from downloading the installer to cleaning up after the installer complete. The script is modular in the sense that each task is a separate function in the script. This allows youk to arrange tasks in different combinations by calling them in a wrapper script. 

## Prerequisites

### DNS

* 1 entry for the bootstrap node of the format bootstrap.[cluster].domain.tld
* 3 entries for the master nodes of the form master-[n].[cluster].domain.tld
* An extry for each of the desired worker nodes in the form worker-[n].[cluster].domain.tld
* 1 entry for the API endpoint in the form api.[cluster].domain.tld
* 1 entry for the API internal endpoint in the form api-int.[cluster].domain.tld
* 1 wilcard entry for the Ingress endpoint in the form \*.apps.[cluster].domain.tld

### DHCP
### Load Balancer

vSphere UPI requires the use of a load balancer. There needs to be two pools.

* API: This pool should contain your master nodes. 
* Ingress: This pool should contain your worker nodes. 

### Proxy (Optional)

If the cluster will sit on a private network, you'll need a proxy for outgoing traffic, but for the install process and for regular operation. In the case of the former, the installer needs to pull containers from the external registires. In the case of the latter, the proxy is needed when applicaton containers need access to the outside world (e.g. yum installs, external code repositories like gitlab, etc.) 

The proxy should be configured to accept conections from the IP subnet for your cluster. A simple proxy to use for this purpose is [squid](http://www.squid-cache.org) 


## Automating Installations with a Wrapper Script

It's possible to completely automate the process of installing OpenShift/OKD on vSphere with User Provisioned Infrastructure by chaining together the various functions of oct via a wrapper script. Here's an example...

``` bash
#!/bin/bash

masters_count=3
workers_count=2
template_name="fedora-coreos-33.20210201.2.1-vmware.x86_64"		
cluster_name="example"
cluster_folder="/vCloud/vm/example"
network_name="VM Network"
install_folder=`pwd`

oct.sh --install-tools --release 4.6
oct.sh --prerun --auto-secret
oct.sh --build --template-name "${template_name}" --library "Linux ISOs" --cluster-name "${cluster_name}" --cluster-folder "${cluster_folder}" --network-name "${network_name}" --installation-folder "${install_folder}" --master-node-count ${masters_count} --worker-node-count ${workers_count} 
oct.sh --cluster-power on --cluster-name "${cluster_name}"  --master-node-count ${masters_count} --worker-node-count ${workers_count}
bin/openshift-install --dir=$(pwd) wait-for bootstrap-complete  --log-level=info

```

## Extending the Setup
