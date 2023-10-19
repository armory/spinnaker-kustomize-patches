# Kustomize patches for configuring Armory Continuous Deployment

This repository contains example [Kustomize](https://kustomize.io) resources to
configure and deploy Armory Continuous Deployment to your Kubernetes cluster
using the [Armory Operator][operator-overview].

## Disclaimer

The example configurations provided in this repository serve as a starting
point for configuring Armory Continuous Deployment. You may need to modify the
contents for the target environment to work properly. These examples are not
exhaustive and don't showcase all available combinations of settings. It's
possible that not all configurations work with all versions of Armory
Continuous Delivery.

## System Requirements

See our [System Requirements] page for more details.

## Components

This repository makes use of [Kustomize Components] to make configuration
simpler for evaluation purposes.

### Persistence

There are two options for persisting cluster metadata. For instructions on
configuring each, consult the associated READMEs.

- [in-cluster]
- [s3][s3-persistence]

[Kustomize Components]: https://github.com/kubernetes/enhancements/blob/master/keps/sig-cli/1802-kustomize-components/README.md
[in-cluster]: core/persistence/in-cluster/README.md
[s3-persistence]: core/persistence/s3/README.md

## All-in-one deployment script

This repo provides a one-click `deploy.sh` script that deploys the Armory
Operator in `cluster` mode and then Armory Continuous Deployment. This is useful
for a proof of concept, but you should not use this script in a production
environment.

Clone this repository and run `./deploy.sh`.

The script does the following:

* Deploys the Armory Operator to the `spinnaker-operator` namespace.
* Deploys a basic Armory Continuous Deployment instance with some default
  integrations to the `spinnaker` namespace.

The script also provide variables based on customize usage, you can set those variables as environment before execute the script 

**Variable**
- **SPIN_FLAVOR**: Distribution of spinnaker operator to deploy _(default: armory)_
  + `armory`
  + `oss`

- **SPIN_OP_DEPLOY** : Deploy Operator or not. _(default: 1)_
  + Set to `0` to **skip** deploy Operator
  + Set to `1`  to deploy the operator. 
    > When deploying, if we already one running operator in our cluster with the same namespace. It will delete the old one automatically

- **SPIN_OP_VERSION** : Define the version of operator we want to deploy _(default: latest)_, check https://github.com/armory/spinnaker-operator/releases for the list release version

- **SPIN_OP_NS**: Specify the namespace of operator _(default: spinnaker-operator)_

- **SPIN_OP_MODE**: Distribution of Spinnaker operator mode to use _(default: cluster)_
  + `basic`
  + `cluster`
  > Currently, this script isn't support for `helm` mode. If you want to deploy operator with helm, please deploy it manually and set variable `SPIN_OP_DEPLOY`

- **SPIN_WATCH**: Watch/Wait for spinnaker to come up or not _(default: 1)_
  + Set to `0` to **skip**
  + Set to `1`  to watch/wait

### Deploy open source Spinnaker

1. You can use oss recipes to deploy Spinnaker instead of Armory Continuous Delivery.
    ```shell
    # Delete default recipe
    rm kustomization.yml

    # Create symlink for oss recipe
    ln -s ./recipes/kustomization-oss-minimum.yml kustomization.yml
    ```

    When you use an oss recipe, it does the following:

    * Modifies relevant patch files, replacing `apiVersion:
      spinnaker.armory.io/v1alpha2` with `apiVersion: spinnaker.io/v1alpha2`.
    * Deploys a basic of Spinnaker to the `spinnaker` namespace.

1. Execute `deploy.sh` script to deploy **Spinnaker Operator**, with latest version, and **Spinnaker**

## Add remote clusters script

For adding remote Kubernetes clusters to Armory Continuous Deployment, you can
use the helper script `secrets/create-kubeconfig.sh` to create a Kubernetes
service account (with cluster admin role) and its corresponding `kubeconfig`
file for Armory Continuous Deployment to use.

[kustomize]: https://kustomize.io
[operator-overview]: https://docs.armory.io/armory-enterprise/installation/armory-operator/
[System Requirements]: https://docs.armory.io/armory-enterprise/installation/system-requirements/
