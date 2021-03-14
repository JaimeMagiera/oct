#!/bin/bash

OC_URL="https://mirror.openshift.com/pub/openshift-v4/clients/oc/latest/linux/oc.tar.gz"
GOVC_URL="https://github.com/vmware/govmomi/releases/download/v0.24.0/govc_linux_amd64.gz"

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
		--auto-secret)
			auto_secret=1
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
		--destroy)
			destroy=1
			;;		    
		--clean)
			clean=1
			;;
		--cluster-power)
			if [ "$2" ]; then
				cluster_power_action=$2
				shift
			else
				die 'ERROR: "--power" requires a non-empty option argument.'
			fi
			;;
		--library)
			if [ "$2" ]; then
				library=$2
				shift
			else
				die 'ERROR: "--library" requires a non-empty option argument.'
			fi
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
		--cluster-folder)
			if [ "$2" ]; then
				cluster_folder=$2
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

check_oc() {
	
	if ! command -v oc &> /dev/null
        then
                while true; do
                        read -p "The oc command could not be found. Would you like to download it? " yn
                        case $yn in
                                [Yy]* )
                                        install_oc;break;;
                                [Nn]* ) exit;;
                                * ) echo "Please answer yes or no.";;
                        esac
                done
        fi

}	

install_oc() {
	echo "This script will attempt to download the most recent stable version to your working directory."
	curl -L ${OC_URL} | gunzip > oc
	chmod +x oc
}	

check_govc() {

	if ! command -v govc &> /dev/null
	then
		while true; do
			read -p "The govc command could not be found. Would you like to download it? " yn
			case $yn in
				[Yy]* ) 
					install_govc;break;;
				[Nn]* ) exit;;
				* ) echo "Please answer yes or no.";;
			esac
		done
	fi
}

install_govc() {
	echo "This script will attempt to download the most recent stable version to your working directory."
	curl -L ${GOVC_URL} | gunzip > govc 
	chmod +x govc
}	

install_cluster_tools(){

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
	if [ -z ${auto_secret} ]; then
		echo "Please enter your pullSecret"
		read pullSecret
	else
		pullSecret='{"auths":{"fake":{"auth": "bar"}}}'
	fi
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

	echo "Copying bootstrap.ign to /var/www/html/..."
	sudo /usr/bin/cp bootstrap.ign /var/www/html/bootstrap.ign
	sudo /usr/bin/chown apache:apache /var/www/html/bootstrap.ign
	sudo /usr/sbin/restorecon -Rv /var/www/html
}

deploy_node() {
	govc library.deploy --folder "${cluster_folder}" "${library}/${template_name}" "${vm_name}"
	govc vm.change -vm "${vm_name}" \
		-c="${vm_cpu}" \
		-m="${vm_memory}" 
	govc vm.change -vm "${vm_name}" -e guestinfo.ignition.config.data="$(cat ${ignition_file_path} | base64 -w0)" -e guestinfo.ignition.config.data.encoding="base64"
	govc vm.disk.change -vm "${vm_name}" -disk.label "Hard disk 1" -size ${vm_disk}G

	if [[ ! -z "${ipcfg}" ]]; then
		govc vm.change -vm "${vm_name}" -e "guestinfo.afterburn.initrd.network-kargs=${ipcfg}"
	fi

	if [[ ! -z "${vm_mac}" ]]; then
		govc vm.network.change -vm ${vm_name} -net "${cluster_network}" -net.address ${vm_mac} ethernet-0
	fi

	if [[ ! -z "${boot_vm}" ]]; then
		govc vm.power -on "${vm_name}"
	fi
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
	echo "Folder: ${cluster_folder}"
	echo "Network: ${network_name}"
	echo "Installation Folder: ${installation_folder}"

	# Create the bootstrap node
	echo "Creating a bootstrap node with ${bootstrap_cpu} cpus and ${bootstrap_memory} MB of memory"
	vm_name="bootstrap.${cluster_name}"
	vm_cpu="${bootstrap_cpu}"
	vm_memory="${bootstrap_memory}"
	vm_disk="${bootstrap_disk}"
	vm_name="bootstrap.${cluster_name}"
	ignition_file_path="${installation_folder}/append-bootstrap.ign"

	deploy_node

	# Create the master nodes
	echo "Creating ${master_node_count} master nodes with ${master_cpu} cpus and ${master_memory} MB of memory"
	vm_cpu="${master_cpu}"
	vm_memory="${master_memory}"
	vm_disk="${master_disk}"
	ignition_file_path="${installation_folder}/master.ign"

	for (( i=0; i<${master_node_count}; i++ )); do
		vm_name="master-${i}.${cluster_name}"
		deploy_node
	done

	# Create the worker nodes
	echo "Creating ${worker_node_count} worker nodes with ${worker_cpu} cpus and ${worker_memory} MB of memory"
	vm_cpu="${worker_cpu}"
	vm_memory="${worker_memory}"
	vm_disk="${worker_disk}"
	ignition_file_path="${installation_folder}/worker.ign"

	for (( i=0; i<${worker_node_count}; i++ )); do
		vm_name="worker-${i}.${cluster_name}"
		deploy_node
	done
}	

destroy() {

	echo "If you really want to delete the cluster ${cluster_name}, type its name again:"
	read response

	if [[ "${response}" == "${cluster_name}" ]]; then
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
	else
		echo "OK, I'll forget you ever mentioned it."
	fi
}	

clean() {
	rm -rf master.ign worker.ign metadata.json .openshift_install* auth/ bootstrap.ign
}	

manage_cluster_power() {

	echo "Turning cluster ${power_action}..."

	vm="bootstrap.${cluster_name}"
	govc vm.power -${cluster_power_action} "${vm}"

	# Manage power for the master nodes

	for (( i=0; i<${master_node_count}; i++ )); do
		vm="master-${i}.${cluster_name}"
		govc vm.power -${cluster_power_action} "${vm}"
	done

	# Manage power for the worker nodes

	for (( i=0; i<${worker_node_count}; i++ )); do
		vm="worker-${i}.${cluster_name}"
		govc vm.power -${cluster_power_action} "${vm}"
	done

}

check_oc
check_govc

if [ ! -z ${install_tools} ]; then
	install_cluster_tools	
fi	

if [ ! -z ${prerun} ]; then
	launch_prerun
fi

if [ ! -z ${build} ]; then
	build_cluster
fi

if [ ! -z ${destroy} ]; then
	destroy
fi

if [ ! -z ${cluster_power_action} ]; then
	manage_cluster_power
fi

if [ ! -z ${clean} ]; then
	clean
fi

