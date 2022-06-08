#!/bin/bash

# This script downloads the images used by Armory 
# Usage: imagedownloader.sh <version name>
# Prerequisites:
# - docker and creds to push to your docker registry
# - yq: a portable command-line YAML processor

PGM=$0
VERSION=$1
DESTINATION_DIR="halconfig"
SERVICES="clouddriver echo gate orca igor deck fiat front50 kayenta rosco monitoring-daemon dinghy terraformer"

if [[ $# -lt 1 ]]; then
    echo "Usage: ${PGM} <version name>"
    exit 1
fi

bom="${DESTINATION_DIR}/bom/${VERSION}.yml"
armory_address=docker.io/armory
new_registy_address=$(yq e '.artifactSources.dockerRegistry' ${bom})

set -x

for svc in $SERVICES; do
    sv=$(yq e '.services.'${svc}'.version' ${bom})
    docker pull $armory_address/${svc}:${sv}
    docker tag $armory_address/${svc}:${sv} $new_registy_address/${svc}:${sv}
    docker push $new_registy_address/${svc}:${sv}
done