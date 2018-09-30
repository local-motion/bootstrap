#!/usr/bin/env bash
#
# Make sure you've installed docker-edge
# Enable Kubernetes support -- https://docs.docker.com/docker-for-mac/kubernetes/
#
LEVEL=0
ASK_FOR_PERMISSION=true
PERFORM_CLEANUP_ONLY=false
PERFORM_CLEANUP_FIRST=false

# shellcheck source=./support/_brew.sh
source support/_brew.sh
brew::install kubectl jq

# shellcheck source=./support/_utils.sh
source support/_utils.sh
# shellcheck source=support/_ask.sh
source support/_ask.sh
# shellcheck source=./_istio.sh
source _istio.sh
# shellcheck source=./_port_forward.sh
source _port_forward.sh
# shellcheck source=./_logging.sh
source _logging.sh
# shellcheck source=./_telemetry.sh
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

bootstrap::_setup_conditional_output_redirect() {
    # https://serverfault.com/questions/414810/sh-conditional-redirection
    exec 6>/dev/null
    if [[ ${LEVEL} -ge 8 ]]; then
        info "Verbose mode"
        exec 6>&1
    else
        info "Silent mode"
    fi
}

bootstrap::_setup_port_forwards() {
    kube::wait_until_all_pods_are_running

    logging::port_forwards
    telemetry::port_forwards
    istio::port_forwards
}

bootstrap::cleanup() {
    info "Cleaning up the running Kube cluster first"

    if [[ ${ASK_FOR_PERMISSION} = true ]]; then
        ask "Delete everything from Kubernetes cluster?" Y || exit 1
    fi

    debug "Stopping port-forwards"
    port-forward::stop_all >&6 2>&1

    debug "Uninstalling everything from [default] namespace"
    kube::uninstall_everything_from_namespace "default" >&6 2>&1

    debug "Uninstalling Istio telemetry"
    telemetry::uninstall >&6 2>&1

    debug "Uninstalling Istio logging stack (Kibana, ElasticSearch, Fluentd)"
    logging::uninstall >&6 2>&1

    debug "Uninstalling remaining Istio Pilot, Mixer and Envoy"
    istio::uninstall >&6 2>&1

    debug "Uninstalling Kubernetes dashboard"
    kube::_uninstall_dashboard >&6 2>&1
}

bootstrap::all() {
    info "Start bootstrap"

    debug "Installing Kubernetes Dashboard"
    kube::_install_dashboard >&6 2>&1

    debug "Installing Istio Pilot, Mixer and Envoy"
    istio::install >&6 2>&1

    debug "Installing Istio logging stack (Kibana, ElasticSearch, Fluentd)"
    logging::install >&6 2>&1

    debug "Installing Istio telemetry"
    telemetry::install >&6 2>&1

    debug "Setting up port-forwards"
    bootstrap::_setup_port_forwards

    info "Done."
}

bootstrap::_setup_conditional_output_redirect

if [[ ${PERFORM_CLEANUP_ONLY} = true ]]; then
    bootstrap::cleanup
else
    if [[ ${PERFORM_CLEANUP_FIRST} = true ]]; then
        bootstrap::cleanup
    fi
    bootstrap::all
fi
