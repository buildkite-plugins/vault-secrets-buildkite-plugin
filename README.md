# Vault Secrets Buildkite Plugins [![Build status](https://badge.buildkite.com/a68804f84b31ee4bde97db4ee52415c13d46bf2c72a9dd06cb.svg)](https://buildkite.com/buildkite/plugins-vault-secrets)

Expose secrets to your build steps. Secrets are stored encrypted-at-rest in HashiCorp Vault.

Different types of secrets are supported and exposed to your builds in appropriate ways:

- `ssh-agent` for SSH Private Keys
- Environment Variables for strings
- `git-credential` via git's credential.helper

## Example Usage

The following pipeline uses AppRole authentication to authenticate to the Vault server, and downloads env secrets stored in `https://my-vault-server/secret/buildkite/{pipeline}/env` and git-credentials from `https://my-vault-server/secret/buildkite/{pipeline}/git-credentials`.

The keys in the `env` secret are exposed in the `checkout` and `command` as environment variables. The git-credentials are exposed as an environment variable `GIT_CONFIG_PARAMETERS` and are also exposed in the `checkout` and `command`.

```yml
steps:
  - command: ./run_build.sh
    plugins:
      - vault-secrets#v1.0.0:
          server: "https://my-vault-server"
          path: secret/buildkite
          auth:
            method: "approle"
            role-id: "my-role-id"
            secret-env: "VAULT_SECRET_ID"
```


## Uploading Secrets

Secrets are downloaded by the plugin by matching the following keys

```text
env
environment
private_ssh_key
id_rsa_github
git-credentials
```

Secrets can be uploaded to the Vault CLI, in a field called *value*

```sh
echo -n $(cat private_ssh_key | base64) | vault write  data/buildkite/test-pipeline/private_ssh_key \
  value=-
```

`examples/` has 2 sample helper script for adding environment variables or ssh keys to Vault for a pipeline.

### Environment Secrets

Environment variable secrets are handled differently in this Vault plugin to the S3 plugin.

Each environment variable is treated as an individually secret under the `env` or `environment` nodes for a project.
eg.
project foo/env/var1
project foo/env/var2
etc

### Vault Policies

Create policies to manage who can read and update pipeline secrets

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
### Environment Variables

Key values pairs can also be uploaded.

```bash
vault kv put data/buildkite/my_pipeline/environment value=- <<< $(echo "MY_SECRET=blah")
```

```bash
vault kv put data/buildkite/my_pipeline/env_key value=- <<< $(echo "my secret")
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

### Git Credentials

For git over https, you can use a `git-credentials` file with credential urls in the format of:

```text
https://user:password@host/path/to/repo
```

```bash
vault write data/buildkite/my_pipeline/git-credentials value=- <<< $(echo "https://user:password@host/path/to/repo" | base64)
```

These are then exposed via a [gitcredential helper](https://git-scm.com/docs/gitcredentials) which will download the
credentials as needed.

## Options
***
The Vault Secrets plugin supports a number of different configuration options.

### `server` (optional, string)
The address of the target Vault server. Example: `https://my-vault-server:8200`

### `path` (optional, string)
Alternative Base Path to use for Vault secrets. This is expected to be a [KV Store](https://developer.hashicorp.com/vault/docs/secrets/kv#kv-version-2)  

Defaults to: `data/buildkite`

### `namespace` (optional, string)
Configure the [Enterprise Namespace](https://developer.hashicorp.com/vault/docs/enterprise/namespaces) to be used when querying the vault server


### `auth` (required, object)
Dictionary/map with the configuration of the parameters the plugin should use to authenticate with Vault.

`auth` expects the following keys:

#### `method` (required, string)

The auth method to use when authenticating with Vault. Currently only `approle` is supported

Possible values:
* `approle`: use AppRole authentication to the Vault server (requires a `role-id` be set)

#### `role-id` (required for `approle`)

The role-id the plugin should use to authenticate to Vault. Has no default value

#### `secret-env` (optional, string)

The environment variable which holds the **secret-id** used to authenticate to vault. Defaults to `VAULT_SECRET_ID`

Example:

```yaml
steps:
  - command: ./run_build.sh
    plugins:
      - vault-secrets#v1.0.0:
          server: https://my-vault-server
          auth:
            method: 'approle'
            role-id: 'my-role-id'
            secret-env: 'MY_SECRET_ENV'
```

## Testing
---
### Unit tests
The unit tests are written using BATS, you can test locally with:
```bash
make test
```
or using docker-compose:
```bash
docker-compose -f docker-compose.yml run --rm tests
```

### Integration test

The integration tests are run by spinning up a local vault container in dev mode, and configuring them with some data.

```bash
make integration-test
```

When writing test plans, note that secrets are processed in the order they appear in the list returned from the Vault.

### Testing the pipeline
You can test the pipeline locally using the `bk cli`. Passing the `-E BUILDKITE_PLUGIN_DOCKER_COMPOSE_RUN_LABELS=false` value will prevent the docker-compose plugin
from trying to use variables that don't exist when running the pipeline locally.

```bash
bk local run -E BUILDKITE_PLUGIN_DOCKER_COMPOSE_RUN_LABELS=false
```

## Acknowledgements
A special thank you to the original author [@mikeknox](https://github.com/mikeknox) for providing the framework for this plugin


## License

MIT (see [LICENSE](LICENSE))
