# Armory Scale Agent for Kubernetes

This component gives you the ability to install the Scale Agent using
Kustomize and the Spinnaker Operator. At the time of this writing *this
particular Component does not support CDSH*, only Spinnaker.

Please consult [our existing docs] for installation in a CDSH cluster.

## Usage

A quick-start recipe is available in the `recipes/kustomization-oss-all.yml`
file in the root of this project. . It assumes you are starting from a clean
Kubernetes cluster and will install the Spinnaker Operator as well as a minimal
Spinnaker cluster with Scale Agent enabled.

If you already have the Operator installed and an existing Kustomization file
then add the following configuration fields:

```yaml
# ... other Kustomizations

components:
  - targets/kubernetes/scale-agent

# ... other Kustomizations
```

This will install the latest verson of the Scale Agent for the latest supported
version of Spinnaker by Armory. Alternatively, if you'd like to reference this
component remotely without cloning this repository you can use the following
syntax:

```yaml
# ... other Kustomizations

components:
  - git@github.com:armory/spinnaker-kustomize-patches.git/targets/kubernetes/scale-agent

# ... other Kustomizations
```

## Compatibility Across Spinnaker Versions

If you're installing the Scale Agent in an older version of Spinnaker then you
will need to ensure compatibility of the plugin with Clouddriver. Patches are
provided for all supported Spinnaker versions by Armory.

For example, to choose a version that is compatible with Spinnaker v1.27.x you
would add the following patch to your Kustomization file:

```yaml
# This patch ensures that the correct Scale Agent plugin version is selected.
patches:
  - target:
      kind: SpinnakerService
    path: targets/kubernetes/scale-agent/versions/v1-26.yml
```

## Specifying a Custom Repository

If for some reason you're unable to source plugin metadata from an external
source, you can mirror the repository information within your network boundary
and tell Spinnaker how to source plugin information with the following patch:

```yaml
# This patch ensures that a custom repository is used. You will need to modify
# this file with the location of your repository information.
patches:
  - target:
      kind: SpinnakerService
    path: targets/kubernetes/scale-agent/custom-repository.yml
```

# Customizing Scale Agent Settings
```yaml
patchesStrategicMerge:
  - ./plugin-config.yml
  - ./agent-config.yml # patches the deployment to mount the configuration file
  
# generates the settings that will be mounted in the agent container
configMapGenerator:
- name: agent-config
  files:
  - armory-agent.yaml
```

## Adding static accounts
Static Accounts are added by modifying the armory-agent.yml file:
```yaml
kubernetes:
  accounts:
   - kubeconfigFile: /kubeconfigfiles/kubeconfig
     name: account1
```

```yaml
patchesStrategicMerge:
  - ./plugin-config.yml
  - ./agent-config.yml # includes the armory-agent.yml settings file
  - ./kubeconfig-volume.yml # patches the deployment to include the kubeconfig dir mount

  secretGenerator:
  - name: kubeconfig-secret
    options:
      disableNameSuffixHash: true
    files:
      - kubeconfig #Make sure it points to a valid kubeconfig
```


# Development

Versions of the Scale Agent are not updated automatically in the `versions/`
subdirectory, they will need to be updated on each release.

Versions of the Scale Agent itself will need to be updated as well in `./kustomization.yml`.

[cdsh-scale-agent-docs]: https://docs.armory.io/scale-agent/install/install-agent-plugin/
