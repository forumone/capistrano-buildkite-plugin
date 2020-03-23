# Capistrano Deployment Buildkite Plugin

A [Buildkite plugin](https://buildkite.com/docs/agent/v3/plugins) to deploy a project using Capistrano.

## Example

This will deploy a project using the given branch-to-stage mapping. If the current branch being built doesn't have a Capistrano stage associated with it, nothing happens.

```yaml
steps:
  - plugins:
      - forumone/capistrano#v0.2.1:
          branches:
            master: dev
            stable: staging
            live: production
```

In this example, the plugin will fail if a Capistrano stage couldn't be found.

```yaml
steps:
  - plugins:
      - forumone/capistrano#v0.2.1:
          require-stage: true
          branches:
            master: dev
            stable: staging
            live: production
```

This runs a deployment by specifying additional arguments.

```yaml
steps:
  - plugins:
      - forumone/capistrano#v0.2.1:
          extra-args:
            - foo=bar
          branches:
            master: dev
            stable: staging
            live: production
```

## Options

### `branches`

An object mapping Git branch names to Capistrano stages (the argument you pass to `cap <env> deploy`).

### `require-stage` (optional)

When set to `true`, requires that a stage be found for the given branch. Useful when the logic for skipping deployments can be found elsewhere (using Buildkite's `if` key or another plugin). By default, this value is `false`.

### `extra-args` (optional)

If your Capistrano configuration needs additional arguments, you may specify them here. This uses a YAML list in order to respect potential hazards with spaces and quoting.
