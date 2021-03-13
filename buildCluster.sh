#!/bin/bash


die() {
    echo "$1"
    exit 1
}

while :; do
    case $1 in
        -h|-\?|--help)
            show_help
            exit
            ;;
        --auto)
            auto_select=1
            ;;
	--install-tools)
            install_tools=1
            ;;
	 --prerun)
            prerun=1
            ;;
         --build)
            build=1
            ;;	    
         --template-name)
            if [ "$2" ]; then
                template_name=$2
                shift
            else
                die 'ERROR: "--template-name" requires a non-empty option argument.'
            fi
            ;;	    
         --cluster-name)
            if [ "$2" ]; then
                cluster_name=$2
                shift
            else
                die 'ERROR: "--cluster-name" requires a non-empty option argument.'
            fi
            ;;
         --vm-folder)
            if [ "$2" ]; then
                vm_folder=$2
                shift
            else
                die 'ERROR: "--vm-folder" requires a non-empty option argument.'
            fi
            ;;
         --network-name)
            if [ "$2" ]; then
                network_name=$2
                shift
            else
                die 'ERROR: "--network-name" requires a non-empty option argument.'
            fi
            ;;	    
         --installation-folder)
            if [ "$2" ]; then
                installation_folder=$2
                shift
            else
                die 'ERROR: "--installation_folder" requires a non-empty option argument.'
            fi
            ;;
         --master-node-count)
            if [ "$2" ]; then
		master_node_count=$2
                shift
            else
                die 'ERROR: "--master-node-count" requires a non-empty option argument.'
            fi
            ;;
         --worker-node-count)
            if [ "$2" ]; then
                worker_node_count=$2
                shift
            else
                die 'ERROR: "--worker-node-count" requires a non-empty option argument.'
            fi
            ;;

    -v|--verbose)
            verbose=$((verbose + 1))
            ;;
        --)
            shift
            break
            ;;
        -?*)
            printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
            ;;
        *)
            break
    esac

    shift
done

install_cluster_tools(){

	if ! command -v oc &> /dev/null
	then
        	echo "The oc command could not be found. This script will attempt to download the most recent stable version of the OpenShift client, which can be used to install all minor version of the software."
        	curl -O "https://mirror.openshift.com/pub/openshift-v4/clients/oc/latest/linux/oc.tar.gz"
        	binary_path="$HOME/bin"
        	tar xvf oc.tar.gz -C ${binary_path}
        	rm oc.tar.gz
	fi

	if [ -z ${release_version} ]; then
        	release_info=$(oc adm release info registry.ci.openshift.org/origin/release:4.7)
        	release_version=$(echo "${release_info}" | grep Name | awk '{print $2}')
		pull_url=$(echo "${release_info}" | grep "Pull From:" | awk '{print $3}')	
	fi

	installer_file_name="openshift-install-linux-${release_version}.tar.gz"
	client_file_name="openshift-client-linux-${release_version}.tar.gz"

	if [ ! -d bin ]; then
		mkdir bin
	fi



	oc adm release extract --to bin --tools ${pull_url} 
	tar xvf bin/${installer_file_name} -C bin
	tar xvf bin/${client_file_name} -C bin
	rm bin/${installer_file_name}
	rm bin/${client_file_name}
}

launch_prerun() {
	echo "Please enter your pullSecret"
	read pullSecret
	cp install-config.yaml.template install-config.yaml
	echo "pullSecret: '${pullSecret}'" >> install-config.yaml
	bin/openshift-install create manifests --dir=$(pwd)
	rm -f openshift/99_openshift-cluster-api_master-machines-*.yaml openshift/99_openshift-cluster-api_worker-machineset-*.yaml
	sed -i -e s/true/false/g manifests/cluster-scheduler-02-config.yml
	bin/openshift-install create ignition-configs --dir=$(pwd)
	# Change timeouts for Master
	sed -i "s/\"timeouts\":{}/\"timeouts\":{\"httpResponseHeaders\":50,\"httpTotal\":600}/g" master.ign
	# Change timeouts for Worker
	sed -i "s/\"timeouts\":{}/\"timeouts\":{\"httpResponseHeaders\":50,\"httpTotal\":600}/g" worker.ign

	sudo /usr/bin/cp bootstrap.ign /var/www/html/bootstrap.ign
	sudo /usr/bin/chown apache:apache /var/www/html/bootstrap.ign
	sudo /usr/sbin/restorecon -Rv /var/www/html/
}

build_cluster(){
	
	bootstrap_cpu=4
	bootstrap_memory=16384
	bootstrap_disk=120
	master_cpu=4
	master_memory=16384
	master_disk=120
	worker_cpu=4
	worker_memory=16384
	worker_disk=120


	echo "Cluster: ${cluster_name}"
	echo "Template: ${template_name}"
	echo "Datastore: ${datastore_name}"
	echo "Folder: ${vm_folder}"
	echo "Network: ${network_name}"
	echo "Installation Folder: ${installation_folder}"

	# Create the bootstrap node
	echo "Creating a bootstrap node with ${bootstrap_cpu} cpus and ${bootstrap_memory} MB of memory"

	vm="bootstrap.${cluster_name}"
	/home/jaimelm1/projects/oct/deploy-coreos-node.sh -v --ova "$template_name" --name "${vm}" --cpu "${bootstrap_cpu}"  --memory "${bootstrap_memory}" --disk "${bootstrap_disk}"  --folder "${vm_folder}" --library "Linux ISOs" --ignition "${installation_folder}/append-bootstrap.ign"

	# Create the master nodes
	echo "Creating ${master_node_count} master nodes with ${master_cpu} cpus and ${master_memory} MB of memory"

	for (( i=0; i<${master_node_count}; i++ )); do
        	vm="master-${i}.${cluster_name}"
        	/home/jaimelm1/projects/oct/deploy-coreos-node.sh -v --ova "$template_name" --name "${vm}" --cpu "${master_cpu}"  --memory "${master_memory}" --disk "${master_disk}"  --folder "${vm_folder}" --library "Linux ISOs" --ignition "${installation_folder}/master.ign"
	done

	# Create the worker nodes
	echo "Creating ${worker_node_count} worker nodes with ${worker_cpu} cpus and ${worker_memory} MB of memory"

	for (( i=0; i<${worker_node_count}; i++ )); do
        	vm="worker-${i}.${cluster_name}"
        	/home/jaimelm1/projects/oct/deploy-coreos-node.sh --ova "$template_name" --name "${vm}" --cpu "${worker_cpu}"  --memory "${worker_memory}" --disk "${worker_disk}"  --folder "${vm_folder}" --library "Linux ISOs" --ignition "${installation_folder}/worker.ign"
	done
}	

if [ ! -z ${install_tools} ]; then
	install_cluster_tools	
fi	

if [ ! -z ${prerun} ]; then
        launch_prerun
fi

if [ ! -z ${build} ]; then
        build_cluster
fi
