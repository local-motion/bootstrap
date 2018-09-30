#!/usr/bin/env bash

# shellcheck source=./support/_brew.sh
source support/_brew.sh
brew::install kubectl lnav stern

logging::port_forwards() {
    return
}

logging::uninstall() {
    return
}

logging::install() {
    info "Logging infrastructure for development consists of OSX command line tools:"
    debug "Learning about [lnav] can be done at https://lnav.readthedocs.io/en/latest/"
    debug "Learning about [stern] can be done at https://github.com/wercker/stern#usage"
    echo ""
    debug "For example:"
    debug "$ stern community | lnav"
    return
}


