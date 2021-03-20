# Implementing an Automated Testing Solution for OKD Installs on vSphere with User Provisioned Infrastructure (UPI)

## Introduction 

It's possible to completely automate the process of installing OpenShift/OKD on vSphere with User Provisioned Infrastructure by chaining together the various functions of oct via a wrapper script. 

## Steps

1. Deploy the DNS, DHCP, and load balancer infrastructure outlined in the Prerequisites section.
2. Create an install-config.yaml.template file based on the format outlined in the section [Sample install-config.yaml file for VMware vSphere](https://docs.okd.io/latest/installing/installing_vsphere/installing-vsphere.html#installation-vsphere-config-yaml_installing-vsphere) of the OKD docs. Do not add a pull secret. The script will query you for one or it will insert a default one if you use the --auto-secret flag. 
3. Create a wrapper script that:
   * Downloads the oc and openshift-installer binaries for your desired release version
   * Generates and modifies the ignition files appropriately
   * Builds the cluster nodes
   * Triggers installation process. 

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

## Wrapper Script

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
