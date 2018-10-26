#!/usr/bin/env bash

source support/_brew.sh
brew::install helm


helm::install() {
    # Install Helm (client) and Tiller (server) -- https://docs.bitnami.com/kubernetes/get-started-kubernetes/#step-4-install-helm-and-tiller
    if [ ! -f /usr/local/bin/helm ]; then
        brew install kubernetes-helm
    fi

    kubectl apply -f install/kubernetes/helm/helm-service-account.yaml
    helm init --service-account tiller
}
