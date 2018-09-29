#!/usr/bin/env bash

info() { printf "\\033[38;5;040mℹ\\033[0m %s\\n" "$1"; }
error() { printf "\\033[38;5;124m✗\\033[0m %s\\n" "$1"; }
debug() { printf "\\033[38;5;033m✓\\033[0m %s\\n" "$1"; }
pushd () { command pushd "$@" > /dev/null;  }
popd () { command popd "$@" > /dev/null; }

function control_c() {
	exit 1
}
trap control_c INT
