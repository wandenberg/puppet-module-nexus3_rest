#!/usr/bin/env bash
BASE_PATH="/data/wandenberg-nexus3_rest"
echo "Installing Puppet module"
ln -f -s ${BASE_PATH}/docker/common.yaml /etc/puppetlabs/code/environments/production/data/common.yaml
ln -f -s ${BASE_PATH}/docker/nexus3_rest.conf /etc/puppetlabs/puppet/nexus_rest.conf
ln -f -s ${BASE_PATH} /etc/puppetlabs/code/environments/production/modules/nexus3_rest
#cp -a ${BASE_PATH} /tmp/wandenberg-nexus3_rest
#
#tar -zcf /tmp/wandenberg-nexus3_rest.tar.gz ${BASE_PATH}
#puppet module install /tmp/wandenberg-nexus3_rest.tar.gz

# Lets give nexus some time to start
#sleep 30

puppet module install puppetlabs-stdlib

# Run puppet and show changes
puppet apply /data/wandenberg-nexus3_rest/docker/site.pp --show_diff

#sleep 36000
# Uncomment this if you want to keep puppet containter running
while true; do
  sleep 5
done
