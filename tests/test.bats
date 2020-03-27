#!/usr/bin/env bats

set -euo pipefail

load "$BATS_PATH/load.bash"
load helpers

@test "Deploys master to dev" {
  export BUILDKITE_PLUGINS="$(create-config master=dev stable=staging)"
  export BUILDKITE_BRANCH=master

  stub docker \
    "run --rm -it * : true"

  run "$PWD/hooks/post-command"

  assert_success
  assert_line "Deploying master to dev"

  unstub docker
}

@test "Deploys master to dev with custom arguments" {
  export BUILDKITE_PLUGIN_CAPISTRANO_EXTRA_ARGS_0=foo=bar
  export BUILDKITE_PLUGIN_CAPISTRANO_EXTRA_ARGS_1=abc=def
  export BUILDKITE_PLUGINS="$(create-config master=dev stable=staging)"
  export BUILDKITE_BRANCH=master

  # Stub docker so that it outputs its arguments
  # (this is easier to do than pattern-matching on the inline script argument)
  stub docker \
    'run --rm -it * : echo "$@"'

  run "$PWD/hooks/post-command"

  assert_success

  # Assert that the output includes the two arguments that were added via the extra-args
  # config (use --partial because there may be some whitespace funny business)
  assert_output --partial "foo=bar abc=def"

  unstub docker
}

@test "Ignores non-existing branches" {
  export BUILDKITE_PLUGINS="$(create-config master=dev)"
  export BUILDKITE_BRANCH=ABC123-some-feature

  run "$PWD/hooks/post-command"

  assert_success
  assert_line "Branch ABC123-some-feature has no deployment destination"
}

@test "Warns if no config" {
  export BUILDKITE_PLUGINS="$(create-config)"
  export BUILDKITE_BRANCH=master

  run "$PWD/hooks/post-command"

  assert_success
  assert_output --partial "You have not configured any stages"
  assert_line "Branch master has no deployment destination"
}

@test "Warns if reversed config" {
  export BUILDKITE_PLUGINS="$(create-config dev=master)"
  export BUILDKITE_BRANCH=master

  run "$PWD/hooks/post-command"

  assert_success
  assert_output --partial "Try using 'master: dev' instead"
  assert_line "Branch master has no deployment destination"
}

@test "Hard fails if required" {
  export BUILDKITE_PLUGIN_CAPISTRANO_REQUIRE_STAGE=true
  export BUILDKITE_PLUGINS="$(create-config master=dev)"
  export BUILDKITE_BRANCH=stable

  run "$PWD/hooks/post-command"

  assert_failure
  assert_output --partial "Failed to determine a stage to deploy to"
  assert_line "Current branch: stable"
}

@test "Hard fails with missing config warning" {
  export BUILDKITE_PLUGIN_CAPISTRANO_REQUIRE_STAGE=true
  export BUILDKITE_PLUGINS="$(create-config)"
  export BUILDKITE_BRANCH=master

  run "$PWD/hooks/post-command"

  assert_failure
  assert_output --partial "Failed to determine a stage to deploy to"
  assert_output --partial "You have not configured any stages"
  assert_line "Current branch: master"
}

@test "Hard fails with reversed config warning" {
  export BUILDKITE_PLUGIN_CAPISTRANO_REQUIRE_STAGE=true
  export BUILDKITE_PLUGINS="$(create-config dev=master)"
  export BUILDKITE_BRANCH=master

  run "$PWD/hooks/post-command"

  assert_failure
  assert_output --partial "Failed to determine a stage to deploy to"
  assert_output --partial "Try using 'master: dev' instead"
  assert_line "Current branch: master"
}
