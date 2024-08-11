#!/bin/bash

OC_DOWNLOAD_URL="https://mirror.openshift.com/pub/openshift-v4/clients/oc/latest/linux/oc.tar.gz"

BIN_DIR=${HOME}/bin

die() {
	echo "$1"
	exit 1
}

show_help() {
  echo -e "\n-h|-?|--help

--auto-secret

Automatically use the "dummy" pull secret instead of prompting for one.

--install-tools

Calls the install_cluster_tools() function. This flag should be used in conjunction with the --release flag.

--prerun

Call the launch_prerun() function.

--provision-infrastructure

Calls the provision_cluster_infrastructure() function. This flag should be accompanied by the --template-name, --library, --cluster-name, --cluster-folder, --network-name, --installation-folder, --master-node-count, and --worker-node-count flags with their appropriate values.

--destroy

Calls the destroy-cluster() function. This should be accompanied by the --cluster-name, --master-node-count, and --worker-node-count flags with their appropriate values.

--clean

Calls the clean() function, which removes all generated files from an installation.

--release version

The release version you wish to install the OKD/OpenShift tools for. This can be the complete release version (e.g. "4.7.0-0.okd-2021-03-07-090821") or the just the major.minor version, in which case the latest build of that version will be used (e.g. "4.7")

--cluster-power [on/off]

Calls the manage_power()function. Values are "on" and "off". This should be accompanied by the --cluster-name, --master-node-count, and --worker-node-count flags with their appropriate values.

--library name

The name of the vSphere Content Library where the VM template can be found

--template-name name

The name of the VM template to use when deploying nodes

--cluster-name name

The name of the cluster. This is used for assembling the node names and URLs (e.g. worker-1.*name.example.com)

--master-node-count number

The desired number of master nodes. This flag should be used in conjunction with --worker-node-count, --build, --destroy, and --cluster-power.

--worker-node-count number

The desired number of worker nodes. This flag should be used in conjunction with --master-node-count, --build, --destroy, and --cluster-power.

--cluster-folder folder

The folder on vSphere where the VMs will be deployed into.

--network-name name

The name of the vSphere network that the deployed VMs should use (e.g. the default "VM Network")

--installation-folder path

The path to the folder with the installation materials.

-v|--verbose

Set the verbosity level."

}	


while :; do
	case $1 in
		-h|-\?|--help)
			show_help
			exit
			;;
	        --test)
                        test_mode=1
                        ;;
		--auto-secret)
			auto_secret=1
			;;    
		--install-tools)
			install_tools=1
			;;
		--install-config-template)
			if [ "$2" ]; then
                                install_config_template_path=$2
                                shift
                        else
                                die 'ERROR: "--install-config-template" requires a non-empty option argument.'
                        fi
                        ;;
		--prerun)
			prerun=1
			;;
		--provision-infrastructure)
			provision_infrastructure=1
			;;
		--destroy)
			destroy=1
			;;
    		--deploy-node)
			deploy_single_node=1
                        ;;			
		--clean)
			clean=1
			;;
                --import-template)
                        import_template=1
			;;
                --template-url)
                        if [ "$2" ]; then
                                template_url=$2
                                shift
                        else
                                die 'ERROR: "--template-url" requires a non-empty option argument.'
                        fi
                        ;;

		--release)
                        if [ "$2" ]; then
                                release=$2
                                shift
                        else
                                die 'ERROR: "--release" requires a non-empty option argument.'
                        fi
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

		--vm-name)
                        if [ "$2" ]; then
                                vm_name=$2
                                shift
                        else
                                die 'ERROR: "--vm-name" requires a non-empty option argument.'
                        fi
                        ;;
		--vm-cpu)
                        if [ "$2" ]; then
                               vm_cpu=$2
                                shift
                        else
                                die 'ERROR: "--vm-cpu" requires a non-empty option argument.'
                        fi
                        ;;
		--vm-memory)
                        if [ "$2" ]; then
                                vm_memory=$2
                                shift
                        else
                                die 'ERROR: "--vm-memory" requires a non-empty option argument.'
                        fi
                        ;;
		--vm-disk)
                        if [ "$2" ]; then
                                vm_disk=$2
                                shift
                        else
                                die 'ERROR: "--vm-disk" requires a non-empty option argument.'
                        fi
                        ;;
		--ignition-file)
                        if [ "$2" ]; then
                                ignition_file_path=$2
                                shift
                        else
                                die 'ERROR: "--ignition-file" requires a non-empty option argument.'
                        fi
                        ;;	
		--ipcfg)
                        if [ "$2" ]; then
                                ipcfg=$2
                                shift
                        else
                                die 'ERROR: "--ipcfg" requires a non-empty option argument.'
                        fi
                        ;;
		--boot)
                        boot_vm=1
                        ;;
		--query-fcos)
                        query_fcos=1
                        ;;	
		--stream-name)
			if [ "$2" ]; then
                                stream_name=$2
                                shift
                        else
                                die 'ERROR: "--stream-name" requires a non-empty option argument.'
                        fi
                        ;;
		--config)
                        parse_config=1
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
	curl -L ${OC_DOWNLOAD_URL} > /tmp/oc.tar.gz
	tar xvf /tmp/oc.tar.gz -C /tmp 
	mv /tmp/oc ${BIN_DIR}
	mv /tmp/kubectl ${BIN_DIR}
	echo "The oc and kubectl applications have been downloaded to directory ${BIN_DIR}"
}	

parse_config() {
	echo "Parsing config..."
	while IFS= read -r line; do
		key=$(echo $line | awk -F ':' '{print $1}')
		value=$(echo $line | awk -F ':' '{print $2}')
		export "$key"="$value"
	done < upi.conf
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
	curl -L ${GOVC_DOWNLOAD_URL} | gunzip > ${BIN_DIR}/govc 
	chmod +x ${BIN_DIR}/govc
	echo "The govc application has been downloaded to the directory ${BIN_DIR}"	
}	

import_template_from_url(){
	file_name=$(basename ${template_url})
	template_name="${file_name%.*}"
	template_exists=false

	echo "Checking for ${template_name} in library ${library}"
	library_items=$(govc library.ls "${library}/*")
	while IFS= read -r line; do
  		library_item_name=$(echo  ${line} | cut -d'/' -f 3)
  		echo "Library Item: $library_item_name"
  		if [[ "$library_item_name" ==  "$template_name" ]]; then
    			echo "Template already exists in library"
    			template_exists=true
    			break
  		fi
	done <<< "$library_items"

	if [[ "$template_exists" == false ]]; then
  		echo "Importing template to library"
  		curl -s -i -O ${template_url}
  		govc library.import -k=true "${library}" "${template_url}"
		echo "template_name"
	fi
}

install_cluster_tools(){

	if [[ -v release ]]; then
		release_info=$(oc adm release info registry.ci.openshift.org/origin/release:"${release}")
		release_version=$(echo "${release_info}" | grep Name | awk '{print $2}')
		pull_url=$(echo "${release_info}" | grep "Pull From:" | awk '{print $3}')	
	else      
		echo "Please use the --release flag to denote what version you'd like to install."
	fi

	installer_file_name="openshift-install-linux-${release_version}.tar.gz"
	client_file_name="openshift-client-linux-${release_version}.tar.gz"

	if [ ! -d bin ]; then
		mkdir bin
	fi
	echo "Downloading the cluster tools for ${release_version}..."

	oc adm release extract --to bin --tools ${pull_url} 
	tar xvf bin/${installer_file_name} -C bin
	tar xvf bin/${client_file_name} -C bin
	rm bin/${installer_file_name}
	rm bin/${client_file_name}
}

create_install_config_from_template() {
        echo "Creating an install config from ${install_config_template_path}"
	if [ -z ${auto_secret} ]; then
                echo "Please enter your pullSecret"
                read pullSecret
        else
                pullSecret='{"auths":{"fake":{"auth":"aWQ6cGFzcwo="}}}'
        fi
        cp "${install_config_template_path}" install-config.yaml
        echo "pullSecret: '${pullSecret}'" >> install-config.yaml
}	

launch_prerun() {
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

	IGNITION_CONFIG="/usr/local/share/images/${NODE_TYPE}.ign"
	IGNITION_DEVICE_ARG=(--qemu-commandline="-fw_cfg name=opt/com.coreos/config,file=${IGNITION_CONFIG}")
	virt-install --connect="qemu:///system" --name="${VM_NAME}" --vcpus="${VM_CPUS}" --memory="${VM_MEMORY}" \
        --os-variant="fedora-coreos-${IMAGE_STREAM}" --import --graphics=none \
        --disk="size=${VM_DISK},pool=openshift-production,backing_store=${IMAGE}" \
        --network network="${BASE_DOMAIN}" "${IGNITION_DEVICE_ARG[@]}" --noreboot
}

provision_cluster_infrastructure(){
        dhcp_config="dhcp_config.txt"
	dns_config="dns_config.txt"
	CLUSTER_BASE_NETWORK=$(echo $CLUSTER_NETWORK | awk -F. -v OFS=. 'NF=3')
	echo "Network: ${CLUSTER_BASE_NETWORK}"
	echo "Cluster: ${CLUSTER}"
	echo "Base Domain: ${BASE_DOMAIN}"
	echo "Image Stream: ${IMAGE_STREAM}"

	## Create the bootstrap node
	VM_NAME="bootstrap.${BASE_DOMAIN}"
	VM_CPUS="${BOOTSTRAP_VCPUS}"
	VM_MEMORY="${BOOTSTRAP_MEMORY}"
	VM_DISK="${BOOTSTRAP_DISK}"
	NODE_TYPE="bootstrap"
	echo "Creating a bootstrap node with ${VM_CPUS} cpus and ${VM_MEMORY} MB of memory"
	IP_ADDRESS="${CLUSTER_BASE_NETWORK}.9"
	if [ -z ${test_mode} ]; then
		deploy_node
		MAC_ADDRESS=$(virsh dumpxml "${VM_NAME}" | grep "<mac address=" | awk -F\' '{print $2}' | awk -F: -v OFS=: 'NF=6')
	else
		MAC_ADDRESS="00:00:00:00:00"
	fi	
	echo "<host mac='${MAC_ADDRESS}' ip='${IP_ADDRESS}'/>" > "${dhcp_config}"
	echo -en "<host ip='${IP_ADDRESS}'>\n  <hostname>${VM_NAME}</hostname>\n</host>\n" > "${dns_config}"

	## Create the master nodes
	VM_CPUS="${CONTROL_PLANE_VCPUS}"
	VM_MEMORY="${CONTROL_PLANE_RAM}"
	VM_DISK="${CONTROL_PLANE_DISK}"
	NODE_TYPE="master"
	echo "Creating ${CONTROL_PLANE_NODE_COUNT} control plane nodes with ${VM_CPUS} cpus and ${VM_MEMORY} MB of memory"

	for (( i=0; i<${CONTROL_PLANE_NODE_COUNT}; i++ )); do
		declare -i x=${i}
		LAST_OCTET=$((x + 10))
		IP_ADDRESS="${CLUSTER_BASE_NETWORK}.${LAST_OCTET}"
		VM_NAME="control-plane-${i}.${BASE_DOMAIN}"
		if [ -z ${test_mode} ]; then
                	deploy_node
              		MAC_ADDRESS=$(virsh dumpxml "${VM_NAME}" | grep "<mac address=" | awk -F\' '{print $2}' | awk -F: -v OFS=: 'NF=6')
     		else
            		MAC_ADDRESS="00:00:00:00:00"
    	        fi 
		echo "<host mac='${MAC_ADDRESS}' ip='${IP_ADDRESS}'/>" >> "${dhcp_config}"
	        echo -en "<host ip='${IP_ADDRESS}'>\n  <hostname>${VM_NAME}</hostname>\n</host>\n" >> "${dns_config}"
	done

	## Create the worker nodes
        VM_CPUS="${WORKER_VCPUS}"	
        VM_MEMORY="${WORKER_MEMORY}"
	VM_DISK="${WORKER_DISK}"
	NODE_TYPE="worker"
	echo "Creating ${WORKER_NODE_COUNT} worker nodes with ${VM_CPUS} cpus and ${VM_MEMORY} MB of memory"

	for (( i=0; i<${WORKER_NODE_COUNT}; i++ )); do
		declare -i x=${i}
                LAST_OCTET=$((x + 20))
                IP_ADDRESS="${CLUSTER_BASE_NETWORK}.${LAST_OCTET}"
		VM_NAME="worker-${i}.${BASE_DOMAIN}"
		if [ -z ${test_mode} ]; then
                        deploy_node
                        MAC_ADDRESS=$(virsh dumpxml "${VM_NAME}" | grep "<mac address=" | awk -F\' '{print $2}' | awk -F: -v OFS=: 'NF=6')
                else
                        MAC_ADDRESS="00:00:00:00:00"
                fi
                echo "<host mac='${MAC_ADDRESS}' ip='${IP_ADDRESS}'/>" >> "${dhcp_config}"
                echo -en "<host ip='${IP_ADDRESS}'>\n  <hostname>${VM_NAME}</hostname>\n</host>\n" >> "${dns_config}" 
	done
	echo "########## DHCP CONFIG ##########"
	cat "${dhcp_config}"
	echo "########## DNS CONFIG ##########"
	cat "${dns_config}"
}	

run_installer() {
  bin/openshift-install create cluster --dir=$(pwd) --log-level=info 
}	

destroy_cluster() {
	echo "If you really want to delete the cluster ${cluster_name}, type its name again:"
	read response
	
	if [[ "${response}" == "${cluster_name}" ]]; then
		echo "Destroying cluster: ${cluster_name}"
		# Destroy the master nodes

		for (( i=0; i<${master_node_count}; i++ )); do
			vm="master-${i}.${cluster_name}"
			echo "master: $vm"
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

query_fcos_stream() {
	stream_data=$(curl -s https://builds.coreos.fedoraproject.org/streams/${stream_name}.json)
	file_url=$(echo ${stream_data} | jq -r '.architectures.x86_64.artifacts.vmware.formats.ova.disk.location')
	file_name=$(basename ${file_url})
	template_name="${file_name%.*}"
	echo "${file_url}"
}

#check_oc
parse_config
provision_cluster_infrastructure

if [ ! -z ${install_tools} ]; then
	install_cluster_tools	
fi	

if [ ! -z ${import_template} ]; then
        import_template_from_url
fi

if [ ! -z ${install_config_template_path} ]; then
	create_install_config_from_template	
fi

if [ ! -z ${prerun} ]; then
	launch_prerun
fi

if [ ! -z ${provision_infrastructure} ]; then
	provision_cluster_infrastructure
fi

if [ ! -z ${deploy_single_node} ]; then
        deploy_node
fi

if [ ! -z ${destroy} ]; then
	destroy_cluster
fi

if [ ! -z ${cluster_power_action} ]; then
	manage_cluster_power
fi

if [ ! -z ${clean} ]; then
	clean
fi

if [ ! -z ${query_fcos} ]; then
        query_fcos_stream
fi
