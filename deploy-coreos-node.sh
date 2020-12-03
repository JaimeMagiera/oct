#!/bin/bash

while :; do
    case $1 in
        -h|-\?|--help)
            show_help
            exit
            ;;
        --template)
            if [ "$2" ]; then
                template_name=$2
                shift
            else
                die 'ERROR: "--template" requires a non-empty option argument.'
            fi
            ;;
	--ignition)
            if [ "$2" ]; then
                ignition_file_path=$2
                shift
            else
                die 'ERROR: "--ignition" requires a non-empty option argument.'
            fi
            ;;
        --name)
            if [ "$2" ]; then
                vm_name=$2
                shift
            else
                die 'ERROR: "--name" requires a non-empty option argument.'
            fi
            ;;
        --cpu)
            if [ "$2" ]; then
                vm_cpu=$2
                shift
            else
                die 'ERROR: "--cpu" requires a non-empty option argument.'
            fi
            ;;
        --memory)
            if [ "$2" ]; then
                vm_memory=$2
                shift
            else
                die 'ERROR: "--memory" requires a non-empty option argument.'
            fi
            ;;
        --disk)
            if [ "$2" ]; then
                vm_disk=$2
                shift
            else
                die 'ERROR: "--disk" requires a non-empty option argument.'
            fi
            ;;	    
        --network)
            if [ "$2" ]; then
                cluster_network=$2
                shift
            else
                die 'ERROR: "--network" requires a non-empty option argument.'
            fi
            ;;
	--mac)
            if [ "$2" ]; then
                vm_mac=$2
                shift
            else
                die 'ERROR: "--mac" requires a non-empty option argument.'
            fi
            ;;
	--folder)
            if [ "$2" ]; then
                cluster_folder=$2
                shift
            else
                die 'ERROR: "--folder" requires a non-empty option argument.'
            fi
            ;;        
        --datastore)
            if [ "$2" ]; then
                cluster_datastore=$2
                shift
            else
                die 'ERROR: "--datastore" requires a non-empty option argument.'
            fi
            ;;  
        --boot)
            boot_vm=$1
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

echo "Template: ${template_name}"
echo "VM Name: ${vm_name}"
echo "CPU: ${vm_cpu}"
echo "Memory: ${vm_memory}"
echo "Disk: ${vm_disk}"
echo "MAC Address: ${vm_mac}"
echo "Network: ${cluster_network}"
echo "Folder: ${cluster_folder}"
echo "Datastore: ${cluster_datastore}"

govc vm.clone -vm "${template_name}" \
		-ds "${cluster_datastore}" \
		-folder "${cluster_folder}" \
		-on="false" \
		-c="${vm_cpu}" -m="${vm_memory}" \
		-net="${cluster_network}" \
		$vm_name

govc vm.change -vm "${vm_name}" \
	-e guestinfo.ignition.config.data="$(cat ${ignition_file_path} | base64 -w0)" \
	-e guestinfo.ignition.config.data.encoding="base64" \

govc vm.network.change -vm ${vm_name} -net "${cluster_network}" -net.address ${vm_mac} ethernet-0
govc vm.info -e "${vm_name}"

if [ "${boot_vm}" == "yes" ]; then
	govc vm.power -on "${vm_name}"
fi