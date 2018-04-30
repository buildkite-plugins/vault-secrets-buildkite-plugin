#!/usr/bin/env bats

load '/usr/local/lib/bats/load.bash'

# export SSH_AGENT_STUB_DEBUG=/dev/tty
# export SSH_ADD_STUB_DEBUG=/dev/tty
# export VAULT_STUB_DEBUG=/dev/tty
# export GIT_STUB_DEBUG=/dev/tty

@test "test auth token option" {
  export BUILDKITE_PLUGIN_VAULT_SECRETS_PATH=foobar
  export BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER=https://vault_svr_url
  export BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV=false
  export BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_TOKEN=acdef-12345
  export BUILDKITE_PIPELINE_SLUG=testpipe

  stub vault \
    'auth -address=https://vault_svr_url - : echo Successfully authenticated. You are now logged in' \
    "list -address=https://vault_svr_url -format=yaml foobar/testpipe : exit 0" \
    "list -address=https://vault_svr_url -format=yaml foobar : exit 0"

  run bash -c "$PWD/hooks/environment && $PWD/hooks/pre-exit"

  assert_success
  assert_output --partial 'Successfully authenticated. You are now logged in'

  unstub vault

  unset BUILDKITE_PLUGIN_VAULT_SECRETS_PATH
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_TOKEN
  unset BUILDKITE_PIPELINE_SLUG
}

@test "test aws auth method" {
  export BUILDKITE_PLUGIN_VAULT_SECRETS_PATH=foobar
  export BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER=https://vault_svr_url
  export BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV=false
  export BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_METHOD=aws
  export BUILDKITE_PIPELINE_SLUG=testpipe

  stub vault \
    "auth -address=https://vault_svr_url -method=aws : echo Successfully authenticated. You are now logged in" \
    "list -address=https://vault_svr_url -format=yaml foobar/testpipe : exit 0" \
    "list -address=https://vault_svr_url -format=yaml foobar : exit 0"

  run bash -c "$PWD/hooks/environment && $PWD/hooks/pre-exit"

  assert_success
  assert_output --partial 'Successfully authenticated. You are now logged in'

  unstub vault

  unset BUILDKITE_PLUGIN_VAULT_SECRETS_PATH
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_METHOD
  unset BUILDKITE_PIPELINE_SLUG
}

@test "test auth token header" {
  export BUILDKITE_PLUGIN_VAULT_SECRETS_PATH=foobar
  export BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER=https://vault_svr_url
  export BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV=false
  export BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_HEADER=X-foobar
  export BUILDKITE_PIPELINE_SLUG=testpipe

  stub vault \
    'auth -address=https://vault_svr_url -header_value=X-foobar : echo Successfully authenticated. You are now logged in' \
    "list -address=https://vault_svr_url -format=yaml foobar/testpipe : exit 0" \
    "list -address=https://vault_svr_url -format=yaml foobar : exit 0"

  run bash -c "$PWD/hooks/environment && $PWD/hooks/pre-exit"

  assert_success
  assert_output --partial 'Successfully authenticated. You are now logged in'

  unstub vault

  unset BUILDKITE_PLUGIN_VAULT_SECRETS_PATH
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_HEADER
  unset BUILDKITE_PIPELINE_SLUG
}

@test "test auth role" {
  export BUILDKITE_PLUGIN_VAULT_SECRETS_PATH=foobar
  export BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER=https://vault_svr_url
  export BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV=false
  export BUILDKITE_PLUGIN_VAULT_SECRETS_ROLE=role_black_sheep
  export BUILDKITE_PIPELINE_SLUG=testpipe

  stub ssh-agent "-s : echo export SSH_AGENT_PID=45678"

  stub vault \
    'auth -address=https://vault_svr_url role=role_black_sheep : echo Successfully authenticated. You are now logged in' \
    "list -address=https://vault_svr_url -format=yaml foobar/testpipe : exit 0" \
    "list -address=https://vault_svr_url -format=yaml foobar : exit 0"

  run bash -c "$PWD/hooks/environment && $PWD/hooks/pre-exit"

  assert_success
  assert_output --partial 'Successfully authenticated. You are now logged in'

  unstub vault

  unset BUILDKITE_PLUGIN_VAULT_SECRETS_PATH
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_METHOD
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_ROLE
  unset BUILDKITE_PIPELINE_SLUG
}

@test "test auth method, role" {
  export BUILDKITE_PLUGIN_VAULT_SECRETS_PATH=foobar
  export BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER=https://vault_svr_url
  export BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV=false
  export BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_METHOD=aws
  export BUILDKITE_PLUGIN_VAULT_SECRETS_ROLE=role_black_sheep
  export BUILDKITE_PIPELINE_SLUG=testpipe

  stub vault \
    'auth -address=https://vault_svr_url -method=aws role=role_black_sheep : echo Successfully authenticated. You are now logged in' \
    "list -address=https://vault_svr_url -format=yaml foobar/testpipe : exit 0" \
    "list -address=https://vault_svr_url -format=yaml foobar : exit 0"

  run bash -c "$PWD/hooks/environment && $PWD/hooks/pre-exit"

  assert_success
  assert_output --partial 'Successfully authenticated. You are now logged in'

  unstub vault

  unset BUILDKITE_PLUGIN_VAULT_SECRETS_PATH
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_METHOD
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_ROLE
  unset BUILDKITE_PIPELINE_SLUG
}
