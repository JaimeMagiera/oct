# Examples

## Deploying an OKD Cluster

Please see [Implementing an Automated Installation Solution for OKD on vSphere with User Provisioned Infrastructure (UPI)](https://github.com/JaimeMagiera/oct/blob/master/automated-installations.md)

## Deploying a single CoreOS node

```/bin/bash

#!/bin/bash

template_name=fedora-coreos-33.20210315.1.0-vmware.x86_64
cluster_folder="/My-vCloud/FCOS/"
library="Linux ISOs"
vm_name="fcos-next"
vm_cpu=2
vm_memory=4000
vm_disk=100
ignition_file="fcos-next.ign"
iface="ens192"
ipcfg="ip=10.103.2.92::10.103.0.1:255.255.255.0:${vm_name}:${iface}:off"

oct.sh --deploy-node --template-name "$template_name" --ignition-file "${ignition_file}" --vm-name "${vm_name}" --vm-cpu "${vm_cpu}" --vm-memory "${vm_memory}" --vm-disk "${vm_disk}" --cluster-folder "${cluster_folder}" --library "${library}" --ipcfg "${ipcfg}" --boot

```
