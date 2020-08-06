#!/bin/bash

#---------------------------------------------------------------------------------
# Creates the following:
#
# - Kubernetes service account in default namespace, with cluster-admin role
# - kubeconfig file for service account
#---------------------------------------------------------------------------------

ACCOUNT_NAME=$1
NAMESPACE=${2:-default}
CWD=$(dirname "$0")

[[ "x$ACCOUNT_NAME" = "x" ]] && echo "Usage: $0 account-name" && exit 1

# Create Service Account
echo "Creating service account spin-sa in namespace \"$NAMESPACE\" with cluster admin privileges"
cat << EOF | kubectl -n "$NAMESPACE" apply -f - > /dev/null
apiVersion: v1
kind: ServiceAccount
metadata:
  name: spin-sa
  namespace: $NAMESPACE

---

apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: spin-sa-$NAMESPACE
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: spin-sa
  namespace: $NAMESPACE
EOF
    
# Get SA token
SECRET_NAME=$(kubectl -n "$NAMESPACE" get secrets | grep spin-sa | awk '{print $1}')
TOKEN=$(kubectl -n "$NAMESPACE" describe secret "$SECRET_NAME" | grep "token:" | awk '{print $2}')

# Generate kubeconfig
echo "Generating kubeconfig in $CWD/files/kubecfg-$ACCOUNT_NAME"
KUBECONFIG=$(kubectl config view --minify --raw | sed '/user:$/,$d')
KUBECONFIG+="\n  user:"
KUBECONFIG+="\n    token: $TOKEN\n"

echo -ne "$KUBECONFIG" > "$CWD"/files/kubecfg-"$ACCOUNT_NAME"

echo "Encrypted reference for using in spinnaker configuration: \"kubeconfigFile: encryptedFile:k8s!n:spin-secrets!k:kubecfg-$ACCOUNT_NAME\""