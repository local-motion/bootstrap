#!/usr/bin/env bash

istio_version=1.0.2

# shellcheck source=./support/_brew.sh
source support/_brew.sh
brew::install kubectl helm

# shellcheck source=./support/_utils.sh
source support/_utils.sh
# shellcheck source=./support/_kube.sh
source support/_kube.sh
# shellcheck source=./_helm.sh
source _helm.sh
source _port_forward.sh

istio::description() {
    echo "Istio Pilot, Mixer and Envoy"
}

istio::port_forwards() {
    port-forward::forward istio-system jaeger 16686 16686 || true
    port-forward::forward istio-system prometheus 19090 9090 || true
    port-forward::forward istio-system grafana 13000 3000 || true
#    port-forward::forward istio-system servicegraph 18088 8088

#    debug "Servicegraph - http://localhost:18088/graph"
#    debug "Servicegraph - http://localhost:18088/force/forcegraph.html"
#    debug "Servicegraph - http://localhost:18088/dotviz"
}

istio::uninstall() {
    info "Removing Istio from Kube cluster using Helm and Tiller"
    helm delete --purge istio || true
    kubectl label namespace default istio-injection-

    # https://github.com/koalaman/shellcheck/wiki/SC2103
    (
        if [ -d istio-${istio_version} ]; then
            (
                pushd istio-${istio_version} || exit

                info "Removing CRDs"
                kubectl delete -f install/kubernetes/helm/istio/charts/certmanager/templates/crds.yaml || true
                kubectl delete -f install/kubernetes/helm/istio/templates/crds.yaml -n istio-system || true
            )
        fi
    )

    # Remove any kubectl port-forward processes that may still be running
    port-forward::stop_all

    # Wait until none of the pods are terminating, e.g. Elastic Search takes a while to remove
    kube::wait_until_all_pods_are_running
}

# https://istio.io/docs/setup/kubernetes/helm-install/
istio::install() {
    if [ ! -d istio-${istio_version} ]; then
        info "Downloading Istio version ${istio_version}"
        curl -sL https://git.io/getLatestIstio | ISTIO_VERSION=${istio_version} sh -
    fi

    # https://github.com/koalaman/shellcheck/wiki/SC2103
    (
        debug "Change directory to ./istio-${istio_version}"
        cd istio-${istio_version} || exit

        kubectl apply -f install/kubernetes/helm/istio/templates/crds.yaml

        # If you are enabling certmanager, you also need to install its CRDs as well and
        # wait a few seconds for the CRDS to be committed in the kube-apiserver
        sleep 5

        kubectl apply -f install/kubernetes/helm/istio/charts/certmanager/templates/crds.yaml
        sleep 5

        helm::install
        sleep 15

        # https://istio.io/docs/setup/kubernetes/helm-install/#option-2-install-with-helm-and-tiller-via-helm-install
        # https://istio.io/docs/tasks/telemetry/distributed-tracing/
        info "Installing Istio onto Kubernetes cluster using Helm"
        helm install install/kubernetes/helm/istio --name istio --namespace istio-system \
            --set tracing.enabled=true \
            --set grafana.enabled=true \
            --set servicegraph.enable=true
        debug "Enabled Jaeger"
        debug "Enabled Prometheus"
        debug "Enabled Grafana"
        debug "Enabled ServiceGraph"

        # IMPORTANT: Any namespace where you want the automated injection to work, make sure it's labeled
        info "Labeling default namespace with [istio-injection=enabled] as to enable automated injection of sidecars"
        kubectl label namespace default istio-injection=enabled --overwrite=true
    )
}
