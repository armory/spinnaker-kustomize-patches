# Kustomize patches for configuring Armory Enterprise

This repository contains example [Kustomize](https://kustomize.io) patch files to configure and deploy Armory Enterprise to your Kubernetes cluster using the [Armory Operator](https://docs.armory.io/docs/installation/operator/). See the Armory Operator [docs](https://docs.armory.io/docs/installation/armory-operator/) to learn how the Operator works and how to configure Armory Enterprise using Kustomize patches.


## Disclaimer

The example configurations provided in this repository serve as a starting point for configuring Armory Enterprise. You may need to modify the contents for the environment where Armory Enterprise is running to work properly. These examples are not exhaustive and don't showcase all available combinations of settings. It's possible that not all configurations work with all versions of Armory Enterprise.

## Kubernetes requirements

You need to have a working Kubernetes 1.13-1.19 cluster and be able to execute `kubectl` commands against that cluster, with permissions to list and create namespaces.

## All-in-one deployment script

This repo provides a one-click `deploy.sh` script that deploys the Armory Operator in `cluster` mode and then Armory Enterprise. This is useful for a proof of concept, but you should not use this script in a production environment.

Clone this repository and run `./deploy.sh`.

The script does the following:

* Deploys the Armory Operator to the `spinnaker-operator` namespace.
* Deploys a basic Armory Enterprise instance with some default integrations to the `spinnaker` namespace.

If you already have the Armory Operator deployed, you can use `SPIN_OP_DEPLOY=0` to specify not to deploy the Operator.

### Deploy open source Spinnaker

You can use `deploy.sh` to deploy Spinnaker instead of Armory Enterprise.

```bash
SPIN_FLAVOR=oss ./deploy.sh

```

When you specify `SPIN_FLAVOR=oss `, the script does the following:

* Modifies relevant patch files, replacing `apiVersion: spinnaker.armory.io/v1alpha2` with `apiVersion: spinnaker.io/v1alpha2`.
* Deploys the open source [Spinnaker Operator](https://github.com/armory/spinnaker-operator) to the `spinnaker-operator` namespace.
* Deploys a basic of Spinnaker to the `spinnaker` namespace.


## Add remote clusters script

For adding remote Kubernetes clusters to Armory Enterprise, you can use the helper script `secrets/create-kubeconfig.sh` to create a Kubernetes service account (with cluster admin role) and its corresponding `kubeconfig` file for Armory Enterprise to use.
