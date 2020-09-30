#!/bin/sh
bin/openshift-install create manifests --dir=$(pwd)
rm -f openshift/99_openshift-cluster-api_master-machines-*.yaml openshift/99_openshift-cluster-api_worker-machineset-*.yaml
sed -i -e s/true/false/g manifests/cluster-scheduler-02-config.yml
bin/openshift-install create ignition-configs --dir=$(pwd)

# Change timeouts for Master
sed -i "s/\"timeouts\":{}/\"timeouts\":{\"httpResponseHeaders\":50,\"httpTotal\":600}/g" master.ign

# Change timeouts for Worker
sed -i "s/\"timeouts\":{}/\"timeouts\":{\"httpResponseHeaders\":50,\"httpTotal\":600}/g" worker.ign

sudo mv bootstrap.ign /var/www/html/bootstrap.ign
sudo chown apache:apache /var/www/html/bootstrap.ign
sudo restorecon -Rv /var/www/html/

