#!/usr/bin/env bash

script_path=$(dirname "$0")

# shellcheck source=./support/_utils.sh
source "${script_path}/support/_utils.sh"

# shellcheck source=./support/_brew.sh
source "${script_path}/support/_brew.sh"
brew::install kubectl

kube::_count_all_pods() {
    # all pods in all namespaces and exclude the header line
    kubectl get pods --all-namespaces | grep -c -v STATUS
}
kube::_count_all_running_pods() {
    kubectl get pods --all-namespaces | grep -c Running
}

kube::wait_until_all_pods_are_running() {
    info "Waiting until all pods are status Running"
    until [[ $(kube::_count_all_running_pods) -eq $(kube::_count_all_pods) ]]; do debug "Waiting..." && sleep 3:; done
}

kube::get_pod() {
    local namespace=$1
    local app_label=$2
    kubectl -n "${namespace}" get pod -l app="${app_label}" -o jsonpath='{.items[0].metadata.name}'
}