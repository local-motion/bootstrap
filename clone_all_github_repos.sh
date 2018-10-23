#!/usr/bin/env bash
ORGANIZATION=$1

info() { printf "\\033[38;5;040mℹ\\033[0m %s\\n" "$1"; }
error() { printf "\\033[38;5;124m✗\\033[0m %s\\n" "$1"; }
debug() { printf "\\033[38;5;033m✓\\033[0m %s\\n" "$1"; }
pushd () { command pushd "$@" > /dev/null;  }
popd () { command popd "$@" > /dev/null; }

function control_c() {
	exit 1
}
trap control_c INT

LEVEL=0
ASK_FOR_PERMISSION=true

# This is a general-purpose function to ask Yes/No questions in Bash, either
# with or without a default answer. It keeps repeating the question until it
# gets a valid answer.

ask() {
    # https://djm.me/ask
    local prompt default reply

    while true; do

        if [ "${2:-}" = "Y" ]; then
            prompt="Y/n"
            default=Y
        elif [ "${2:-}" = "N" ]; then
            prompt="y/N"
            default=N
        else
            prompt="y/n"
            default=
        fi

        # Ask the question (not using "read -p" as it uses stderr not stdout)
        echo -n "$1 [$prompt] "

        # Read the answer (use /dev/tty in case stdin is redirected from somewhere else)
        # shellcheck disable=SC2162
        read reply </dev/tty

        # Default?
        if [ -z "$reply" ]; then
            reply=${default}
        fi

        # Check if the reply is valid
        case "$reply" in
            Y*|y*) return 0 ;;
            N*|n*) return 1 ;;
        esac

    done
}

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
  echo "Usage: $0 -o local-motion [-v]"
  echo "  -o, --organization       The organization for which to clone all repositories."
  echo "  -t, --target-dir         The target directory into which all repositories are cloned"
  echo "  -y, --yes                Don't ask for permission, start cloning"
  echo "  -v, --verbose            Script runs in verbose mode. This generates a fair amount of output."
  echo ""
  echo "Examples:"
  echo "$0 -o local-motion -t ~/dev/local-motion"
  echo "$0 --organization local-motion --target-dir ~/dev/local-motion --yes --verbose"
  echo ""
  exit 1
}


# parse params
while [[ "$#" -gt 0 ]]; do case $1 in
  -o|--organization) ORGANIZATION=$2; shift;shift;;
  -t|--target-dir) TARGET_DIRECTORY=$2; shift;shift;;
  -y|--yes) ASK_FOR_PERMISSION=false;shift;;
  -v|--verbose) LEVEL=8;shift;;
  *) usage "Unknown parameter passed: $1"; shift; shift;;
esac; done

# verify params
if [[ -z "${ORGANIZATION}" ]]; then usage "Github organization is not set"; fi;
if [[ -z "${TARGET_DIRECTORY}" ]]; then usage "Target directory is not set"; fi;

utils::_setup_conditional_output_redirect

info "Cloning all repositories from https://github.com/${ORGANIZATION} into ${TARGET_DIRECTORY}"

mkdir -p ${TARGET_DIRECTORY}
pushd ${TARGET_DIRECTORY}

clone_or_pull() {
	local dry_run=$1
	local ssh_url=$2
	basename=$(basename ${ssh_url})
	repository_name=${basename%.*}
	if [ -d "${repository_name}" ]; then
		info "Existing repository, pulling ${repository_name}"
		if [[ ${dry_run} = false ]]; then
		git pull >&6 2>&1
        fi
	else
		info "New repository, cloning ${ssh_url} into ${TARGET_DIRECTORY}/${repository_name}"

		if [[ ${dry_run} = false ]]; then
			git clone ${ssh_url} >&6 2>&1
		fi
	fi
}

clone_or_pull_all() {
	local dry_run=$1
	curl -s https://api.github.com/orgs/${ORGANIZATION}/repos?per_page=200 | jq -r '.[].ssh_url' | while read ssh_url ; do clone_or_pull ${dry_run} ${ssh_url}; done
}

if [[ ${ASK_FOR_PERMISSION} = true ]]; then
	info "This is a DRY RUN"
	clone_or_pull_all true
	ask "This was a DRY RUN, do you want to make the actual changes?" Y || exit 1
fi
clone_or_pull_all false

popd
