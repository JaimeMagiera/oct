#!/bin/bash

die() {
    echo "$1"
    exit 1
}

show_help() {
        echo ""	
	echo "Test Hostname"
	echo ""
	echo "This script attempts to ssh into a Fedora CoreOS node to determine if the Transient Hostname matches the Fully Qualified Domain Name for the purposes of debugging OKD issue #394 https://github.com/openshift/okd/issues/394. The script outputs the results to console and to a file of the name format 'test-hostname-report-m-d-y-HMS.log". Be sure to load in your ssh key for the ssh user before running the script. 
	echo ""
	echo "Syntax:"
        echo "test-hostname.sh --fqdn <fqdn>"
	echo ""
	echo "options:"
	echo "-fqdn The Fully Qualified Domain Name of the node you wish to test"
	echo ""
	echo "Example:"
        echo "./test-hostname.sh --fqdn mynode.company.com"	
	echo ""
	exit 0;
}


while :; do
    case $1 in
        -h|-\?|--help)
            show_help
            exit
            ;;
        --fqdn)
            if [ "$2" ]; then
                vm_fqdn=$2
                shift
            else
                die 'ERROR: "--fqdn" requires a non-empty option argument.'
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





while true; do
	echo "Testing..."
        if transient_name=$(ssh -o StrictHostKeyChecking=accept-new -t core@${vm_fqdn} "sudo hostnamectl --transient"); then
                current_timstamp=$(date +"%m-%d-%y-%H%M%S")
		output_filename="test_hostname_report_${current_timstamp}.log"
		echo "Timestamp: ${current_timstamp}" > ${output_filename} 
		echo "FQDN: ${vm_fqdn}" >> ${output_filename} 
		echo "Transient Name: ${transient_name}" >> ${output_filename} 
		if [[ ${transient_name} == ${vm_name} ]]; then
			echo "Transient hostname matches dns name" >> ${output_filename} 
                else
			echo "Transient hostname does not match DNS name" >> ${output_filename} 
                        echo "========== Grabbing hosts from nswitch ==========" >> ${output_filename} 
                        ssh -o LogLevel=QUIET -t core@${vm_fqdn} "grep hosts /etc/nsswitch.conf" >> ${output_filename} 
                        echo "========== Checking active status of systemd-resolved ==========" >> ${output_filename} 
                        ssh -o LogLevel=QUIET -t core@${vm_fqdn} "systemctl is-active systemd-resolved" >> ${output_filename} 
                        echo "========== Checking enabled status of systemd-resolved ==========" >> ${output_filename}
		       	ssh -o LogLevel=QUIET -t core@${vm_fqdn} "systemctl is-enabled systemd-resolved" >> ${output_filename}	
                        echo "========== Checking rpm-ostree status ==========" >> ${output_filename} 
                        ssh -o LogLevel=QUIET -t core@${vm_fqdn} "rpm-ostree status" >> ${output_filename} 
                fi
		cat ${output_filename}
                break
        else
                echo "Host not available"
                sleep 20
        fi
done
