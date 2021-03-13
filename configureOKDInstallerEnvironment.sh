#!/bin/sh
install_folder=$1

#okd_install_url="https://github.com/openshift/okd/releases/download/4.6.0-0.okd-2021-01-23-132511/openshift-install-linux-4.6.0-0.okd-2021-01-23-132511.tar.gz"
okd_install_url="https://github.com/openshift/okd/releases/download/4.6.0-0.okd-2021-01-17-185703/openshift-install-linux-4.6.0-0.okd-2021-01-17-185703.tar.gz"

#okd_client_url="https://github.com/openshift/okd/releases/download/4.6.0-0.okd-2021-01-23-132511/openshift-client-linux-4.6.0-0.okd-2021-01-23-132511.tar.gz" 

okd_client_url="https://github.com/openshift/okd/releases/download/4.6.0-0.okd-2021-01-17-185703/openshift-client-linux-4.6.0-0.okd-2021-01-17-185703.tar.gz"

fcos_image_url="https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/32.20201104.3.0/x86_64/fedora-coreos-32.20201104.3.0-vmware.x86_64.ova"


mkdir $1/bin
echo "Downloading the OKD installer..."
wget -O "openshift-install-linux.tar.gz" "${okd_install_url}"
tar xvf openshift-install-linux.tar.gz
mv openshift-install bin/
rm openshift-install-linux.tar.gz

echo "Downloading the OC client..."
wget -O "oc.tar.gz" "${okd_client_url}"
tar xvf oc.tar.gz
mv oc bin/
mv kubectl bin/
rm README.md
rm oc.tar.gz

#echo "Downloading Fedora CoreOS image..."
#wget "${fcos_image_url}"
