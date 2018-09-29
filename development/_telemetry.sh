#!/usr/bin/env bash

#
# https://istio.io/docs/tasks/telemetry/fluentd/
#

source support/_brew.sh
brew::install kubectl

source _port_forward.sh

telemetry::port_forwards() {
    return
}

telemetry::uninstall() {
    kubectl delete -f support/telemetry/new_telemetry.yaml || true
    port-forward::stop_all
}

telemetry::install() {
    kubectl apply -f support/telemetry/new_telemetry.yaml
}
