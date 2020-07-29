# spinnaker-patch-files

This repository contains example [kustomize](https://kustomize.io) patch files to configure and deploy Spinnaker using the Spinnaker Operator.

### Prerequisites

1. You need to have a working Kubernetes cluster, and be able to execute `kubectl` commands against that cluster, with permissions to list and create namespaces.

### Quick start

1. Update the symlink `kustomization.yml` to point to the flavor of Spinnaker you want to install: `kustomization-oss.yml` for OSS Spinnaker or `kustomization-armory.yml` for Armory Spinnaker.
1. Run `./deploy.sh`. It will deploy Spinnaker Operator, and a base Spinnaker instance with some default integrations.

### General usage

This repository can be used in two ways:

1. Deploy and manage a spinnaker installation: This makes use of the helper shell scripts to install prerequisites and quickly iterate over Spinnaker changes. It's good for POCs and quick setups.
1. Serve as a repository for example configurations for specific things, like how to enable dynamic Kubernetes accounts, load custom packer templates for AWS deployments, etc. Ideally there's one kustomize patch file for each complete "feature" to use.

If using this repository to directly manage a Spinnaker instance:

* Namespace for the Spinnaker Operator is specified in script `deploy.sh`.
* Namespace for Spinnaker and its infrastructure is specified in `kustomization.yml`.
* Store secret literals in `secrets/secrets.env` and secret files in `secrets/files`.
* Comment/uncomment patches from `kustomization.yml`.
* Deploy everything with `deploy.sh`.
