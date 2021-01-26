#!/bin/bash

while getopts ":c:a:m:w:" opt; do
  case $opt in
	c) cluster_name="$OPTARG"
	;;
 	m) master_node_count="$OPTARG"
        ;;
        w) worker_node_count="$OPTARG"
        ;;	
	a) action="$OPTARG"
	;;	
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

echo "Cluster: ${cluster_name}"
echo "Action: ${action}"
echo "Master Node Count: ${master_node_count}"
echo "Worker Node Count: ${worker_node_count}"

# Manage power for the bootstrap node

vm="bootstrap.${cluster_name}"
govc vm.power -on "${vm}"

# Manage power for the master nodes

for (( i=0; i<${master_node_count}; i++ )); do
        vm="master-${i}.${cluster_name}"
	govc vm.power -on "${vm}"
done

# Manage power for the worker nodes

for (( i=0; i<${worker_node_count}; i++ )); do
	vm="worker-${i}.${cluster_name}"
	govc vm.power -on "${vm}"
done

