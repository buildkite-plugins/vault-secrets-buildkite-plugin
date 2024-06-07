#!/usr/bin/env bats

setup() {
  load "${BATS_PLUGIN_PATH}/load.bash"

  export BUILDKITE_PIPELINE_SLUG=testpipe
  export BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER=https://vault_svr_url
  export BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV=true
}

@test "Load integer value from vault server" {
  export TESTDATA='MY_SECRET: 1'

  stub vault \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite/testpipe : exit 0" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite : echo 'env'" \
    "kv get -address=https://vault_svr_url -field=data -format=yaml data/buildkite/env : echo ${TESTDATA}"

  run bash -c "$PWD/hooks/environment && $PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "MY_SECRET=1"

  unstub vault
}

@test "Load floating-point value from vault server" {
  export TESTDATA='MY_SECRET: 0.95'

  stub vault \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite/testpipe : exit 0" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite : echo 'env'" \
    "kv get -address=https://vault_svr_url -field=data -format=yaml data/buildkite/env : echo ${TESTDATA}"

  run bash -c "$PWD/hooks/environment && $PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "MY_SECRET=0.95"

  unstub vault
}

@test "Load IP-like string value from vault server" {
  export TESTDATA='MY_SECRET: 0.0.0.1'

  stub vault \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite/testpipe : exit 0" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite : echo 'env'" \
    "kv get -address=https://vault_svr_url -field=data -format=yaml data/buildkite/env : echo ${TESTDATA}"

  run bash -c "$PWD/hooks/environment && $PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "MY_SECRET=0.0.0.1"

  unstub vault
}

@test "Load boolean true value from vault server" {
  export TESTDATA='MY_SECRET: true'

  stub vault \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite/testpipe : exit 0" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite : echo 'env'" \
    "kv get -address=https://vault_svr_url -field=data -format=yaml data/buildkite/env : echo ${TESTDATA}"

  run bash -c "$PWD/hooks/environment && $PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "MY_SECRET=true"

  unstub vault
}

@test "Load boolean false value from vault server" {
  export TESTDATA='MY_SECRET: false'

  stub vault \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite/testpipe : exit 0" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite : echo 'env'" \
    "kv get -address=https://vault_svr_url -field=data -format=yaml data/buildkite/env : echo ${TESTDATA}"

  run bash -c "$PWD/hooks/environment && $PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "MY_SECRET=false"

  unstub vault
}

@test "Load string 'truey' value from vault server" {
  export TESTDATA='MY_SECRET: truey'

  stub vault \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite/testpipe : exit 0" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite : echo 'env'" \
    "kv get -address=https://vault_svr_url -field=data -format=yaml data/buildkite/env : echo ${TESTDATA}"

  run bash -c "$PWD/hooks/environment && $PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "MY_SECRET=truey"

  unstub vault
}

@test "Load string 'falsey' value from vault server" {
  export TESTDATA='MY_SECRET: falsey'

  stub vault \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite/testpipe : exit 0" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite : echo 'env'" \
    "kv get -address=https://vault_svr_url -field=data -format=yaml data/buildkite/env : echo ${TESTDATA}"

  run bash -c "$PWD/hooks/environment && $PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "MY_SECRET=falsey"

  unstub vault
}
