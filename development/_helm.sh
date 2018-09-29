#!/usr/bin/env bash

source support/_brew.sh
brew::install helm


helm::install() {
    # Install Helm (client) and Tiller (server) -- https://docs.bitnami.com/kubernetes/get-started-kubernetes/#step-4-install-helm-and-tiller
    if [ ! -f /usr/local/bin/helm ]; then
        brew install kubernetes-helm
    fi

    helm init
    kubectl create serviceaccount --namespace kube-system tiller
    kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
    kubectl create clusterrolebinding tiller-cluster-admin \
        --clusterrole=cluster-admin \
        --serviceaccount=kube-system:default
    kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'
}
