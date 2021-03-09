#!/bin/bash

#--------------------------------------------------------------------------------------------------------------------------
# Usage: ./deploy.sh
#
# This script does the following:
# 0. If "oss" flavor was specified, it changes all kustomize patches to be spinnaker oss compliant
# 1. Installs the latest version of operator if not already installed
# 2. Deploys spinnaker secrets to a Kubernetes secret
# 3. Deploys spinnaker with kustomize patches using "kubectl -k apply"
#
# Full logs are redirected to deploy_log.txt
#--------------------------------------------------------------------------------------------------------------------------

SPIN_FLAVOR=${SPIN_FLAVOR:-armory}         # Distribution of spinnaker to deploy (oss or armory)
SPIN_OP_DEPLOY=${SPIN_OP_DEPLOY:-1}        # Whether or not to deploy and manage operator (0 or 1)
SPIN_OP_VERSION=${SPIN_OP_VERSION:-latest} # Spinnaker operator version
SPIN_WATCH=${SPIN_WATCH:-1}                # Whether or not to watch/wait for Spinnaker to come up (0 or 1)

ROOT_DIR="$(
  cd "$(dirname "$0")" >/dev/null 2>&1 || exit 1
  pwd -P
)"
OUT="$ROOT_DIR/deploy_log.txt"

function log() {
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  ORANGE='\033[0;33m'
  CYAN='\033[0;36m'
  NC='\033[0m'
  LEVEL=$1
  MSG=$2
  case $LEVEL in
  "INFO") HEADER_COLOR=$GREEN MSG_COLOR=$NS ;;
  "WARN") HEADER_COLOR=$ORANGE MSG_COLOR=$NS ;;
  "KUBE") HEADER_COLOR=$ORANGE MSG_COLOR=$CYAN ;;
  "ERROR") HEADER_COLOR=$RED MSG_COLOR=$NS ;;
  esac
  printf "${HEADER_COLOR}[%-5.5s]${NC} ${MSG_COLOR}%b${NC}" "${LEVEL}" "${MSG}"
  printf "[%-5.5s] %b" "${LEVEL}" "${MSG}" >>"$OUT"
}

function info() {
  log "INFO" "$1"
}

function warn() {
  log "WARN" "$1"
}

function error() {
  log "ERROR" "$1" && exit 1
}

function handle_generic_kubectl_error() {
  error "Error executing command:\n$ERR_OUTPUT"
}

function exec_kubectl_mutating() {
  log "KUBE" "$1\n"
  ERR_OUTPUT=$({ $1 >>"$OUT"; } 2>&1)
  EXIT_CODE=$?
  [[ $EXIT_CODE != 0 ]] && $2
}

function change_patch_flavor() {
  if ! grep "^$API_VERSION" spinnakerservice.yml >/dev/null; then
    info "Changing spinnaker flavor..."
    {
      echo "API_VERSION: $API_VERSION" >>"$OUT"
      # shellcheck disable=SC2044
      for f in $(find "$ROOT_DIR" -name '*.yml' -or -name '*.yaml'); do
        if ! grep -E "^apiVersion: spinnaker.(armory.)?io/v1alpha2" "$f" >/dev/null 2>&1; then continue; fi
        if grep "^$API_VERSION" "$f" >/dev/null 2>&1; then continue; fi
        echo "Changing spinnaker apiVersion on file: $f"
        sed "s|^apiVersion: spinnaker.\(armory.\)\{0,1\}io/v1alpha2|$API_VERSION|" "$f" >"$f".new
        mv "$f.new" "$f"
      done
    } >>"$OUT" 2>&1
    echo -ne "Done\n"
  fi
}

function check_prerequisites() {
  date >"$OUT"
  case $SPIN_FLAVOR in
  "oss")
    OP_API_GROUP=spinnakerservices.spinnaker.io
    if [[ $SPIN_OP_VERSION == "latest" ]]; then SPIN_OP_VERSION=`curl -s https://github.com/armory/spinnaker-operator/releases/latest | cut -d'"' -f2 | awk '{gsub(".*/v","")}1'`; fi
    OP_URL=https://github.com/armory/spinnaker-operator/releases/download/v${SPIN_OP_VERSION}/manifests.tgz
    OP_IMAGE_BASE="armory/spinnaker-operator"
    API_VERSION="apiVersion: spinnaker.io/v1alpha2"
    ;;
  "armory")
    OP_API_GROUP=spinnakerservices.spinnaker.armory.io
    if [[ $SPIN_OP_VERSION == "latest" ]]; then SPIN_OP_VERSION=`curl -s https://github.com/armory-io/spinnaker-operator/releases/latest | cut -d'"' -f2 | awk '{gsub(".*/v","")}1'`; fi
    OP_URL=https://github.com/armory-io/spinnaker-operator/releases/download/v${SPIN_OP_VERSION}/manifests.tgz
    OP_IMAGE_BASE="armory/armory-operator"
    API_VERSION="apiVersion: spinnaker.armory.io/v1alpha2"
    ;;
  *) error "Invalid spinnaker flavor: $SPIN_FLAVOR. Valid values: armory, oss\n" ;;
  esac

  info "Spinnaker Operator Version: $SPIN_OP_VERSION\n"
  info "Spinnaker flavor: $SPIN_FLAVOR\n"

  if ! kubectl get ns >/dev/null 2>&1; then
    error "Unable to list namespaces of the kubernetes cluster:\n$(kubectl get ns)"
  fi

  if ! command -v jq &>/dev/null; then
    error "'jq' is not installed."
  fi

  change_patch_flavor

  KUST_OUT=$(kubectl kustomize . 2>&1)
  [[ $? != 0 ]] && error "\"kubectl kustomize .\" returned an error:\n$KUST_OUT\n"
  if ! command -v watch &>/dev/null; then
    HAS_WATCH=0
  else
    HAS_WATCH=1
  fi
}

function find_current_operator_details() {
  kubectl get crd "$OP_API_GROUP" >>"$OUT" 2>&1 && CRD_READY=1 || CRD_READY=0
  CURRENT_OP_NS=$({ kubectl get deployment --all-namespaces -o json | jq -r '.items[] | select(.metadata.name == "spinnaker-operator") | .metadata.namespace'; } 2>>"$OUT")
  [[ $(echo "$CURRENT_OP_NS" | wc -l | awk '{print $1}') -gt 1 ]] && error "More than one deployment named \"spinnaker-operator\" found in the cluster"

  if [[ "$CURRENT_OP_NS" != "" ]] ; then
    CURRENT_OP_IMAGE=$(kubectl -n $CURRENT_OP_NS get deployment spinnaker-operator -o json | jq -r '.spec.template.spec.containers | .[] | select(.name | contains("spinnaker-operator")) | .image')
  else
    CURRENT_OP_IMAGE=""
  fi
}

function delete_operator() {
  info "Deleting operator\n"
  exec_kubectl_mutating "kubectl -n $OPERATOR_NS delete deployment spinnaker-operator" handle_generic_kubectl_error
}

function check_operator_deployment() {
  OP_READY_REP=$({ kubectl -n $OPERATOR_NS get deployment spinnaker-operator -o json | jq '.status.readyReplicas'; } 2>>"$OUT")
  [[ "$OP_READY_REP" == "1" ]] && OP_READY=1 || OP_READY=0
}

function deploy_operator() {
  info "Deploying $SPIN_FLAVOR operator...\n"
  {
    rm -rf "$ROOT_DIR/operator/deploy"
    cd "$ROOT_DIR/operator" || exit 1
  } >>"$OUT" 2>&1
  info "Downloading operator from $OP_URL\n"
  { curl -L $OP_URL | tar -xz; } >>"$OUT" 2>&1
  exec_kubectl_mutating "kubectl apply -f $ROOT_DIR/operator/deploy/crds/" handle_generic_kubectl_error
  if ! kubectl get ns "$OPERATOR_NS" >/dev/null 2>&1; then
    exec_kubectl_mutating "kubectl create ns $OPERATOR_NS" handle_generic_kubectl_error
  fi
  exec_kubectl_mutating "kubectl -n $OPERATOR_NS apply -k $ROOT_DIR/operator" handle_generic_kubectl_error
  info "Waiting for operator to start."
  check_operator_deployment
  while [[ $OP_READY != 1 ]]; do
    echo -ne "."
    sleep 2
    check_operator_deployment
  done
  echo -ne "Done\n"
  cd "$ROOT_DIR" || exit 1
}

function assert_operator() {
  [[ $SPIN_OP_DEPLOY = 0 ]] && info "Not manging operator\n" && return

  find_current_operator_details
  OPERATOR_NS=$(grep "^namespace:" "$ROOT_DIR"/operator/kustomization.yml | awk '{print $2}')
  info "Resolved operator namespace: $OPERATOR_NS\n"
  check_operator_deployment

  if [[ "$CURRENT_OP_NS" != "" && "$CURRENT_OP_NS" != "$OPERATOR_NS" ]]; then
    error "There is already a spinnaker operator in the cluster at namespace \"$CURRENT_OP_NS\", and doesn't match the desired namespace \"$OPERATOR_NS\". Change desired namespace in operator/kustomization.yml, or delete the existing operator, or set the env var SPIN_OP_DEPLOY=0 to ignore this error.\n"

  elif [[ $CURRENT_OP_IMAGE != "" && ${CURRENT_OP_IMAGE//:*/} != "$OP_IMAGE_BASE" ]]; then
    warn "There is a different operator in namespace \"$OPERATOR_NS\" (expected: \"$OP_IMAGE_BASE\", actual: \"${CURRENT_OP_IMAGE//:*/}\"). Do you want to delete it? (y/n)\n"
    read -r del_choice
    [[ "$del_choice" != "y" ]] && exit 0
    delete_operator
    deploy_operator

  elif [[ $CRD_READY == 0 || $OP_READY != 1 ]]; then
    deploy_operator
  fi
  OP_IMAGE=$(kubectl -n $OPERATOR_NS get deployment spinnaker-operator -o json | jq '.spec.template.spec.containers | .[] | select(.name | contains("spinnaker-operator")) | .image')
  info "Operator version: $OP_IMAGE\n"
}

function deploy_secrets() {
  SPIN_NS=$(grep "^namespace:" "$ROOT_DIR"/kustomization.yml | awk '{print $2}')
  [[ "x$SPIN_NS" == "x" ]] && SPIN_NS=spinnaker
  info "Resolved spinnaker namespace: $SPIN_NS\n"
  info "Deploying secrets...\n"
  if ! kubectl get ns "$SPIN_NS" >/dev/null 2>&1; then
    exec_kubectl_mutating "kubectl create ns $SPIN_NS" handle_generic_kubectl_error
  fi
  if kubectl -n "$SPIN_NS" get secret spin-secrets > /dev/null 2>&1 ; then
    exec_kubectl_mutating "kubectl -n $SPIN_NS delete secret spin-secrets" handle_generic_kubectl_error
  fi
  log "KUBE" "kubectl -n $SPIN_NS create secret generic spin-secrets [REDACTED]\n"
  {
    "$ROOT_DIR"/secrets/create-secrets.sh
  } >>"$OUT" 2>&1
}

function handle_spin_deploy_error {
  echo -ne "$ERR_OUTPUT" >>"$OUT"
  if echo "$ERR_OUTPUT" | grep "SpinnakerService validation failed" >/dev/null 2>&1; then
    PRETTY_ERR=$(echo "$ERR_OUTPUT" | sed -n -e '/SpinnakerService validation failed/,$p' | sed -e '/):.*/,$d')
  else
    PRETTY_ERR=$ERR_OUTPUT
  fi
  error "Error deploying spinnaker, see deploy_log.txt for full output:\n$PRETTY_ERR\n"
}

function deploy_spinnaker() {
  info "Deploying spinnaker...\n"
  exec_kubectl_mutating "kubectl -n $SPIN_NS apply -k $ROOT_DIR" handle_spin_deploy_error
  info "Spinnaker deployed\n"
}

check_prerequisites
assert_operator
deploy_secrets
deploy_spinnaker

if [[ $SPIN_WATCH == 1 ]]; then
  if [[ $HAS_WATCH == 1 ]]; then
    watch "kubectl -n $SPIN_NS get spinsvc && echo "" && kubectl -n $SPIN_NS get pods"
  else
    info "=== Consider installing \"watch\" command to monitor installation progress"
    kubectl -n $SPIN_NS get spinsvc && echo "" && kubectl -n $SPIN_NS get pods
  fi
else
  info "Skipping watch of Spinnaker "
fi
