# Vault Secrets Buildkite Plugins

__This plugin was originally based on the the *AWS S3 Secrets Buildkite Plugin*__

__All secrets are base64 encoded in Vault__
It currently runs on an AWS based Buildkite stack, but it should work on any agent.

Expose secrets to your build steps. Secrets are stored encrypted-at-rest in HashiCorp Vault.

Different types of secrets are supported and exposed to your builds in appropriate ways:

- `ssh-agent` for SSH Private Keys
- Environment Variables for strings
- `git-credential` via git's credential.helper

## ENV example

The following pipeline downloads env secrets stored in `https://my-vault-server/secret/buildkite/{pipeline}/env` and git-credentials from `https://my-vault-server/secret/buildkite/{pipeline}/git-credentials`

The keys in the `env` secret are exposed in the `checkout` and `command` as environment variables. The git-credentials are exposed as an environment variable `GIT_CONFIG_PARAMETERS` and are also exposed in the `checkout` and `command`.

```yml
steps:
  - command: ./run_build.sh
    plugins:
      - buildkite-plugins/vault-secrets#v0.2.0:
          server: "https://my-vault-server"
          path: secret/buildkite
          auth:
            method: approle
            role-id: "my-role-id"
            secret-env: "VAULT_SECRET_ID"
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

- Create policies to manage who can read and update pipeline secrets

The plugin needs at least *read* and *list* capabilities for the data.
A sample read policy, this could be used by agents.

```text
path "data/buildkite/*" {
    capabilities = ["read", "list"]
}
```

A sample update policy for build engineers or developers.
This would allow creation of secrets for pipelines, but not as defaults.

```text
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

```text
https://user:password@host/path/to/repo
```

```bash
vault write data/buildkite/my_pipeline/git-credentials value=- <<< $(echo "https://user:password@host/path/to/repo" | base64)
```

These are then exposed via a [gitcredential helper](https://git-scm.com/docs/gitcredentials) which will download the
credentials as needed.

### Environment variables

Key values pairs can also be uploaded.

```bash
vault write data/buildkite/my_pipeline/environment value=- <<< $(echo "MY_SECRET=blah" | base64)
```

```bash
vault write data/buildkite/my_pipeline/env_key value=- <<< $(echo "my secret"| base64)
```

Can be loaded using:

```yaml
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

```bash
BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV=true BUILDKITE_PLUGIN_VAULT_SECRETS_ADDR=http://0.0.0.0:8200 BUILDKITE_PIPELINE_SLUG=my_pipeline hooks/environment
```

To test with BATS:

```bash
docker-compose -f docker-compose.yml run --rm tests
```

Integration test:

```bash
.buildkite/steps/test_envvar.sh
```

When writing test plans, note that secrets are processed in the order they appear in the list returned from the Vault.

## TODO

- Document use of `TESTER_VAULT_VERSION` version to set Vault version on tester service
- Add `SVC_VAULT_VERSION` to specify version of Vault service
- Document use of Makefile
- Merge compose files together

## Acknowledgements
A huge thank you to the original author @mknox


## License

MIT (see [LICENSE](LICENSE))
