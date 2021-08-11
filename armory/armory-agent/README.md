1. Use the following command to retrieve the gRPC LB address
```
kubectl get svc spin-agent-clouddriver -n spinnaker
```
2. Install Armory Agent for Kubernetes _(Don't forget to add :9091 at the end)_:
```
export GRPC_ADDR=<EXERNAL IP OR ADDRESS FROM STEP 4>:9091
```
```
export CLUSTER_NAME="Agent-Spinnaker"
```
```
kubectl apply -k armory/armory-agent/overlays/<ARMORY VERSION>
```
3. Use the following command to watch the spinnaker pods update. Wait until all terminating pods are replaced by running pods. Use ```CTL``` + ```C``` to exit.

```
watch kubectl get po -n spinnaker
```

4. Test your install by configuring a ```Deploy Manifest``` stage that targets your new ```Agent-Spinnaker```
cluster account.