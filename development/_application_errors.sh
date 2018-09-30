#!/usr/bin/env bash

# shellcheck source=./support/_brew.sh
source support/_brew.sh
brew::install kubectl helm getsentry/tools/sentry-cli

# shellcheck source=./support/_utils.sh
source support/_utils.sh

application_errors::description() {
    echo "Application error services (Sentry and Sentry-kubernetes)"
}

application_errors::port_forwards() {
    return
}

application_errors::uninstall() {
    kubectl delete deployment --namespace kube-system sentry-kubernetes || true
}

application_errors::install() {
    local sentry_dsn=$1
    local environment= #SC2155

    environment="dev-$(whoami)"

    info "Deploying sentry-kubernetes pod to [kube-system] namespace, using environment ${environment} and DSN ${sentry_dsn}"

    # if deployed to [default] namespace, the pod cannot access /api/v1/events?watch=true endpoint
    # of the Kube API in [kube-system] namespace.
    # Deploying the sentry-kubernetes deployment to [kube-system];
    kubectl run sentry-kubernetes \
        --namespace kube-system \
        --image getsentry/sentry-kubernetes \
        --env="DSN=${sentry_dsn}" \
        --env="ENVIRONMENT=${environment}"
}
