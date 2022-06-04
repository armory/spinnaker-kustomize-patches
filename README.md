# Kustomize patches for configuring Armory Continuous Delivery

This repository contains example [Kustomize](https://kustomize.io) resources to
configure and deploy Armory Continuous Delivery to your Kubernetes cluster
using the [Armory Operator][operator-overview].

## Disclaimer

The example configurations provided in this repository serve as a starting
point for configuring Armory Continuous Delivery. You may need to modify the
contents for the target environment to work properly. These examples are not
exhaustive and don't showcase all available combinations of settings. It's
possible that not all configurations work with all versions of Armory
Continuous Delivery.

## System Requirements

See our [System Requirements] page for more details.

## All-in-one deployment script

This repo provides a one-click `deploy.sh` script that deploys the Armory
Operator in `cluster` mode and then Armory Continuous Delivery. This is useful
for a proof of concept, but you should not use this script in a production
environment.

Clone this repository and run `./deploy.sh`.

The script does the following:

* Deploys the Armory Operator to the `spinnaker-operator` namespace.
* Deploys a basic Armory Continuous Delivery instance with some default
  integrations to the `spinnaker` namespace.

If you already have the Armory Operator deployed, you can use
`SPIN_OP_DEPLOY=0` to specify not to deploy the Operator.

### Deploy open source Spinnaker

You can use `deploy.sh` to deploy Spinnaker instead of Armory Continuous
Delivery.

```bash
SPIN_FLAVOR=oss ./deploy.sh

```

When you specify `SPIN_FLAVOR=oss `, the script does the following:

* Modifies relevant patch files, replacing `apiVersion:
  spinnaker.armory.io/v1alpha2` with `apiVersion: spinnaker.io/v1alpha2`.
* Deploys the open source [Spinnaker
  Operator](https://github.com/armory/spinnaker-operator) to the
  `spinnaker-operator` namespace.
* Deploys a basic of Spinnaker to the `spinnaker` namespace.


## Add remote clusters script

For adding remote Kubernetes clusters to Armory Continuous Delivery, you can
use the helper script `secrets/create-kubeconfig.sh` to create a Kubernetes
service account (with cluster admin role) and its corresponding `kubeconfig`
file for Armory Continuous Delivery to use.

[kustomize]: https://kustomize.io
[operator-overview]: https://docs.armory.io/armory-enterprise/installation/armory-operator/
[System Requirements]: https://docs.armory.io/armory-enterprise/installation/system-requirements/
