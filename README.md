# Kustomize Patches for Armory

This repository contains example [Kustomize](https://kustomize.io) patch files to configure and deploy Armory using the [Armory Operator](https://docs.armory.io/docs/installation/operator/), which is a Kubernetes Operator for installing Armory.

The Armory Operator has `basic` and a `cluster` modes.

Functionality                                   | `basic` | `cluster`
:-----------------------------------------------|:-------:|:--------:
Can configure with single file                  |    Y    |     Y
Can configure with kustomize patches            |    Y    |     Y
Operator performs pre-flight checks/validations |    N    |     Y
Requires Kubernetes 'cluster role'              |    N    |     Y

Even though you can configure Armory in a single `SpinnakerService.yml` file, the advantage of using patch files is that each config section is its own file, with a `kustomization.yml` file that uses the patch files to build a deployment file. The Kustomize approach provides readability, consistency across environments, and maintenance manageability.  See the [Managing Configuration](https://docs.armory.io/docs/installation/operator/#managing-configuration) section of the Spinnaker Operator docs for details and examples.

This repo provides one-click installation of the Armory Operator (`cluster` mode) and Armory via the `deploy.sh` script. You don't have to read the Armory Operator documentation before you start, configure a manifest, or execute several commands to install Armory - `deploy.sh` does it all! Additionally, this repo has many example patch files that you can easily modify to match your environment - no more creating YAML files from scratch!

## Disclaimer

The example configurations provided in this repository serve as a starting point for configuring Armory. You may need to modify the contents for the environment where Armory is running to work properly. These examples are not exhaustive and don't showcase all available combinations of settings. It's possible that not all configurations work with all versions of Armory.

You can use these patch files, with modification, to configure a Spinnaker<sup>TM</sup> instance installed using the the open source [Spinnaker Operator](https://github.com/armory/spinnaker-operator). You need to change the `apiVersion` by removing `armory` from it. For example,

```
apiVersion: spinnaker.armory.io/v1alpha2
```

changes to:

```
apiVersion: spinnaker.io/v1alpha2
```

The `deploy.sh` script automatically does this to deploy Spinnaker when you run it with the `SPIN_FLAVOR` environment variable:

```bash
SPIN_FLAVOR=oss ./deploy.sh

```

## Prerequisites

You need to have a working Kubernetes cluster and be able to execute `kubectl` commands against that cluster, with permissions to list and create namespaces.

### Quick start

Clone this repository and run `./deploy.sh`.

This will deploy the Armory Operator to the `spinnaker-operator` namespace, and a base Armory instance to the `spinnaker` namespace with some default integrations.

## General usage

1. Make a link from `kustomization.yml` to one of the example kustomization files in `recipes` folder depending on your use case.
1. Modify `kustomization.yml` by adding or removing patches depending on what you want to be included in spinnaker. [Kustomization Reference Documentation describes the syntax of this file](https://kubectl.docs.kubernetes.io/pages/reference/kustomize.html).
1. Change any of the kustomize patch files to match your desired configuration. For example changing github username, aws account id, etc.
1. Store secret literals in `secrets/secrets.env` and secret files in `secrets/files` if you want to store spinnaker secrets in Kubernetes. They are ignored by source control.
1. Run `./deploy.sh` to deploy spinnaker.

* Namespace for the Spinnaker Operator is configured in `operator/kustomization.yml`.
* Namespace for Spinnaker and all its infrastructure is configured in `kustomization.yml`.
* Spinnaker version is configured in `spinnakerservice.yml`.
* Environment variable `SPIN_OP_DEPLOY` can be passed to deploy script to manage operator (default) or not (i.e. `SPIN_OP_DEPLOY=0 ./deploy.sh`)

For adding remote Kubernetes clusters to Spinnaker, the helper script `secrets/create-kubeconfig.sh` can be used to create a Kubernetes service account (with cluster admin role) and its corresponding `kubeconfig` file for spinnaker to use.

## Resources

* [Armory Operator](https://docs.armory.io/docs/installation/operator/)
* [Armory Operator Configuration](https://docs.armory.io/docs/installation/operator-reference/operator-config/)
* [Kustomize](https://kustomize.io)

