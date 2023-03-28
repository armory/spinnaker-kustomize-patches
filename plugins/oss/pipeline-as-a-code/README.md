# Armory Pipeline as a Code Plguin

This component gives you the ability to install the Pipeline as a Code plugin using
Kustomize and the Spinnaker Operator. At the time of this writing *this
particular Component does not support CDSH*, only Spinnaker.

## Usage

A quick-start recipe is available in the `recipes/kustomization-oss-pac.yml`
file in the root of this project. . It assumes you are starting from a clean
Kubernetes cluster and will install the Spinnaker Operator as well as a minimal
Spinnaker cluster with Pipeline as a Code enabled.

If you already have the Operator installed and an existing Kustomization file
then add the following configuration fields:

```yaml
# ... other Kustomizations

components:
  - plugins/oss/pipeline-as-a-code

# ... other Kustomizations
```

This will install the latest verson of the Pipeline as a Code for the latest supported
version of Spinnaker by Armory. Alternatively, if you'd like to reference this
component remotely without cloning this repository you can use the following
syntax:

```yaml
# ... other Kustomizations

components:
  - git@github.com:armory/spinnaker-kustomize-patches.git/plugins/oss/pipeline-as-a-code

# ... other Kustomizations
```

## Compatibility Across Spinnaker Versions

If you're installing the Pipeline as a Code in an older version of Spinnaker then you
will need to ensure compatibility of the plugin with Gate and Echo. Patches are
provided for all supported Spinnaker versions by Armory.

For example, to choose a version that is compatible with Spinnaker v1.27.x you
would add the following patch to your Kustomization file:

```yaml
# This patch ensures that the correct PaC version is selected.
patches:
  - target:
      kind: SpinnakerService
    path: plugins/oss/pipeline-as-a-code/versions/v-1.26.yml
```

# Customizing Pipeline as a Code Settings
```yaml
patchesStrategicMerge:
  - ./pac-plugin-config.yml
  
# generates the settings that will be mounted in the PaC container
secretGenerator:
  - name: spin-dinghy-config-file
    files:
      - dinghy.yml
      - spinnaker.yml
```

# Development

Versions of the Pac Plugin are not updated automatically in the `versions/`
subdirectory, they will need to be updated on each release.

Versions of the Pac Plugin itself will need to be updated as well in `./kustomization.yml`.
