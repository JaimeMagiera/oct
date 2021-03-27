* Examples

** Deploying a single CoreOS node

```/bin/bash
template_name=fedora-coreos-33.20210315.1.0-vmware.x86_64
vm_name="fcos-next"
iface="ens192"

oct.sh --deploy-node --template-name "${template_name}" --ignition-file "fcos-next.ign" --vm-name "${vm_name}" --vm-cpu 2 --vm-memory 4000 --vm-disk 100 --cluster-folder "/My-vCloud/FCOS/" --library "Linux ISOs" --ipcfg "ip=10.103.2.92::10.103.0.1:255.255.255.0:${template_name}:${iface}:off" --boot


```
