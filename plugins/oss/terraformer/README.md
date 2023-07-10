# Armory Terraformer Plguin

This component gives you the ability to install the Terraformer plugin using
Kustomize and the Spinnaker Operator. At the time of this writing *this
particular Component does not support CDSH*, only Spinnaker.

The CDSH specific component may be found in `armory/patch-terraformer.yml`.
## Usage

A quick-start recipe is available in the `recipes/kustomization-oss-terraformer.yml`
file in the root of this project. It assumes you are starting from a clean
Kubernetes cluster and will install the Spinnaker Operator as well as a minimal
Spinnaker cluster with Terraformer enabled.

If you already have the Operator installed and an existing Kustomization file
then add the following configuration fields:

```yaml
# ... other Kustomizations

components:
  - plugins/oss/terraformer

# ... other Kustomizations
```

This will install the latest version of the Terraformer for the latest supported
version of Spinnaker by Armory. Alternatively, if you'd like to reference this
component remotely without cloning this repository you can use the following
syntax:

```yaml
# ... other Kustomizations

components:
  - git@github.com:armory/spinnaker-kustomize-patches.git/plugins/oss/terraformer

# ... other Kustomizations
```

## Compatibility Across Spinnaker Versions

If you're installing Terraformer in an older version of Spinnaker then you
will need to ensure compatibility of the plugin with Gate, Orca and Deck. Patches are
provided for all supported Spinnaker versions by Armory.

For example, to choose a version that is compatible with Spinnaker v1.27.x you
would add the following patch to your Kustomization file:

```yaml
# This patch ensures that the correct Terraformer version is selected.
patches:
  - target:
      kind: SpinnakerService
    path: plugins/oss/terraformer/versions/v-1.27.yml
```

# Customizing Terraformer Settings
```yaml
patchesStrategicMerge:
  - ./terraformer-plugin-config.yml
  
# generates the settings that will be mounted in the Terraformer container
secretGenerator:
  - name: spin-terraformer-config-file
    files:
      - terraformer.yml
      - spinnaker.yml
```

If you want to specify a named terraform profile you can create a `terraform-local.yml` file 
```yaml
profiles:
  - name: aws-with-session-tokens
    variables:
      - kind: static
        options:
          name: AWS_ACCESS_KEY_ID
          value: access-key
      - kind: static
        options:
          name: AWS_SECRET_ACCESS_KEY
          value: value-secret-access-key
      - kind: static
        options:
          name: AWS_SESSION_TOKEN
          value: session-token

```
and include it in the spin-terraformer-config file like below
```yaml
# generates the settings that will be mounted in the Terraformer container
secretGenerator:
  - name: spin-terraformer-config-file
    files:
      - terraformer-local.yml
      - terraformer.yml
      - spinnaker.yml
```
# Development

Versions of the Terraformer Plugin are not updated automatically in the `versions/`
subdirectory, they will need to be updated on each release.

Versions of the Terraformer Plugin itself will need to be updated as well in `./kustomization.yml`.
