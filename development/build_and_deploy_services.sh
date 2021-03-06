#!/usr/bin/env bash
info() { printf "\\033[38;5;040mℹ\\033[0m %s\\n" "$1"; }
error() { printf "\\033[38;5;124m✗\\033[0m %s\\n" "$1"; }
debug() { printf "\\033[38;5;033m✓\\033[0m %s\\n" "$1"; }
pushd () { command pushd "$1" > /dev/null;  }
popd () { command popd > /dev/null; }

function control_c() {
	exit 1
}
trap control_c INT

LEVEL=0


utils::_setup_conditional_output_redirect() {
    # https://serverfault.com/questions/414810/sh-conditional-redirection
    exec 6>/dev/null
    if [[ ${LEVEL} -ge 8 ]]; then
        info "Verbose mode"
        exec 6>&1
    else
        info "Silent mode"
    fi
}

usage() {
  if [ -n "$1" ]; then
    echo ""
    error "👉 $1";
    echo ""
  fi
  echo "Usage: $0 [-v]"
  echo "  -v, --verbose            Script runs in verbose mode. This generates a fair amount of output."
  echo ""
  echo "Examples:"
  echo "$0"
  echo "$0 --verbose"
  echo ""
  exit 1
}

# parse params
while [[ "$#" -gt 0 ]]; do case $1 in
  -v|--verbose) LEVEL=8;shift;;
  *) usage "Unknown parameter passed: $1"; shift; shift;;
esac; done

utils::_setup_conditional_output_redirect

pushd ../.. || exit

for repository_name in */; do
    info "Checking for [build.sh] script in ${repository_name}"
    pushd "${repository_name}" || exit

    if [[ -f ./build.sh ]]; then
        debug "[build.sh] found, executing..."
        if [[ ${LEVEL} -ge 8 ]]; then
            ./build.sh --verbose >&6 2>&1
        else
            ./build.sh >&6 2>&1
        fi
    fi
    popd || exit
done

popd || exit

info "All microservices have been compiled and built. Now wrap into Docker container..."
docker-compose build --force

info "All microservices have wrapped into a Docker container. Now start them up..."
docker-compose up -d

info "Done, tail the logs"
docker-compose logs -f