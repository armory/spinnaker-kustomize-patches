# spinnaker-patch-files

This repository contains example [kustomize](https://kustomize.io) patch files to configure and deploy Spinnaker using the Spinnaker Operator.

### Prerequisites

* You need to have a working Kubernetes cluster, and be able to execute `kubectl` commands against that cluster, with permissions to list and create namespaces.

### Quick start

Run `./deploy.sh`. It will deploy Spinnaker Operator to `spinnaker-operator` namespace, and a base Spinnaker instance to `spinnaker` namespace with some default integrations.

### General usage

1. Comment or uncomment lines from the file `kustomization.yml` depending on what you want to be included in spinnaker. 
1. Change any of the kustomize patch files to match your desired configuration. For example changing github username, aws account id, etc.
1. Store secret literals in `secrets/secrets.env` and secret files in `secrets/files`. They are ignored by source control.
1. Run `./deploy.sh` to deploy spinnaker. 

* Namespace for the Spinnaker Operator is configured in `operator/kustomization.yml`.
* Namespace for Spinnaker and all its infrastructure is configured in `kustomization.yml`.
* Spinnaker version is configured in `spinnakerservice.yml`.

For adding remote Kubernetes clusters to Spinnaker, the helper script `secrets/create-kubeconfig.sh` can be used to create a Kubernetes service account (with cluster admin role) and its corresponding `kubeconfig` file for spinnaker to use.

### OSS Spinnaker or Armory Spinnaker

All kustomize patch files in this repository are for Armory Spinnaker distribution. For using with OSS Spinnaker you need to change their `apiVersion` by removing `armory` from it. For example, 
```
apiVersion: spinnaker.armory.io/v1alpha2
```
changes to: 
```
apiVersion: spinnaker.io/v1alpha2
```
The script `deploy.sh` automatically does this to deploy OSS Spinnaker when run with the `SPIN_FLAVOR` environment variable:
```bash
SPIN_FLAVOR=oss ./deploy.sh
```
