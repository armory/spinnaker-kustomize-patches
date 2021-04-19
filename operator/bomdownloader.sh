#!/bin/bash

# This script download a version of Armory's BOM to a local directory
# Usage: download.sh <version name>
# Prerequisites:
# - aws cli: https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html
# - access to public s3 installed (no need for credentials)
# - write access to the destination path
# - yq: a portable command-line YAML processor

# Change that

PGM=$0
VERSION=$1
NEW_DOCKER_REGISTRY=$2
DESTINATION_DIR="halconfig"
ARMORY_BUCKET="halconfig"
ARMORY_BUCKET_REGION="us-west-2"
SERVICES="clouddriver echo gate orca igor deck fiat front50 kayenta rosco monitoring-daemon dinghy terraformer"

if [[ $# -lt 2 ]]; then
    echo "Usage: ${PGM} <version name> <new_docker_registry_address>"
    exit 1
fi

mkdir -p ${DESTINATION_DIR}/bom
bom="${DESTINATION_DIR}/bom/${VERSION}.yml"
aws s3 cp --no-sign-request --region ${ARMORY_BUCKET_REGION} s3://${ARMORY_BUCKET}/bom/${VERSION}.yml ${bom}
for svc in $SERVICES; do
    sv=$(yq r ${bom} 'services.'${svc}'.version')
    sdir="$DESTINATION_DIR/profiles/${svc}/${sv}"
    mkdir -p $sdir
    aws s3 cp --no-sign-request --region ${ARMORY_BUCKET_REGION} --recursive --include "*" s3://${ARMORY_BUCKET}/profiles/${svc}/${sv}/ $sdir
done

sed -i '' "s/docker.io\\/armory/$(echo $NEW_DOCKER_REGISTRY | sed 's/\//\\\//g')/g" $bom

echo "Version ${VERSION} is ready to be uploaded to your private bucket."
echo "For example, with \"aws cp --recursive\"  or \"gsutil cp -m -r ...\""