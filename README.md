# spinnaker-patch-files

This repository contains example [kustomize](https://kustomize.io) patch files to configure and deploy Spinnaker using the [Spinnaker Operator](https://github.com/armory/spinnaker-operator).

### Prerequisites

You need to have a working Kubernetes cluster, and be able to execute `kubectl` commands against that cluster, with permissions to list and create namespaces.

### Usage

1. Enable/disable Spinnaker features by commenting/uncommenting patches in `kustomization.yml`.
2. Modify configurations as needed.
3. Copy the file `secrets/secrets-example.env` to `secrets/secrets.env` and add or change any needed secret literal values, and add any needed secret files to `secrets/files` folder. Run `./secrets/create-kubeconfig.sh` if needed to create kubeconfig files for connecting to remote clusters.
4. Run `./secrets/create-secrets.sh` to deploy all secrets to Kubernetes in the namespace where Spinnaker will be installed.
5. If you have `kustomize` available (preferred), run `kustomize build . | kubectl -n <spinnaker namespace> apply -f -`. Otherwise to use an older version run `kubectl -n <spinnaker namespace> apply -k .`
