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
        --ova)
            if [ "$2" ]; then
                ova_name=$2
                shift
            else
                die 'ERROR: "--ova" requires a non-empty option argument.'
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
        --ipcfg)
            if [ "$2" ]; then
                ipcfg=$2
                shift
            else
                die 'ERROR: "--ipcfg" requires a non-empty option argument.'
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
            boot_vm=1
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

#if [ ${verbose} > 0 ]; then
	echo "Template: ${ova_name}"
	echo "Library: ${library}"
	echo "VM Name: ${vm_name}"
	echo "CPU: ${vm_cpu}"
	echo "Memory: ${vm_memory}"
	echo "Disk: ${vm_disk}"
	echo "MAC Address: ${vm_mac}"
	echo "Afterburn Network Config ${ipcfg}"
	echo "Network: ${cluster_network}"
	echo "Folder: ${cluster_folder}"
	echo "Datastore: ${cluster_datastore}"
	echo "ignition_file_path: ${ignition_file_path}"
	#fi 

govc library.deploy --folder "${cluster_folder}" "${library}/${ova_name}" "${vm_name}"
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
