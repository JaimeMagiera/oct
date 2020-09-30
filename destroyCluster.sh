#!/bin/bash

while getopts ":c:m:w:" opt; do
  case $opt in
	c) cluster_name="$OPTARG"
	;;
	m) master_node_count="$OPTARG"
        ;;
	w) worker_node_count="$OPTARG"
        ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

echo "Destroying cluster: ${cluster_name}"

# Destroy the master nodes

for (( i=0; i<${master_node_count}; i++ )); do
        vm="master-${i}.${cluster_name}"
	govc vm.destroy $vm
done

# Destroy the worker nodes

for (( i=0; i<${worker_node_count}; i++ )); do
	vm="worker-${i}.${cluster_name}"
	govc vm.destroy $vm
done


# Destroy the bootstrap node

vm="bootstrap.${cluster_name}"
govc vm.destroy $vm
