#!/bin/bash

# This script downloads the operator images used by Armory 
# Prerequisites:
# - docker and creds to push to your docker registry
# - yq: a portable command-line YAML processor

PGM=$0
DESTINATION_REPO=$1

if [[ $# -lt 1 ]]; then
    echo "Usage: ${PGM} <TARGET_DOCKER_ADDR>"
    exit 1
fi

if [[ ! -e deploy/operator/cluster/deployment.yaml ]]; then
    echo "Error: Could not find operator deploy/operator/cluster/deployment.yaml"
    echo "Hint: run this script from the operator folder"
    echo "      and make sure you've downloaded the operator manifests, e.g."
    echo "      curl -L https://github.com/armory-io/spinnaker-operator/releases/download/v1.2.5/manifests.tgz | tar -xz"
    exit 1
fi

echo "Confirm you want the images to be pushed to $DESTINATION_REPO"
echo "For example, resulting image will reside here: $DESTINATION_REPO/spinnaker-operator:1.2.5"
echo "Ctrl-c to quit, any key to continue"
read ans

armory_address=docker.io

set -x

operatorimage=$(yq r deploy/operator/cluster/deployment.yaml 'spec.template.spec.containers[0].image')
shortoperatorimage=${operatorimage#armory/}  #removes armory/ from the imagename
docker pull $armory_address/$operatorimage
docker tag $armory_address/$operatorimage $DESTINATION_REPO/$shortoperatorimage
docker push $DESTINATION_REPO/$shortoperatorimage
yq w -i kustomization.yml 'images[0].name' ${operatorimage%:*} 
yq w -i kustomization.yml 'images[0].newName' $DESTINATION_REPO/${shortoperatorimage%:*} # `%:*` removes the tag

halyardimage=$(yq r deploy/operator/cluster/deployment.yaml 'spec.template.spec.containers[1].image')
shorthalyardimage=${halyardimage#armory/}
docker pull $armory_address/$halyardimage
docker tag $armory_address/$halyardimage $DESTINATION_REPO/$shorthalyardimage
docker push $DESTINATION_REPO/$shorthalyardimage
yq w -i kustomization.yml 'images[1].name' ${halyardimage%:*} 
yq w -i kustomization.yml 'images[1].newName' $DESTINATION_REPO/${shorthalyardimage%:*}
