# Vault Secrets Buildkite Plugins [![Build status](https://badge.buildkite.com/a68804f84b31ee4bde97db4ee52415c13d46bf2c72a9dd06cb.svg)](https://buildkite.com/buildkite/plugins-vault-secrets)

Expose secrets to your build steps. Secrets are stored encrypted-at-rest in HashiCorp Vault.

Different types of secrets are supported and exposed to your builds in appropriate ways:

-  Environment Variables for strings
- `ssh-agent` for SSH Private Keys
- `git-credential` via git's credential.helper

## Example Usage

The following examples use the available authentication methods to authenticate to the Vault server, and download env secrets stored in `https://my-vault-server/secret/buildkite/{pipeline}/env` and git-credentials from `https://my-vault-server/secret/buildkite/{pipeline}/git-credentials`.

The keys in the `env` secret are exposed in the `checkout` and `command` as environment variables. The git-credentials are exposed as an environment variable `GIT_CONFIG_PARAMETERS` and are also exposed in the `checkout` and `command`.

### AppRole Authentication
By default, the plugin references `BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_SECRET_ENV (default: $VAULT_SECRET_ID)` for the SecretID in Vault. Two examples will be provided below to describe how to use either the `secret-env` or `$VAULT_SECRET_ID` values.

You can read more about Vault's AppRole auth method (and SecretID) in the [documentation](https://developer.hashicorp.com/vault/docs/auth/approle).

#### Environment hook without secret-env
```bash
# This value is set in your agent's Environment hook
export VAULT_SECRET_ID="$(vault read -field "secret_id" auth/approle/role/buildkite/secret-id)"
```

```yml
steps:
  - command: ./run_build.sh
    plugins:
      - vault-secrets#v2.4.0:
          server: "https://my-vault-server"
          path: secret/buildkite
          auth:
            method: "approle"
            role-id: "my-role-id"
```

#### Environment hook using secret-env
This example shows how to use an environment hook using a `SUPER_SECRET_ID` variable in the environment through the plugin's `secret-env` option.

```bash
# This value is set in your agent's Environment hook
SUPER_SECRET_ID=$(vault read -field "secret_id" auth/approle/role/buildkite/secret-id)
```

```yml
steps:
  - command: ./run_build.sh
    plugins:
      - vault-secrets#v2.4.0:
          server: "https://my-vault-server"
          path: secret/buildkite
          auth:
            method: "approle"
            role-id: "my-role-id"
            secret-env: "SUPER_SECRET_ID"
```

### AWS Authentication

```yml
steps:
  - command: ./run_build.sh
    plugins:
      - vault-secrets#v2.4.0:
          server: "https://my-vault-server"
          path: secret/buildkite
          auth:
            method: "aws"
            aws-role-name: "my-role-name"
```
### JWT Authentication

```yml
steps:
  - command: ./run_build.sh
    plugins:
      - vault-secrets#v2.4.0:
          server: "https://my-vault-server"
          path: secret/buildkite
          auth:
            method: "jwt"
            jwt-env: "VAULT_JWT"
```

### Custom Secret Keys
It is possible to download secrets from a custom secret key, by using the `secret` option on the plugin. Setting this option will tell the plugin to check the KV store for your secret (ex: `secret/buildkite/supersecret`).
This secret should still follow the same conventions as the `env` and `environment` secrets.
```yml
steps:
  - command: ./run_build.sh
    plugins:
      - vault-secrets#v2.4.0:
          server: "https://my-vault-server"
          secret: supersecret
          path: secret/buildkite
          auth:
            method: "approle"
            role-id: "my-role-id"
            secret-env: "VAULT_SECRET_ID"
```

## Uploading Secrets

Secrets are downloaded by the plugin by matching the following keys, as well as the key declared in the `secret` option

```text
env
environment
private_ssh_key
id_rsa_github
git-credentials
```

Secrets can be uploaded to the Vault CLI, in a field called *value*

```sh
echo -n $(cat private_ssh_key | base64) | vault write  secret/buildkite/test-pipeline/private_ssh_key \
  value=-
```

`examples/` has 2 sample helper script for adding environment variables or ssh keys to Vault for a pipeline.

### Custom Secret Keys

It is possible to download secrets from a custom secret key, by using the `secret` option on the plugin. Setting this option will tell the plugin to check the KV store for your secret (ex: `secret/buildkite/supersecret`).

This secret should still follow the same conventions as the `env` and `environment` secrets.
```yml
steps:
  - command: ./run_build.sh
    plugins:
      - vault-secrets#v2.4.0:
          server: "https://my-vault-server"
          secret: supersecret
          path: secret/buildkite
          auth:
            method: "approle"
            role-id: "my-role-id"
            secret-env: "VAULT_SECRET_ID"
```

## Example Usage

The following examples use the available authentication methods to authenticate to the Vault server, and download env secrets stored in `https://my-vault-server/secret/buildkite/{pipeline}/env` and git-credentials from `https://my-vault-server/secret/buildkite/{pipeline}/git-credentials`.

The keys in the `env` secret are exposed in the `checkout` and `command` as environment variables. The git-credentials are exposed as an environment variable `GIT_CONFIG_PARAMETERS` and are also exposed in the `checkout` and `command`.

### AppRole Authentication

```yml
steps:
  - command: ./run_build.sh
    plugins:
      - vault-secrets#v2.4.0:
          server: "https://my-vault-server"
          path: secret/buildkite
          auth:
            method: "approle"
            role-id: "my-role-id"
            secret-env: "VAULT_SECRET_ID"
```

### AWS Authentication

```yml
steps:
  - command: ./run_build.sh
    plugins:
      - vault-secrets#v2.4.0:
          server: "https://my-vault-server"
          path: secret/buildkite
          auth:
            method: "aws"
            aws-role-name: "my-role-name"
```
### JWT Authentication

```yml
steps:
  - command: ./run_build.sh
    plugins:
      - vault-secrets#v2.4.0:
          server: "https://my-vault-server"
          path: secret/buildkite
          auth:
            method: "jwt"
            jwt-env: "VAULT_JWT"
```

### Environment Variables

Key values pairs can also be uploaded.

```bash
vault kv put secret/buildkite/my_pipeline/environment value=- <<< $(echo "MY_SECRET=blah")
```

```bash
vault kv put secret/buildkite/my_pipeline/env_key value=- <<< $(echo "my secret")
```

### Environment Secrets

Environment variable secrets are handled differently in this Vault plugin to the S3 plugin.

Each environment variable is treated as an individually secret under the `env` or `environment` nodes for a project.
eg.
project foo/env/var1
project foo/env/var2
etc

Secrets are exported into the environment as key/value pairs identically matching how they are stored in Vault. For instance, a secret at path `data/buildkite/env_mytest123` with the keypair `MY_ENV_VAR=foobar` will be exported into the environment as `MY_ENV_VAR=foobar`.

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

SSH keyload requires the field used to store the key information to be named `ssh_key`. Any other value will result in an error.

```bash
# generate a deploy key for your project
ssh-keygen -t rsa -b 4096 -f id_rsa_buildkite
pbcopy < id_rsa_buildkite.pub # paste this into your github deploy key

export my_pipeline=my-buildkite-secrets
echo -n $(cat id_rsa_buildkite) | vault write data/buildkite/my_pipeline/private_ssh_key \
    ssh_key=-
```

### Git Credentials

For git over https, you can use a `git-credentials` file with credential urls in the format of:

```text
https://user:password@host/path/to/repo
```

```bash
vault write secret/buildkite/my_pipeline/git-credentials value=- <<< $(echo "https://user:password@host/path/to/repo" | base64)
```

These are then exposed via a [gitcredential helper](https://git-scm.com/docs/gitcredentials) which will download the
credentials as needed.

### Vault Policies

Create policies to manage who can read and update pipeline secrets

The plugin needs at least *read* and *list* capabilities for the data.
A sample read policy, this could be used by agents.

```text
path "secret/buildkite/*" {
    capabilities = ["read", "list"]
}
```

A sample update policy for build engineers or developers.
This would allow creation of secrets for pipelines, but not as defaults.

```text
# Allow update of secrets
path "secret/buildkite/*" {
    capabilities = ["create", "update", "delete", "list"]
}
path "secret/buildkite/env" {
    capabilities = ["deny"]
}
path "secret/buildkite/environment" {
    capabilities = ["deny"]
}
path "secret/buildkite/git-credentials" {
    capabilities = ["deny"]
}
path "secret/buildkite/private_ssh_key" {
    capabilities = ["deny"]
}
```

## Options
***
The Vault Secrets plugin supports a number of different configuration options.

### `server` (optional, string)
The address of the target Vault server. Example: `https://my-vault-server:8200`

### `secret` (optional, string)
The key name for a custom secret. See [Example](#custom-secret-keys)

### `path` (optional, string)
Alternative Base Path to use for Vault secrets. This is expected to be a [KV Store](https://developer.hashicorp.com/vault/docs/secrets/kv#kv-version-2)  

Defaults to: `data/buildkite`

### `namespace` (optional, string)
Configure the [Enterprise Namespace](https://developer.hashicorp.com/vault/docs/enterprise/namespaces) to be used when querying the vault server

### `output` (optional, string)
Select the output format used by the Vault CLI when getting secrets from Vault. 
Expects one of the following values:

* `yaml`
* `json`

Default: `yaml`

### `debug` (optional, boolean)
Enable detailed debug logging to troubleshoot connection and authentication issues with Vault.

When enabled, the plugin will:
- Show detailed configuration information
- Validate Vault server connectivity before authentication
- Verify authentication success after login
- Test secret path accessibility before listing secrets
- Provide enhanced error messages with context for failures
- Enable bash trace mode for full command visibility

```yml
steps:
  - command: ./run_build.sh
    plugins:
      - vault-secrets#v2.4.0:
          server: "https://my-vault-server"
          debug: true
          auth:
            method: "approle"
            role-id: "my-role-id"
```

### `auth` (required, object)
Dictionary/map with the configuration of the parameters the plugin should use to authenticate with Vault.

`auth` expects the following keys:

#### `method` (required, string)

The auth method to use when authenticating with Vault. The values listed below are supported by the plugin.

Possible values:
* `approle`: use AppRole authentication to the Vault server (requires a `role-id` be set)
* `aws`: use AWS authentication to the Vault server (requires `aws-role-name` be set)
* `jwt`: use JWT authentication to request a token from the Vault server

#### `aws-role-name` (required for `aws`)

The IAM role name to be used when authenticating with AWS. If no value set, and running on an EC2 instance, defaults to the IAM role of the instance.

#### `role-id` (required for `approle`)

The role-id the plugin should use to authenticate to Vault. Has no default value

#### `secret-env` (optional, string)

The environment variable which holds the **secret-id** used to authenticate to Vault. Defaults to `VAULT_SECRET_ID`

#### `jwt-env` (optional, string)

The environment variable which contains the **JSON Web Token** used to authenticate to Vault. Defaults to `VAULT_JWT`

#### `jwt-role` (optional, string)

The role name that should be used to log in to Vault. Defaults to `buildkite`

Example:

```yaml
steps:
  - command: ./run_build.sh
    plugins:
      - vault-secrets#v2.4.0:
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

## Acknowledgements
A special thank you to the original author [@mikeknox](https://github.com/mikeknox) for providing the framework for this plugin

## License

MIT (see [LICENSE](LICENSE))
