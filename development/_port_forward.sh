#!/usr/bin/env bash

source support/_brew.sh
brew::install kubectl

source support/_utils.sh
source support/_kube.sh

port-forward::stop_all() {
    killall kubectl || true
}

port-forward::forward() {
    local namespace=$1
    local app_label=$2
    local local_port=$3
    local container_port=$4
    local pod= #SC2155

    pod=$(kube::get_pod "${namespace}" "${app_label}")
    kubectl -n "${namespace}" port-forward "${pod}" "${local_port}:${container_port}" > forward.log 2>&1 &

    info "Port-forward for ${namespace}:${app_label}:${container_port} -> http://localhost:${local_port}"
}
