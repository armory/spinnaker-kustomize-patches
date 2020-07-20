#!/bin/bash

#--------------------------------------------------------------------------------------------
# Creates a Kubernetes secret named "spin-secrets" with files and secret values.
#
# Usage: create-secrets.sh [spinnaker namespace]
#
# - Secret literal values are read from secrets.env
# - All files in "files" folder are included in the secret
#--------------------------------------------------------------------------------------------

NAMESPACE=$1
CWD=$(dirname "$0")

if [[ "x$NAMESPACE" = "x" ]] ; then
  NAMESPACE=$(grep "^namespace:" "$CWD"/../kustomization.yml | awk '{print $2}')
  [[ "x$NAMESPACE" = "x" ]] && NAMESPACE=spinnaker
fi

echo "Secrets will be created in namespace \"$NAMESPACE\""

if ! kubectl get ns "$NAMESPACE" > /dev/null 2>&1
then
  echo "ERROR: Namespace \"$NAMESPACE\" not found. Create it first with kubectl create ns $NAMESPACE"
  echo "Usage: $0 [spinnaker namespace]"
  exit 1
fi

[[ "x$NAMESPACE" = "x" ]] && echo "Usage: $0 [spinnaker namespace]" && exit 1

if kubectl -n "$NAMESPACE" get secret spin-secrets > /dev/null 2>&1
then
  kubectl -n "$NAMESPACE" delete secret spin-secrets
fi

SEC_FILE=$CWD/secrets.env
[[ ! -f $SEC_FILE  ]] && echo "WARNING: Missing file $SEC_FILE, loading sample secrets from $CWD/secrets-example.env instead" && SEC_FILE=$CWD/secrets-example.env
while IFS= read -r l
do
  echo "Including secret literal \"$(echo $l | sed 's|=.*||')\""
  LITERALS+="--from-literal=$l "
done < <(grep -v -e '^#' -e '^$' < "$SEC_FILE")
LITERALS=${LITERALS::${#LITERALS}-1}

if [[ -d "$CWD"/files && -n "$(ls -A "$CWD"/files)" ]]; then
  for f in "$CWD"/files/*
  do
    echo "Including secret file \"$f\""
    FILES+="--from-file=$f "
  done
  FILES=${FILES::${#FILES}-1}
fi

# Create the secrets
if ! kubectl -n "$NAMESPACE" create secret generic spin-secrets $LITERALS $FILES ; then exit 1 ; fi

kubectl -n "$NAMESPACE" describe secret spin-secrets
