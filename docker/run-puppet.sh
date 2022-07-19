#!/usr/bin/env bash
BASE_PATH="/data/wandenberg-nexus3_rest"
echo "Installing Puppet module"
ln -f -s ${BASE_PATH}/docker/common.yaml /etc/puppetlabs/code/environments/production/data/common.yaml
ln -f -s ${BASE_PATH} /etc/puppetlabs/code/environments/production/modules/nexus3_rest
ln -f -s ${BASE_PATH}/docker/nexus /etc/puppetlabs/code/environments/production/modules/nexus
cp ${BASE_PATH}/docker/nexus3_rest.conf /etc/puppetlabs/puppet/nexus3_rest.conf
sed -i 's,localhost,nexus,' /etc/puppetlabs/puppet/nexus3_rest.conf

# Lets give nexus some time to start
sleep 30

puppet module install puppetlabs-stdlib

# Run puppet and show changes
puppet apply /data/wandenberg-nexus3_rest/docker/site.pp --show_diff

# Uncomment this if you want to keep puppet container running
while true; do
  sleep 5
done
