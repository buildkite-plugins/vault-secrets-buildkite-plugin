#!/usr/bin/env bats

# export SSH_AGENT_STUB_DEBUG=/dev/tty
# export SSH_ADD_STUB_DEBUG=/dev/tty
# export VAULT_STUB_DEBUG=/dev/tty
# export GIT_STUB_DEBUG=/dev/tty

setup() {
  load "${BATS_PLUGIN_PATH}/load.bash"

  export BUILDKITE_PIPELINE_SLUG=testpipe

  export BUILDKITE_PLUGIN_VAULT_SECRETS_ADDR=https://vault_svr_url

  export GIT_CONFIG_PARAMETERS="'credential.helper=basedir/git-credential-vault-secrets ${BUILDKITE_PLUGIN_VAULT_SECRETS_ADDR} data/buildkite/testpipe/git-credentials'"
}

# Schema for git-credentials Secrets
# [schema://][user[:password]@]host[:port][/path][?[arg1=val1]...][#fragment]

@test "Basic url" {
  export TESTDATA="https://user:password@host.io"

  stub vault \
    "kv get -address=https://vault_svr_url -field=data -format=yaml data/buildkite/testpipe/git-credentials : echo ${TESTDATA}"

  run ./git-credential-vault-secrets "${BUILDKITE_PLUGIN_VAULT_SECRETS_ADDR}" "data/buildkite/${BUILDKITE_PIPELINE_SLUG}/git-credentials"

  assert_success
  assert_output --partial "protocol=https"
  assert_output --partial "host=host.io"
  assert_output --partial "username=user"
  assert_output --partial "password=password"

  unstub vault
}

@test "URL with args" {
  export TESTDATA='https://user:password@host.io/?arg1=val1'

  stub vault \
    "kv get -address=https://vault_svr_url -field=data -format=yaml data/buildkite/testpipe/git-credentials : echo ${TESTDATA}"

  run ./git-credential-vault-secrets "${BUILDKITE_PLUGIN_VAULT_SECRETS_ADDR}" "data/buildkite/${BUILDKITE_PIPELINE_SLUG}/git-credentials"

  assert_success
  assert_output --partial "protocol=https"
  assert_output --partial "host=host.io"
  assert_output --partial "username=user"
  assert_output --partial "password=password"

  unstub vault
}

@test "URL with multiple args" {
  export TESTDATA='https://user:password@host.io/?arg1=val1&arg2=val2'

  stub vault \
    "kv get -address=https://vault_svr_url -field=data -format=yaml data/buildkite/testpipe/git-credentials : echo ${TESTDATA}"

  run ./git-credential-vault-secrets "${BUILDKITE_PLUGIN_VAULT_SECRETS_ADDR}" "data/buildkite/${BUILDKITE_PIPELINE_SLUG}/git-credentials"

  assert_success
  assert_output --partial "protocol=https"
  assert_output --partial "host=host.io"
  assert_output --partial "username=user"
  assert_output --partial "password=password"

  unstub vault
}

@test "URL with fragment" {
  export TESTDATA='https://user:password@host.io/#anchor'

  stub vault \
    "kv get -address=https://vault_svr_url -field=data -format=yaml data/buildkite/testpipe/git-credentials : echo ${TESTDATA}"

  run ./git-credential-vault-secrets "${BUILDKITE_PLUGIN_VAULT_SECRETS_ADDR}" "data/buildkite/${BUILDKITE_PIPELINE_SLUG}/git-credentials"

  assert_success
  assert_output --partial "protocol=https"
  assert_output --partial "host=host.io"
  assert_output --partial "username=user"
  assert_output --partial "password=password"

  unstub vault
}

@test "URL with path" {
  export TESTDATA='https://user:password@host.io/path'

  stub vault \
    "kv get -address=https://vault_svr_url -field=data -format=yaml data/buildkite/testpipe/git-credentials : echo ${TESTDATA}"

  run ./git-credential-vault-secrets "${BUILDKITE_PLUGIN_VAULT_SECRETS_ADDR}" "data/buildkite/${BUILDKITE_PIPELINE_SLUG}/git-credentials"

  assert_success
  assert_output --partial "protocol=https"
  assert_output --partial "host=host.io"
  assert_output --partial "username=user"
  assert_output --partial "password=password"

  unstub vault
}

@test "URL with port" {
  # [schema://][user[:password]@]host[:port][/path][?[arg1=val1]...][#fragment]
  export TESTDATA='https://user:password@host.io:7999/'

  stub vault \
    "kv get -address=https://vault_svr_url -field=data -format=yaml data/buildkite/testpipe/git-credentials : echo ${TESTDATA}"

  run ./git-credential-vault-secrets "${BUILDKITE_PLUGIN_VAULT_SECRETS_ADDR}" "data/buildkite/${BUILDKITE_PIPELINE_SLUG}/git-credentials"

  assert_success
  assert_output --partial "protocol=https"
  assert_output --partial "host=host.io:7999"
  assert_output --partial "username=user"
  assert_output --partial "password=password"

  unstub vault
}

@test "URL with everything" {
  # [schema://][user[:password]@]host[:port][/path][?[arg1=val1]...][#fragment]
  export TESTDATA='https://user:password@host.io:7999/path?arg=val&arg2=val2#anchor'

  stub vault \
    "kv get -address=https://vault_svr_url -field=data -format=yaml data/buildkite/testpipe/git-credentials : echo ${TESTDATA}"

  run ./git-credential-vault-secrets "${BUILDKITE_PLUGIN_VAULT_SECRETS_ADDR}" "data/buildkite/${BUILDKITE_PIPELINE_SLUG}/git-credentials"

  assert_success
  assert_output --partial "protocol=https"
  assert_output --partial "host=host.io:7999"
  assert_output --partial "username=user"
  assert_output --partial "password=password"

  unstub vault
}
