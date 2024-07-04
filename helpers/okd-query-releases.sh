#!/bin/bash

version="0.2.0"

die() {
	echo "${1}"
	exit "${2}"
}

show_help() {
	echo -e "\nOKD Query Releases v${version}\n"
	echo -e "Parameters\n"
	echo -e "  --version: The OKD minor version to query\n"
	echo -e "  --select: Used in conjunction with select, allows you to select a particular release and extract the respective tools.\n"
	echo -e "  --auto: Optional flag to automatically download the respective tools for the latest available release.\n"
	echo -e "  --test: Go through the motions, but don't actually make changes.\n"
	echo -e "  --debug: Output debugging information.\n"
	echo -e "  --help: Output this help text.\n"
	echo -e "Examples\n"
	echo -e "  Query releases for OKD 4.17:"
	echo -e "  ./okd-query-releases.sh --version 4.17\n"
	echo -e "  Query releases for OKD 4.17 and select which version to extract the tools for:"
        echo -e "  ./okd-query-releases.sh --version 4.17 --select\n"
}

while :; do
	case $1 in
		-h|-\?|--help)
			show_help
			exit
			;;
                --version)
                        if [ "$2" ]; then
                                selected_version=$2
                                shift
                        else
                                die 'ERROR: "--version" requires a non-empty option argument.' 1
                        fi
                        ;;
		--filter)
                        if [ "$2" ]; then
				filter=$2
                                shift
                        else
                                die 'ERROR: "--filter" requires a non-empty option argument.' 1
                        fi
                        ;;
                --select)
                        select_release=1
                        ;;			
		--auto)
		        auto_download=1
			;;
	        --test)
                        test_run=1
			echo "Running test..."
                        ;;
		--debug)
                        debug=1
                        echo "Running in debug mode..."
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


function list_releases() {
	releases=("$@")
	for release in "${releases[@]}"; do
        	echo "${release}"
        done
}	

function select_release() {

	releases=("$@")
	index=0
        echo "Available Releases:"
        for release in ${releases[@]}; do
        	echo "[${index}]: ${release}"
                ((++index))
        done
        read -p "Please enter your selection: " selection
        selected_release="${releases[${selection}]}"
        echo "${selected_release}"
        extract_tools "${selected_release}"
}	

function extract_tools() {
	echo "Downloading and extracting the tools..."
	if [[ -v filter ]]; then
        	oc adm release extract --tools registry.ci.openshift.org/origin/release-scos:"${1}" --filter-by-os="${filter}" --command-os "${filter}"
	else
		oc adm release extract --tools registry.ci.openshift.org/origin/release-scos:"${1}"
	fi 	
	echo "Done."
}	

function query_releases() {
	version="${1}"
  	if [ -v debug ]; then
		echo "query_releases()"
  	fi
  	release_name="${version}.0-0.okd-scos"
  	query_url="https://amd64.origin.releases.ci.openshift.org/releasestream/${release_name}"
  	response=$(curl  -S -s --write-out '#RESPONSE_CODE%{response_code}' --request GET "${query_url}")
  	html_component=$(echo "${response}" | awk -F '#RESPONSE_CODE' '{ print $1 }')
  	response_code=$(echo "${response}" | awk -F '#RESPONSE_CODE' '{ print $2 }')

  	if [ "${response_code}" -eq "200" ]; then
		accepted_text=$(echo "${html_component}" | grep "Accepted" -B 2 | awk -F "release/" '{print $2}' | awk -F "\"" '{print $1}' | xargs)
	  	accepted_array=($accepted_text)
	  	if [ ${#accepted_array[@]} -eq 0 ]; then
			echo "No accepted releases for ${release_name} available."
	        	exit 0	
	  	fi 				  
		if [[ -v select_release ]]; then	
		  	select_release "${accepted_array[@]}"
		else
			list_releases "${accepted_array[@]}"
		fi	
  else
          die "Could not retrieve html.\nError: ${response_code}" 10
  fi
}

function decision_tree() {
	if [[ -v selected_version ]]; then
		query_releases "${selected_version}"
	else
		query_releases "4.17"
		query_releases "4.16"
	fi			
}	

decision_tree
