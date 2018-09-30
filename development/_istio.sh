#!/usr/bin/env bash

istio_version=1.0.2

# shellcheck source=./support/_brew.sh
source support/_brew.sh
brew::install kubectl helm

# shellcheck source=./support/_utils.sh
source support/_utils.sh
# shellcheck source=./support/_kube.sh
source support/_kube.sh
source _port_forward.sh

istio::description() {
    echo "Istio Pilot, Mixer and Envoy"
}

istio::port_forwards() {
    port-forward::forward istio-system jaeger 16686 16686
    port-forward::forward istio-system prometheus 19090 9090
    port-forward::forward istio-system grafana 13000 3000
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
        info "Removing Tiller"
        helm reset || true

        pushd istio-${istio_version}
        info "Removing Helm service account"
        kubectl delete -f install/kubernetes/helm/helm-service-account.yaml || true

        info "Removing CRDs"
        kubectl delete -f install/kubernetes/helm/istio/charts/certmanager/templates/crds.yaml || true
        kubectl delete -f install/kubernetes/helm/istio/templates/crds.yaml -n istio-system || true
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
        kubectl apply -f install/kubernetes/helm/istio/charts/certmanager/templates/crds.yaml

        # https://istio.io/docs/setup/kubernetes/helm-install/#option-2-install-with-helm-and-tiller-via-helm-install
        # https://istio.io/docs/tasks/telemetry/distributed-tracing/
        info "Installing Helm and Tiller"
        kubectl apply -f install/kubernetes/helm/helm-service-account.yaml
        helm init --service-account tiller

        info "Waiting for Tiller to be ready"
        bash ../support/wait_for_deployment.sh -n kube-system tiller-deploy

        info "Installing Istio onto Kubernetes cluster using Tiller"
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
