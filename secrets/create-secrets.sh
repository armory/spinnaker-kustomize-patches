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

quoteRequiredRegex="[[:space:]]+"
commentedLineRegex="^[[:space:]]*#"
emptyLineRegex="^[[:space:]]*$"
SEC_FILE=$CWD/secrets.env
[[ ! -f $SEC_FILE  ]] && echo "WARNING: Missing file $SEC_FILE, loading sample secrets from $CWD/secrets-example.env instead" && SEC_FILE=$CWD/secrets-example.env
while IFS='=' read -r literalsLine; 
do
    if [[ $literalsLine =~ $commentedLineRegex || $literalsLine =~ $emptyLineRegex ]] ; then
        continue
    fi
    #echo "Including secret literal \"$(echo $literalsLine)\""
    literalsKey="${literalsLine%%=*}"
    #echo "key is ${literalsKey}"
    literalsValue="${literalsLine#*=}"
    #echo "val is ${literalsValue}"
    if [[ $literalsValue =~ $quoteRequiredRegex ]]; then
        echo "space(s) detected inside value for ${literalsKey}, so wrapping with double quotes"
        LITERALS+="--from-literal=${literalsKey}=\"${literalsValue}\" "
    else
        LITERALS+="--from-literal=${literalsKey}=${literalsValue} "
    fi
done <"$SEC_FILE"

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
