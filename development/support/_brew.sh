#!/usr/bin/env bash

#
# Install brew packages using for example:
#
# brew::install aws jq coreutils
#
brew::install() {
    for program_name in "$@"
    do
        local brew_name= #SC2155
        local tap_name=""

        # Some brew packages use '/'. Only use last part...
        # e.g. getsentry/tools/sentry-cli should become sentry-cli
        # shellcheck disable=SC2001
        brew_name=$(echo "${program_name}" | sed 's#.*/##')

        if [[ ${program_name} == "aws" ]]; then
            brew_name=awscli
        fi
        if [[ ${program_name} == "helm" ]]; then
            brew_name=kubernetes-helm
        fi
        if [[ ${program_name} == "awless" ]]; then
            tap_name="wallix/awless";
        fi

        # https://stackoverflow.com/questions/20802320/detect-if-homebrew-package-is-installed
        set +e
        # shellcheck disable=SC2230,SC2143
        if [[ -z "$(which /usr/local/bin/${brew_name})" && -z "$(brew list -1 | grep "^${brew_name}\$";)" ]]; then
            [[ ! -z "${tap_name}" ]] && brew tap ${tap_name}
            echo "Installing ${brew_name}..."
            brew install ${brew_name} > /dev/null
        fi
        set -e
    done
}
