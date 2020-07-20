#!/usr/bin/env bats

load '/usr/local/lib/bats/load.bash'

# export SSH_AGENT_STUB_DEBUG=/dev/tty
# export SSH_ADD_STUB_DEBUG=/dev/tty
# export VAULT_STUB_DEBUG=/dev/tty
# export GIT_STUB_DEBUG=/dev/tty


# Schema for git-crednetials Secrets
# [schema://][user[:password]@]host[:port][/path][?[arg1=val1]...][#fragment]

@test "Get basic git-credentials from vault server" {
  export BUILDKITE_PLUGIN_VAULT_SECRETS_ADDR=https://vault_svr_url
  export BUILDKITE_PIPELINE_SLUG=testpipe
  export GIT_CONFIG_PARAMETERS="'credential.helper=basedir/git-credential-vault-secrets ${BUILDKITE_PLUGIN_VAULT_SECRETS_ADDR} kv/buildkite/testpipe/git-credentials'"
  export TEST_CREDS1="https://user:password@host.io:7999/path"
  export TESTDATA=`echo -n "${TEST_CREDS1}" | base64`

  stub vault \
    "read -address=https://vault_svr_url -field=value kv/buildkite/testpipe/git-credentials : echo ${TESTDATA}"

  run ./git-credential-vault-secrets ${BUILDKITE_PLUGIN_VAULT_SECRETS_ADDR} kv/buildkite/${BUILDKITE_PIPELINE_SLUG}/git-credentials

  assert_success
  assert_output --partial "protocol=https"
  assert_output --partial "host=host.io"
  assert_output --partial "username=user"
  assert_output --partial "password=password"

  unstub vault

  unset TESTDATA
  unset TEST_CREDS1
  unset GIT_CONFIG_PARAMETERS
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_ADDR
  unset BUILDKITE_PIPELINE_SLUG
}

@test "Get git-credentials with args from vault server" {
  skip "creds with args are not parsing correctly"
  export BUILDKITE_PLUGIN_VAULT_SECRETS_ADDR=https://vault_svr_url
  export BUILDKITE_PIPELINE_SLUG=testpipe
  export GIT_CONFIG_PARAMETERS="'credential.helper=basedir/git-credential-vault-secrets ${BUILDKITE_PLUGIN_VAULT_SECRETS_ADDR} kv/buildkite/testpipe/git-credentials'"
  export TEST_CREDS1='https://user:password@host.io:7999/path?arg1=val1'
  # [schema://][user[:password]@]host[:port][/path][?[arg1=val1]...][#fragment]
  export TESTDATA=`echo -n "${TEST_CREDS1}" | base64`

  stub vault \
    "read -address=https://vault_svr_url -field=value kv/buildkite/testpipe/git-credentials : echo ${TESTDATA}"

  run ./git-credential-vault-secrets ${BUILDKITE_PLUGIN_VAULT_SECRETS_ADDR} kv/buildkite/${BUILDKITE_PIPELINE_SLUG}/git-credentials

  assert_success
  assert_output --partial "protocol=https"
  assert_output --partial "host=host.io"
  assert_output --partial "username=user"
  assert_output --partial "password=password"

  unstub vault

  unset TESTDATA
  unset TEST_CREDS1
  unset GIT_CONFIG_PARAMETERS
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_ADDR
  unset BUILDKITE_PIPELINE_SLUG
}
