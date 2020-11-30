#!/bin/bash

while getopts ":c:b:m:w:u:h" opt; do
  case $opt in
	c) cluster_name="$OPTARG"
	;;
	b) base_domain="$OPTARG"
        ;;
	m) master_node_count="$OPTARG"
        ;;
	w) worker_node_count="$OPTARG"
        ;;
	u) username="$OPTARG"
        ;;
	h) print_help=1
	;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

if [[ ${print_help} -eq 1 ]]; then
        echo ""	
	echo "Repair Cluster Hostnames"
	echo ""
	echo "This script attempts to repair the hostnames of cluster nodes which may have had their hostnames previously changed to something erroneous (such as 'fedora'). The script assembles each node's Fully Qualified Domain Name in the pattern <master | worker>-<index>.<cluster>.<base> An ssh connection is attempted to the host. If the connection is successful, 'sudo hostnamectl set-hostname <fqdn>' is run. Be sure to load in your ssh key for the ssh user before running the script." 
	echo ""
	echo "Syntax:"
        echo "repairiClusterHostnames.sh -c mycluster -b your.company.com -m 3 -w 4 -u "
	echo ""
	echo "options:"
	echo "-c The cluster name"
	echo "-b The base domain name"
	echo "-m The number of master nodes"
	echo "-w The number of worker nodes"
	echo "-u The ssh username"
	echo ""
	echo "Example:"
        echo "./repairiClusterHostnames.sh -c mycluster -b your.company.com -m 3 -w 4 -u core"	
	echo ""
	exit 0;
fi

echo "Attempting to repair hostnames for cluster: ${cluster_name}"


for (( i=0; i<${master_node_count}; i++ )); do
	node_fqdn="master-${i}.${cluster_name}.${base_domain}"
	host_ip=$(host "${node_fqdn}" | awk '{ print $4 }')
	echo "Modifying node ${node_fqdn} at ${host_ip}..."
	ssh -t ${username}@${node_fqdn} "sudo hostnamectl set-hostname ${node_fqdn}"
done

for (( i=0; i<${worker_node_count}; i++ )); do
        node_fqdn="worker-${i}.${cluster_name}.${base_domain}"
        host_ip=$(host "${node_fqdn}" | awk '{ print $4 }')
        echo "Modifying node ${node_fqdn} at ${host_ip}..."
        ssh -t ${username}@${node_fqdn} "sudo hostnamectl set-hostname ${node_fqdn}"
done


