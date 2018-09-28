#!/usr/bin/env bash

script_path=$(dirname "$0")

source ${script_path}/support/_utils.sh
source ${script_path}/support/_brew.sh
brew::install kubectl

kube::_count_all_pods() {
    # all pods in all namespaces and exclude the header line
    kubectl get pods --all-namespaces | grep -v STATUS | wc -l
}
kube::_count_all_running_pods() {
    kubectl get pods --all-namespaces | grep Running | wc -l
}

kube::wait_until_all_pods_are_running() {
    info "Waiting until all pods are status Running"
    until [[ $(kube::_count_all_running_pods) -eq $(kube::_count_all_pods) ]]; do debug "Waiting..." && sleep 3:; done
}
