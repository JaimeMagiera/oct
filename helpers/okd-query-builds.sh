#!/bin/bash

version="0.1.0"

die() {
	echo "${1}"
	exit "${2}"
}

show_help() {
	echo -e "\nOKD Query Builds v${version}\n"
	echo -e "Parameters\n"
	echo -e "  --version: The OKD minor version to query\n"
	echo -e "  --auto: Optional flag to automatically download the respective tools for the selected build.\n"
	echo -e "  --test: Go through the motions, but don't actually make changes.\n"
	echo -e "  --debug: Output debugging information.\n"
	echo -e "  --help: Output this help text.\n"
	echo -e "Examples\n"
	echo -e "  Query builds for OKD 4.17:"
	echo -e "  ./okd-query-builds.sh --version 4.17\n"
}

while :; do
	case $1 in
		-h|-\?|--help)
			show_help
			exit
			;;
                --version)
                        if [ "$2" ]; then
                                version=$2
                                shift
                        else
                                die 'ERROR: "--version" requires a non-empty option argument.' 1
                        fi
                        ;; 
		--auto)
		        auto_download=1
			echo "Auto: True"
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


function query_builds() {
  if [ -v debug ]; then
	echo "query_builds()"
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
		echo "No accepted builds for ${release_name} available."
	        exit 0	
	  fi 				  

	  index=0
	  echo "Available Builds:"
	  for build in ${accepted_array[@]}; do
		echo "[${index}]: ${build}"
		((++index))
	  done
	  read -p "Please enter your selection: " selection
	  selected_release="${accepted_array[${selected_release}]}"
	  echo "${selected_release}"
	  if [[ -v auto_download ]]; then
			echo "Downloading and extracting the tools..."
		  	oc adm release extract --tools registry.ci.openshift.org/origin/release-scos:"${selected_release}"
	  fi 
  else
          die "Could not retrieve html.\nError: ${response_code}" 10
  fi
}

query_builds
