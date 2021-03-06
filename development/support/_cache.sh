#!/bin/bash

# From https://bitbucket.org/dimo414/bash-cache/src
# Bash Cache provides a transparent mechanism for caching long-running Bash
# functions. See the README.md for full details.

# Configuration
if [[ -n "$_BC_TESTONLY_CACHE_DIR" ]]; then
  _bc_cache_dir="$_BC_TESTONLY_CACHE_DIR"
else
  _bc_cache_dir="${BC_CACHE_DIR:-${TMPDIR:-/tmp}}/bash-cache-$(id -u)"
fi
_bc_enabled=true
_bc_version=(0 5 0)
: $_bc_enabled # satisfy SC2034
: ${#_bc_version} # satisfy SC2034

# Ensures the cache dir exists. If it does not creates the directory and restricts its permissions.
bc::_ensure_cache_dir_exists() {
  [[ -d "$_bc_cache_dir" ]] && return
  mkdir -p "$_bc_cache_dir" &&
    # Cache dir should only be accessible to current user
    chmod 700 "$_bc_cache_dir"
}

# Hash function used to key cached results.
# Implementation is selected dynamically to support different environments (notably OSX provides
# shasum instead of GNU's sha1sum).
if command -v sha1sum &> /dev/null; then
  bc::_hash() { sha1sum <<<"$*" | tr -cd '0-9a-fA-F'; }
elif command -v shasum &> /dev/null; then
  bc::_hash() { shasum <<<"$*" | tr -cd '0-9a-fA-F'; }
else
  bc::_hash() { cksum <<<"$*"; }
fi

# Gets the time of last file modification in seconds since the epoch. Prints 0 and fails if file
# does not exist.
# Implementation is selected dynamically to support different environments (notably BSD/OSX and GNU
# stat have different semantics)
# Found https://stackoverflow.com/a/17907126/113632 after implementing this, could also use date
# as suggested there if these two aren't sufficient.
if stat -c %Y . &> /dev/null; then
  bc::_modtime() { stat -c %Y "$@" 2>/dev/null || { echo 0; return 1; }; } # GNU stat
else
  bc::_modtime() { stat -f %m "$@" 2>/dev/null || { echo 0; return 1; }; } # BSD/OSX stat
fi

# Gets the current system time in seconds since the epoch.
# Modern Bash can use the printf builtin, older Bash must call out to date.
if printf "%(%s)T" -1 &> /dev/null; then
  bc::_now() { printf "%(%s)T" -1; } # Modern Bash
else
  bc::_now() { date +'%s'; } # Fallback
fi

# Succeeds if the given FILE is less than SECONDS old (according to its modtime)
bc::_newer_than() {
  local modtime curtime seconds
  modtime=$(bc::_modtime "${1:?Must provide a FILE}") || return
  curtime=$(bc::_now) || return
  seconds=${2:?Must provide a number of SECONDS}
  (( modtime > curtime - seconds ))
}

# Reads stdin into a variable, accounting for trailing newlines. Avoids needing a subshell or
# command substitution.
# See http://stackoverflow.com/a/22607352/113632 and https://stackoverflow.com/a/49552002/113632
bc::_read_input() {
  # Use unusual variable names to avoid colliding with a variable name
  # the user might pass in (notably "contents")
  : "${1:?Must provide a variable to read into}"
  if [[ "$1" == '_line' || "$1" == '_contents' ]]; then
    echo "Cannot store contents to $1, use a different name." >&2
    return 1
  fi

  local _line _contents
   while read -r _line; do
     _contents="${_contents}${_line}"$'\n'
   done
   _contents="${_contents}${_line}" # capture any content after the last newline
   printf -v "$1" '%s' "$_contents"
}

# Given a name and an existing function, create a new function called name that
# executes the same commands as the initial function.
bc::copy_function() {
  local function="${1:?Missing function}"
  local new_name="${2:?Missing new function name}"
  declare -F "$function" &> /dev/null || {
    echo "No such function ${function}" >&2; return 1
  }
  eval "$(printf "%s()" "$new_name"; declare -f "$function" | tail -n +2)"
}

# Enables and disables caching - if disabled cached functions delegate directly
# to their bc::orig:: function.
bc::on()  { _bc_enabled=true;  }
bc::off() { _bc_enabled=false; }

# Captures function output and writes to disc
bc::_write_cache() {
  func=${1:?Must provide a function to cache}; shift
  : "${cachepath:?Must provide a cachepath to link to as an environment variable}"
  bc::_ensure_cache_dir_exists
  local cmddir
  cmddir=$(mktemp -d "$_bc_cache_dir/XXXXXXXXXX") || return
  "bc::orig::$func" "$@" > "$cmddir/out" 2> "$cmddir/err"; printf '%s' $? > "$cmddir/exit"
  ln -sfn "$cmddir" "$cachepath" # atomic
}

# Triggers a cleanup of stale cache records at most once every 60 seconds.
bc::_cleanup() {
  [[ -d "$_bc_cache_dir" ]] || return
  bc::_newer_than "$_bc_cache_dir/cleanup" 60 && return
  touch "$_bc_cache_dir/cleanup"
  cd / || return # necessary because find will cd back to the cwd, which can fail
  find "$_bc_cache_dir" -not -path "$_bc_cache_dir" -not -newermt '-1 minute' -delete
#  find "$_bc_cache_dir" -xtype l -delete
  find "$_bc_cache_dir" -type l ! -exec test -e {} \; -delete
  cd - > /dev/null || return
}

# Given a function - and optionally a list of environment variables - Decorates
# the function with a short-term caching mechanism, useful for improving the
# responsiveness of functions used in the prompt, at the expense of slightly
# stale data.
#
# Suggested usage:
#   expensive_func() {
#     ...
#   } && bc::cache expensive_func PWD
#
# This will replace expensive_func with a new function that caches the result
# of calling expensive_func frequently with the same arguments and in the same
# working directory. The original expensive_func is still available as
# bc::orig::expensive_func.
#
# It'd be nice to do something like write out,err,exit to a single file (e.g.
# base64 encoded, newline separated), but uuencode isn't always installed.
bc::cache() {
  func="${1:?"Must provide a function name to cache"}"; shift
  bc::copy_function "${func}" "bc::orig::${func}" || return
  local env="${func}:" v
  for v in "$@"; do
    env="$env:\$$v"
  done
  eval "$(cat <<EOF
    bc::warm::$func() {
      ( {
        local cachepath
        cachepath="\$_bc_cache_dir/\$(bc::_hash "\${*}::${env}")"
        bc::_write_cache "$func" "\$@"
       } & )
    }
EOF
  )"
  eval "$(cat <<EOF
    $func() {
      \$_bc_enabled || { bc::orig::$func "\$@"; return; }
      ( bc::_cleanup & ) # Clean up stale caches in the background

      local cachepath
      cachepath="\$_bc_cache_dir/\$(bc::_hash "\${*}::${env}")"

      # Read from cache - capture output once to avoid races
      # Note redirecting stderr to /dev/null comes first to suppress errors due to missing stdin
      local out err exit
      bc::_read_input out 2>/dev/null < "\$cachepath/out" || true
      bc::_read_input err 2>/dev/null < "\$cachepath/err" || true
      bc::_read_input exit 2>/dev/null < "\$cachepath/exit" || true

      if [[ "\$exit" == "" ]]; then
        # No cache, execute in foreground
        bc::_write_cache "$func" "\$@"
        bc::_read_input out < "\$cachepath/out"
        bc::_read_input err < "\$cachepath/err"
        bc::_read_input exit < "\$cachepath/exit"
      elif ! bc::_newer_than "\$cachepath/exit" 10; then
        # Cache exists but is old, refresh in background
        ( bc::_write_cache "$func" "\$@" & )
      fi

      # Output cached result
      printf '%s' "\$out"
      printf '%s' "\$err" >&2
      return "\${exit:-255}"
    }
EOF
  )"
}

# Prints the real-time to execute the given command, discarding its output.
bc::_time() {
  (
    TIMEFORMAT=%R
    time "$@" &> /dev/null
  ) 2>&1
}

# Benchmarks a function, printing the function's raw runtime as well as with a cold and warm cache.
# Runs in a subshell and can be used with any function, whether or not it's been cached already.
bc::benchmark() {
  local func=${1:?Must specify a function to benchmark}
  shift
  if ! declare -F "$func" &> /dev/null; then
    echo "No such function ${func}" >&2
    return 1
  fi
  # Drop into a subshell so the benchmark doesn't affect the calling shell
  (
    _bc_cache_dir=$(mktemp -d "${TMPDIR:-/tmp}/bc-benchmark-XXXXXX") || return
    TIMEFORMAT='%R'

    # Undo the caching if $func has already been cached - no-op otherwise
    bc::copy_function "bc::orig::${func}" "${func}" &> /dev/null || true
    # Cache (or re-cache) the function
    # Doesn't include any env vars in the key, which is probably fine for most benchmarks
    bc::cache "${func}"

    local raw cold warm
    raw="$(bc::_time "bc::orig::${func}" "$@")"
    cold="$(bc::_time "$func" "$@")"
    warm="$(bc::_time "$func" "$@")"

    printf 'Original:\t%s\nCold Cache:\t%s\nWarm Cache:\t%s\n' "$raw" "$cold" "$warm"

    rm -rf "$_bc_cache_dir" # not the "real" cache dir
  )
}