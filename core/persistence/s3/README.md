# s3 persistence

This component provides a way for you to configure Spinnaker to store cluster
metadata in S3.

## Usage

Add this component to your kustomization.yml file like so:

### Local Copy

If you have a local copy of this project, you will need to update the
`core/persistence/s3/spinnaker-config.yml` to point to your s3 bucket. Once
you've done so you can add the component to your `kustomization.yaml` file to
enable.

```yaml
kind: Kustomization

components:
  - core/persistence/s3
```


### Remote Reference

If you're referencing the remote component you will need to provide a patch in
addition to the referenced component like so:

```yaml
kind: Kustomization

components:
  # Or, if you'd like to reference this via remote url you can specify it like so
  - https://github.com/armory/spinnaker-kustomize-patches.git/core/persistence/s3

patchesStrategicMerge:
  - ./s3-bucket.yml
```

Where the patch is in the following format:

```yaml
# file: ./s3-bucket.yml
apiVersion: spinnaker.armory.io/v1alpha2
kind: SpinnakerService
metadata:
  name: spinnaker
spec:
  spinnakerConfig:
    config:
      persistentStorage:
        s3:
          bucket: CHANGEME
```
