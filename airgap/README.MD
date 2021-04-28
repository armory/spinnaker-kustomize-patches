# AIR-GAP
Detailed instructions and docs can be found on Armory's website

This folder contains scripts and summarized instructions on how to configure Spinnaker in an air-gapped environment.

## CONTENTS
`bomdownloader.sh` - helper script that will download the Armory BOM
usage: `./bomdownloader.sh <version> <new_docker_registy>`
example: `./bomdownloader.sh 2.25.0 my.jfrog.io/myteam/armory`

`imagedownloader.sh` - helper script that downloads the Armory images and pushes them up to your docker registry. Only necessary if you cannot setup armory docker as a virtual registy.
usage: `./imagedownloader.sh <version>`
example: `./imagedownloader.sh 2.25.0`
requirements: 
* yq
* bomdownloader needs to be run prior

`operatorimageudpate.sh` - helper script that downloades the Spinnaker operator images and pushes them to your docker registry, and updates the kustomization.yml for operator to use the new docker registry location.  Run this script from the operator folder after the operator manifest has been downloaded.

usage: `../airgap/operatorimageudpate.sh <new_docker_registy>`
example: `../airgap/operatorimageudpate.sh my.jfrog.io/myteam/armory`
requirements:
* yq
* operator manifests in operator folder
