#!/usr/bin/env bash

# shellcheck source=./support/_brew.sh
source _port_forward.sh

brew::install kubectl

axon::description() {
    echo "Axon Server stack"
}

axon::port_forwards() {
    port-forward::forward "default" axonserver-0 8024 8024 || true
    port-forward::forward "default" axonserver-0 8124 8124 || true
}

axon::uninstall() {
    kubectl delete -f axonserver.yml || true
}

axon::install() {
    kubectl apply -f axonserver.yml
}
