#!/usr/bin/env bash

script_path=$(dirname "$0")

# shellcheck source=./support/_brew.sh
source "${script_path}/_brew.sh"
brew::install kubectl stern lnav

# shellcheck source=./support/_utils.sh
source "${script_path}/_utils.sh"

function control_c() {
    info "Counter pod is still running, uninstall using: "
    echo "kubectl delete -f https://k8s.io/examples/debug/counter-pod.yaml"
    echo ""
    info "Logging infrastructure for development consists of OSX command line tools:"
    debug "Learning about [lnav] can be done at https://lnav.readthedocs.io/en/latest/"
    debug "Learning about [stern] can be done at https://github.com/wercker/stern#usage"
    echo ""
    debug "For example:"
    debug "$ stern community | lnav"
	exit 1
}
trap control_c INT


kubectl create -f https://k8s.io/examples/debug/counter-pod.yaml || true

info "Piping through [lnav] to allow search and filtering. See more here https://lnav.readthedocs.io/en/latest/"
stern count | lnav
