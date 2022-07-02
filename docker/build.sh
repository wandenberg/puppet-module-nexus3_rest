#!/bin/bash

BASEDIR=$(dirname "$0")
NEXUS_VERSION=${1:-3.40.1}

docker build -t nexus3_rest:${NEXUS_VERSION} -f ${BASEDIR}/Dockerfile --build-arg NEXUS_VERSION=${NEXUS_VERSION} ${BASEDIR}/..
