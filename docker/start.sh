#!/bin/bash

${SONATYPE_DIR}/start-nexus-repository-manager.sh &

cd /nexus3_rest
bundle install
bundle exec ruby docker/setup.rb

if [ -z "${CI}" ]; then
  while true; do
    sleep 1
  done
else
  bundle exec rspec
fi
