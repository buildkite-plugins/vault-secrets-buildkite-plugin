[![Build status](https://badge.buildkite.com/04c3058f526f7019584f0d206996fd1ec3946c26b50edcd858.svg)](https://buildkite.com/assembly-payments/vault-secrets-buildkite-plugin)

# Vault Secrets Buildkite Plugins

__This plugin was originally based on the the *AWS S3 Secrets Buildkite Plugin*__

__All secrets are base64 encoded in Vault__
It currently runs on an AWS based Buildkite stack, but it should work on any agent.

Expose secrets to your build steps. Secrets are stored encrypted-at-rest in HashiCorp Vault.

Different types of secrets are supported and exposed to your builds in appropriate ways:

- `ssh-agent` for SSH Private Keys
- Environment Variables for strings
- `git-credential` via git's credential.helper

## Example

The following pipeline downloads a private key from `https://my-vault-server/data/buildkite/{pipeline}/ssh_private_key` and set of environment variables from `https://my-vault-server/data/buildkite/{pipeline}/environment`.

The private key is exposed to both the checkout and the command as an ssh-agent instance. The secrets in the env file are exposed as environment variables.

```yml
steps:
  - command: ./run_build.sh
    plugins:
      - mikeknox/vault-secrets#v0.1.:
          server: my-vault-server
```

## Uploading Secrets
Secrets are uploading using the Vault CLI, as a `base64` encoded blob in a field called *value*.
```sh
echo -n $(cat private_ssh_key | base64) | vault write  data/buildkite/test-pipeline/private_ssh_key \
  value=-
```

`examples/` has 2 sample helper script for adding environment variables or ssh keys to Vault for a pipeline.

### Environment secrets
Environment variable secrets are handled differently in this Vault plugin to the S3 plugin.

Each environment variable is treated as an individually secret under the `env` or `environment` nodes for a project.
eg.
project foo/env/var1
project foo/env/var2
etc

### Policies
* Create policies to manage who can read and update pipeline secrets

The plugin needs at least *read* and *list* capabilities for the data.
A sample read policy, this could be used by agents.
```
path "data/buildkite/*" {
    capabilities = ["read", "list"]
}
```

A sample update policy for build engineers or developers.
This would allow creation of secrets for pipelines, but not as defaults.
```
# Allow update of secrets
path "data/buildkite/*" {
    capabilities = ["create", "update", "delete", "list"]
}
path "data/buildkite/env" {
    capabilities = ["deny"]
}
path "data/buildkite/environment" {
    capabilities = ["deny"]
}
path "data/buildkite/git-credentials" {
    capabilities = ["deny"]
}
path "data/buildkite/private_ssh_key" {
    capabilities = ["deny"]
}
```

### SSH Keys

This example uploads an ssh key and an environment file to the base of the Vault secret path, which means it matches all pipelines that use it. You use per-pipeline overrides by adding a path prefix of `/my-pipeline/`.

```bash
# generate a deploy key for your project
ssh-keygen -t rsa -b 4096 -f id_rsa_buildkite
pbcopy < id_rsa_buildkite.pub # paste this into your github deploy key

export my_pipeline=my-buildkite-secrets
echo -n $(cat id_rsa_buildkite | base64) | vault write data/buildkite/my_pipeline/private_ssh_key \
    value=-
```

### Git credentials

For git over https, you can use a `git-credentials` file with credential urls in the format of:

```
https://user:password@host/path/to/repo
```

```
vault write data/buildkite/my_pipeline/git-credentials value=- <<< $(echo "https://user:password@host/path/to/repo" | base64)
```

These are then exposed via a [gitcredential helper](https://git-scm.com/docs/gitcredentials) which will download the
credentials as needed.

### Environment variables

Key values pairs can also be uploaded.

```
vault write data/buildkite/my_pipeline/environment value=- <<< $(echo "MY_SECRET=blah" | base64)
```

```
vault write data/buildkite/my_pipeline/env_key value=- <<< $(echo "my secret"| base64)
```
Can be loaded using:
```yml
steps:
  - command: ./run_build.sh
    plugins:
      - vault-secrets#v0.1.0:
          server: my-vault-server
          secrets:
          - key
```
## Options

### `path`
defaults to: `data/buildkite`
This is expected to be a kv store

Alternative Base Path to use for Vault secrets

## Testing
To run locally:
```
BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV=true BUILDKITE_PLUGIN_VAULT_SECRETS_ADDR=http://0.0.0.0:8200 BUILDKITE_PIPELINE_SLUG=my_pipeline hooks/environment
```

To test with BATS:
```
docker-compose -f docker-compose.yml run --rm tests
```

Integration test:
```
.buildkite/steps/test_envvar.sh
```

When writing test plans, note that secrets are processed in the order they appear in the list returned from the Vault.

# TODO
* Document use of `TESTER_VAULT_VERSION` version to set Vault version on tester service
* Add `SVC_VAULT_VERSION` to specify version of Vault service
* Document use of Makefile

* Merge compose files together

## License

MIT (see [LICENSE](LICENSE))
