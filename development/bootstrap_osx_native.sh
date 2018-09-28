#!/usr/bin/env bash

#
# Make sure you've installed docker-edge
# Enable Kubernetes support -- https://docs.docker.com/docker-for-mac/kubernetes/
#
script_name=$(basename -- $0)

source support/_brew.sh
brew::install kubectl jq

source support/_utils.sh
source _istio.sh
source _port_forward.sh
source _logging.sh
source _telemetry.sh



bootstrap::usage() {
  if [ -n "$1" ]; then
    echo ""
    error "👉 $1";
    echo ""
  fi
  echo "Usage: $0 -n namespace [-v] [-y] [--cleanup-first|--cleanup-only]"
  echo "  -n, --namespace          Everything is namespaced using this value, e.g. Kube namespace, generated names, etc."
  echo "  -y, --yes                Don't ask for permission, start bootstrapping"
  echo "  -v, --verbose            Script runs in verbose mode. This generates a fair amount of output."
  echo "  --cleanup-first          Will first delete any existing cluster with the same name"
  echo "  --cleanup-only           Will delete any existing cluster with the same name. Script is exited after deletion."
  echo ""
  echo "Examples:"
  echo "$0 --name localmotion"
  echo "$0 --name localmotion --cleanup-first --yes --verbose"
  echo ""
  exit 1
}

# parse params
while [[ "$#" -gt 0 ]]; do case $1 in
  -n|--name) NAME="$2"; shift;shift;;
  -y|--yes) ASK_FOR_PERMISSION=false;shift;;
  -v|--verbose) LEVEL=8;shift;;
  --cleanup-only) PERFORM_CLEANUP_ONLY=true;shift;;
  --cleanup-first) PERFORM_CLEANUP_FIRST=true;shift;;

  *) bootstrap::usage "Unknown parameter passed: $1"; shift; shift;;
esac; done

# verify params
if [[ -z "${NAME}" ]]; then bootstrap::usage "Unique project/team name is not set"; fi;

kube::_uninstall_dashboard() {
    kubectl delete -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml || true
}

kube::_install_dashboard() {
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml
    echo "Run 'kubectl proxy' and then the Kubernetes dashboard can be found at http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/"
}

bootstrap::cleanup() {
    info "Cleaning up the running Kube cluster first"

    port-forward::stop_all > uninstall.log 2>&1
    telemetry::uninstall > uninstall.log 2>&1
    logging::uninstall > uninstall.log 2>&1
    istio::uninstall > uninstall.log 2>&1
    kube::_uninstall_dashboard > uninstall.log 2>&1
}

bootstrap::all() {
    info "Start bootstrap"

    kube::_install_dashboard

    istio::install
    logging::install
    telemetry::install

    kube::wait_until_all_pods_are_running
    port-forward::setup

    info "Done."
}

if [[ ${PERFORM_CLEANUP_ONLY} = true ]]; then
    bootstrap::cleanup
else
    if [[ ${PERFORM_CLEANUP_FIRST} = true ]]; then
        bootstrap::cleanup
    fi
    # Don't use './assume_role.sh' since environment variables need to be shared
    bootstrap::all
fi
