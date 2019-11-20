#!/usr/bin/env bats

set -euo pipefail

load "$BATS_PATH/load.bash"
load helpers

@test "Deploys master to dev" {
  export BUILDKITE_PLUGINS="$(create-config master=dev stable=staging)"
  export BUILDKITE_BRANCH=master

  stub docker \
    "run --rm -it * : true"

  run "$PWD/hooks/command"

  assert_success
  assert_line "Deploying master to dev"

  unstub docker
}

@test "Ignores non-existing branches" {
  export BUILDKITE_PLUGINS="$(create-config master=dev)"
  export BUILDKITE_BRANCH=ABC123-some-feature

  run "$PWD/hooks/command"

  assert_success
  assert_line "Branch ABC123-some-feature has no deployment destination"
}

@test "Warns if no config" {
  export BUILDKITE_PLUGINS="$(create-config)"
  export BUILDKITE_BRANCH=master

  run "$PWD/hooks/command"

  assert_success
  assert_output --partial "You have not configured any stages"
  assert_line "Branch master has no deployment destination"
}

@test "Warns if reversed config" {
  export BUILDKITE_PLUGINS="$(create-config dev=master)"
  export BUILDKITE_BRANCH=master

  run "$PWD/hooks/command"

  assert_success
  assert_output --partial "Try using 'master: dev' instead"
  assert_line "Branch master has no deployment destination"
}

@test "Hard fails if required" {
  export BUILDKITE_PLUGIN_CAPISTRANO_REQUIRE_STAGE=true
  export BUILDKITE_PLUGINS="$(create-config master=dev)"
  export BUILDKITE_BRANCH=stable

  run "$PWD/hooks/command"

  assert_failure
  assert_output --partial "Failed to determine a stage to deploy to"
  assert_line "Current branch: stable"
}

@test "Hard fails with missing config warning" {
  export BUILDKITE_PLUGIN_CAPISTRANO_REQUIRE_STAGE=true
  export BUILDKITE_PLUGINS="$(create-config)"
  export BUILDKITE_BRANCH=master

  run "$PWD/hooks/command"

  assert_failure
  assert_output --partial "Failed to determine a stage to deploy to"
  assert_output --partial "You have not configured any stages"
  assert_line "Current branch: master"
}

@test "Hard fails with reversed config warning" {
  export BUILDKITE_PLUGIN_CAPISTRANO_REQUIRE_STAGE=true
  export BUILDKITE_PLUGINS="$(create-config dev=master)"
  export BUILDKITE_BRANCH=master

  run "$PWD/hooks/command"

  assert_failure
  assert_output --partial "Failed to determine a stage to deploy to"
  assert_output --partial "Try using 'master: dev' instead"
  assert_line "Current branch: master"
}
