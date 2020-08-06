#!/bin/bash

#--------------------------------------------------------------------------------------------------------------------------
# Usage: ./deploy.sh
#
# This script does the following:
# 1. Installs the latest version of operator if not already installed,
#    by looking at symlink kustomization.yml to detect the right flavor (oss or armory).
# 2. Deploys spinnaker secrets
# 3. Deploys spinnaker with kubectl
#--------------------------------------------------------------------------------------------------------------------------

OPERATOR_NS=spinnaker-operator
FLAVOR=armory

ROOT_DIR="$( cd "$(dirname "$0")" >/dev/null 2>&1 || exit 1 ; pwd -P )"
OUT="$ROOT_DIR/log.txt"

function log() {
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  NC='\033[0m'
  LEVEL=$1
  MSG=$2
  case $LEVEL in
  "INFO") COLOR=$GREEN ;;
  "ERROR") COLOR=$RED ;;
  esac
  printf "${COLOR}[%-5.5s]${NC} %b" "${LEVEL}" "${MSG}"
}

function info() {
  log "INFO" "$1"
}

function error() {
  log "ERROR" "$1" && exit 1
}

function check_prerequisites() {
  if ! kubectl get ns > /dev/null 2>&1 ; then
    error "Unable to list namespaces of the kubernetes cluster:\n$(kubectl get ns)"
  fi

  if ! command -v jq &>/dev/null; then
    error "'jq' is not installed."
  fi

  if ! command -v kustomize &>/dev/null; then
    HAS_KUSTOMIZE=0
  else
    HAS_KUSTOMIZE=1
    KUST_OUT=$(kustomize build . 2>&1)
    [[ $? != 0 ]] && error "Kustomize build returned an error:\n$KUST_OUT\n"
  fi
  if ! command -v watch &>/dev/null; then
    HAS_WATCH=0
  else
    HAS_WATCH=1
  fi
}

case $FLAVOR in
"oss") CRD=spinnakerservices.spinnaker.io && OP_URL=https://github.com/armory/spinnaker-operator/releases/latest/download/manifests.tgz ;;
"armory") CRD=spinnakerservices.spinnaker.armory.io && OP_URL=https://github.com/armory-io/spinnaker-operator/releases/latest/download/manifests.tgz ;;
esac

function assert_crd() {
  info "Resolved operator namespace: $OPERATOR_NS\n"
  if [[ $(kubectl get crd | grep "$CRD" 2>"$OUT") == "" ]]; then
    CRD_READY=0
    EXISTING_CRD=$(kubectl get crd | grep "spinnakerservices.spinnaker" | awk '{print $1}' 2>"$OUT")
    if [[ "$EXISTING_CRD" != "" ]]; then
      info "Expected operator flavor \"$FLAVOR\" but detected a different one, uninstalling the other operator.\n"
      {
        kubectl delete crd "$EXISTING_CRD"
        kubectl delete crd spinnakeraccounts.spinnaker.io
        kubectl -n $OPERATOR_NS delete deployment spinnaker-operator
      } >>"$OUT" 2>&1
    fi
  else
    CRD_READY=1
  fi
}

function check_operator_status() {
  {
    OP_STATUS=$(kubectl -n $OPERATOR_NS get pods | grep spinnaker-operator | awk '{print $2}')
  } >> "$OUT" 2>&1
}

function assert_operator() {
  assert_crd
  check_operator_status
  if [[ $CRD_READY == 0 || "$OP_STATUS" != "2/2" ]]; then
    info "Deploying $FLAVOR operator from url $OP_URL."
    {
      rm -rf "$ROOT_DIR/operator"
      mkdir -p "$ROOT_DIR/operator" && cd "$ROOT_DIR/operator" || exit 1
      curl -L $OP_URL | tar -xz
      kubectl apply -f deploy/crds/
      if ! kubectl get ns "$OPERATOR_NS" >/dev/null 2>&1; then
        kubectl create ns $OPERATOR_NS
      fi
      sed "s|.*# edit if you want the operator to live somewhere besides here|  namespace: $OPERATOR_NS   # edit if you want the operator to live somewhere besides here|" \
        "$ROOT_DIR"/operator/deploy/operator/cluster/role_binding.yaml >"$ROOT_DIR"/operator/deploy/operator/cluster/role_binding.yaml.new
      mv "$ROOT_DIR"/operator/deploy/operator/cluster/role_binding.yaml.new "$ROOT_DIR"/operator/deploy/operator/cluster/role_binding.yaml
      kubectl -n $OPERATOR_NS apply -f deploy/operator/cluster
    } >>"$OUT" 2>&1
    check_operator_status
    while [[ "$OP_STATUS" != "2/2" ]]; do
      echo -ne "."
      sleep 2
      check_operator_status
    done
    echo -ne "Done\n"
    OP_IMAGE=$(kubectl -n $OPERATOR_NS get deployment spinnaker-operator -o json | jq '.spec.template.spec.containers | .[] | select(.name | contains("spinnaker-operator")) | .image')
    info "Operator flavor: $FLAVOR, version: $OP_IMAGE\n"
    cd "$ROOT_DIR" || exit 1
  else
    OP_IMAGE=$(kubectl -n $OPERATOR_NS get deployment spinnaker-operator -o json | jq '.spec.template.spec.containers | .[] | select(.name | contains("spinnaker-operator")) | .image')
    info "Operator flavor: $FLAVOR, version: $OP_IMAGE\n"
  fi
}

function deploy_secrets() {
  SPIN_NS=$(grep "^namespace:" "$ROOT_DIR"/kustomization.yml | awk '{print $2}')
  [[ "x$SPIN_NS" == "x" ]] && SPIN_NS=spinnaker
  info "Resolved spinnaker namespace: $SPIN_NS\n"
  info "Deploying secrets..."
  {
    if ! kubectl get ns "$SPIN_NS" >/dev/null 2>&1; then
      kubectl create ns $SPIN_NS
    fi
    "$ROOT_DIR"/secrets/create-secrets.sh
  } >>"$OUT" 2>&1
  echo -ne "Done\n"
}

function deploy_dependency_crd {
  if grep "^  - infrastructure/prometheus-grafana" kustomization.yml > /dev/null 2>&1 ; then
    info "Deploying prometheus crds..."
    DEPLOY_OUTPUT=$(kubectl apply -f "$ROOT_DIR"/infrastructure/prometheus-grafana/crd.yml 2>&1)
    [[ $? != 0 ]] && echo "" && error "Error deploying prometheus crds:\n$DEPLOY_OUTPUT\n"
    echo -ne "Done\n"
  fi
}

function deploy_spinnaker() {
  deploy_dependency_crd
  info "Deploying spinnaker..."
  DEPLOY_OUTPUT=$(kubectl -n $SPIN_NS apply -k . 2>&1)
  [[ $? != 0 ]] && echo "" && error "Error deploying spinnaker:\n$DEPLOY_OUTPUT\n"
  echo -ne "$DEPLOY_OUTPUT" >> "$OUT"
  sleep 5
  echo -ne "Done\n"
}

check_prerequisites
assert_operator
deploy_secrets
deploy_spinnaker
if [[ $HAS_WATCH == 1 ]]; then
  watch "kubectl -n $SPIN_NS get spinsvc && echo "" && kubectl -n $SPIN_NS get pods"
else
  info "=== Consider installing \"watch\" command to monitor installation progress"
  kubectl -n $SPIN_NS get spinsvc && echo "" && kubectl -n $SPIN_NS get pods
fi
