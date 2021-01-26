#!/bin/bash

while getopts ":t:c:d:f:n:i:m:w:" opt; do
  case $opt in
	t) template_name="$OPTARG"
	;;
	c) cluster_name="$OPTARG"
	;;
	d) datastore_name="$OPTARG"
	;;	
	f) vm_folder="$OPTARG"	    
	;;
	n) network_name="$OPTARG"
        ;;
	i) install_folder="$OPTARG"
        ;;
	m) master_node_count="$OPTARG"
        ;;
	w) worker_node_count="$OPTARG"
        ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

bootstrap_cpu=4
bootstrap_memory=16000
bootstrap_disk=120
master_cpu=4
master_memory=16000
master_disk=120
worker_cpu=4
worker_memory=16000
worker_disk=120


echo "Cluster: ${cluster_name}"
echo "Template: ${template_name}"
echo "Datastore: ${datastore_name}"
echo "Folder: ${vm_folder}"
echo "Network: ${network_name}"
echo "Install Folder: ${install_folder}"
echo "Creating a bootstrap node with ${bootstrap_cpu} cpus and ${bootstrap_memory} MB of memory"
echo "Creating ${master_node_count} master nodes with ${master_cpu} cpus and ${master_memory} MB of memory"
echo "Creating ${worker_node_count} worker nodes with ${worker_cpu} cpus and ${worker_memory} MB of memory"

# Create the bootstrap node

vm="bootstrap.${cluster_name}"
govc vm.clone -vm "${template_name}" \
                -ds "${datastore_name}" \
                -folder "${vm_folder}" \
                -on="false" \
                -c="${bootstrap_cpu}" -m="${bootstrap_memory}" \
                -net="${network_name}" \
                $vm
govc vm.disk.change -vm $vm -disk.label "Hard disk 1" -size ${bootstrap_disk}G

# Create the master nodes

for (( i=0; i<${master_node_count}; i++ )); do
        vm="master-${i}.${cluster_name}"
	govc vm.clone -vm "${template_name}" \
		-ds "${datastore_name}" \
		-folder "${vm_folder}" \
		-on="false" \
		-c="${master_cpu}" -m="${master_memory}" \
		-net="${network_name}" \
		$vm
	govc vm.disk.change -vm $vm -disk.label "Hard disk 1" -size ${master_disk}G
done

# Create the worker nodes

for (( i=0; i<${worker_node_count}; i++ )); do
	vm="worker-${i}.${cluster_name}"
	govc vm.clone -vm "${template_name}" \
                -ds "${datastore_name}" \
                -folder "${vm_folder}" \
                -on="false" \
                -c="${worker_cpu}" -m="${worker_memory}" \
                -net="${network_name}" \
                $vm
	govc vm.disk.change -vm $vm -disk.label "Hard disk 1" -size ${worker_disk}G
done

# Set metadata for the bootstrap

vm="bootstrap.${cluster_name}"
govc vm.change -vm $vm \
        -e guestinfo.ignition.config.data="$(cat ${install_folder}/append-bootstrap.ign | base64 -w0)" \
        -e guestinfo.ignition.config.data.encoding="base64" \
        -e disk.EnableUUID="TRUE"

# Set metadata on the master nodes

for (( i=0; i<${master_node_count}; i++ )); do
	vm="master-${i}.${cluster_name}"
	govc vm.change -vm $vm \
		-e guestinfo.ignition.config.data="$(cat ${install_folder}/master.ign | base64 -w0)" \
		-e guestinfo.ignition.config.data.encoding="base64" \
		-e disk.EnableUUID="TRUE"
done

# Set metadata on the worker nodes

for (( i=0; i<${worker_node_count}; i++ )); do
	vm="worker-${i}.${cluster_name}"
	govc vm.change -vm $vm \
                -e guestinfo.ignition.config.data="$(cat ${install_folder}/worker.ign | base64 -w0)" \
                -e guestinfo.ignition.config.data.encoding="base64" \
                -e disk.EnableUUID="TRUE"
done
