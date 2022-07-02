#!/bin/bash

BASEDIR=$(dirname "$0")
APP_DIR=$(cd ${BASEDIR}/.. ; pwd)
CI=$1
NAME=$2
NEXUS_VERSION=${3:-3.40.1}

if [ -z "${NAME}" ]; then
    NAME_PARAM=''
else
    NAME_PARAM="--name ${NAME}"
fi

if [ "${CI}" = "true" ]; then
  docker run -e CI=${CI} -v $APP_DIR:/nexus3_rest --rm -it nexus3_rest:${NEXUS_VERSION}
else
  id=$(docker run ${NAME_PARAM} -d -p 8081:8081 -v $APP_DIR:/nexus3_rest --rm -it nexus3_rest:${NEXUS_VERSION})
  name=$(docker inspect --format='{{.Name}}' $id | cut -c2-)
  printf "Container ${name} started.\nAccess it using:\ndocker exec -it ${name} bash\n"
fi
