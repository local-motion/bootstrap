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
    info "${namespace}:${app_label} - http://localhost:${local_port}"
}

port-forward::setup() {
    port-forward::forward istio-system prometheus 19090 9090
#    port-forward::forward istio-system grafana 13000 3000
#    port-forward::forward istio-system servicegraph 18088 8088
#    kubectl -n weave port-forward "$(kubectl get -n weave pod --selector=weave-scope-component=app -o jsonpath='{.items..metadata.name}')" 54040:4040 > forward.log 2>&1 &

    debug "prometheus - http://localhost:59090"
    debug "Grafana - http://localhost:53000"
    debug "servicegraph - http://localhost:58088/graph"
    debug "servicegraph - http://localhost:58088/force/forcegraph.html"
    debug "servicegraph - http://localhost:58088/dotviz"
#    echo "weave - http://localhost:54040/"
}

