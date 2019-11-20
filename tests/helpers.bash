#!/bin/bash

set -euo pipefail

# USAGE: json-object [NAME=VALUE NAME=VALUE ...]
json-object() {
  # shellcheck disable=SC2016
  local filter='
    $ARGS.positional
    | map(
        # split on NAME=VALUE
        match("(.*?)=(.*)")
        | .captures
        # take only string captures
        | map(.string)
        | { key: .[0], value: .[1] }
      )
    | from_entries
  '

  jq -c --null-input "$filter" --args "$@" 2>/dev/tty
}

create-config() {
  local branches

  branches="$(json-object "$@")"

  local config='{"branches":'"$branches"'}'
  local plugin='{"forumone/capistrano":'"$config"'}'

  echo -n "[$plugin]"
}
