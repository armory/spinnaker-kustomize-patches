#!/usr/bin/env bash

NAMESPACE=$1
CWD=$(dirname "$0")

if [[ "x$NAMESPACE" = "x" ]] ; then
  NAMESPACE=$(grep "^namespace:" "$CWD"/../kustomization.yml | awk '{print $2}')
  [[ "x$NAMESPACE" = "x" ]] && NAMESPACE=spinnaker
fi

echo "Secrets will be created in namespace \"$NAMESPACE\""

kubectl -n "$NAMESPACE" create secret docker-registry regcred \
    --docker-server=docker.io \
    --docker-username="$(read -p 'Username: ' user; echo "$user")" \
    --docker-password="$(read -s -p 'Password: ' password; echo "$password")"

