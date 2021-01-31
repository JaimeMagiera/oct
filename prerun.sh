#!/bin/sh
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
sudo /usr/bin/restorecon -Rv /var/www/html/

