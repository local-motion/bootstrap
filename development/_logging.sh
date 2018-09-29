#!/usr/bin/env bash

#
# https://istio.io/docs/tasks/telemetry/fluentd/
#

# shellcheck source=./support/_brew.sh
source support/_brew.sh
brew::install kubectl

source _port_forward.sh

logging::port_forwards() {
    port-forward::forward logging kibana 5601 5601
}

logging::uninstall() {
    kubectl delete -f support/logging/fluentd-istio.yaml || true
    kubectl delete -f support/logging/logging-stack.yaml || true
    port-forward::stop_all
}

logging::install() {
    kubectl apply -f support/logging/logging-stack.yaml
    kubectl apply -f support/logging/fluentd-istio.yaml
}


