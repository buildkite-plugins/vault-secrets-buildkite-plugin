#!/usr/bin/env bats

load '/usr/local/lib/bats/load.bash'

# export SSH_AGENT_STUB_DEBUG=/dev/tty
# export SSH_ADD_STUB_DEBUG=/dev/tty
# export VAULT_STUB_DEBUG=/dev/tty
# export GIT_STUB_DEBUG=/dev/tty

#-------
@test "Add environment secret var to project using example helper" {
  export VAULT_ADDR=https://vault_svr_url
  export BUILDKITE_PIPELINE_SLUG=testpipe
  export TESTDATA=`echo MY_SECRET=fooblah | base64`

  stub vault \
    "token-lookup : exit 0" \
    "write kv/buildkite/testpipe/env/MY_SECRET value=- : exit 0"

  run bash -c "$PWD/examples/update-env-secret --pipeline ${BUILDKITE_PIPELINE_SLUG} --var MY_SECRET --value fooblah"

  assert_success

  unstub vault

  unset TESTDATA
  unset BUILDKITE_PIPELINE_SLUG
  unset VAULT_ADDR
}

@test "Add environment secret var to project using example helper via stdin" {
  export VAULT_ADDR=https://vault_svr_url
  export BUILDKITE_PIPELINE_SLUG=testpipe
  export TESTDATA=`echo MY_SECRET=fooblah | base64`

  stub vault \
    "token-lookup : exit 0" \
    "write kv/buildkite/testpipe/env/MY_SECRET value=- : exit 0"

  run bash -c "echo fooblah | $PWD/examples/update-env-secret --pipeline ${BUILDKITE_PIPELINE_SLUG} --var MY_SECRET"

  assert_success

  unstub vault

  unset TESTDATA
  unset BUILDKITE_PIPELINE_SLUG
  unset VAULT_ADDR
}

@test "Adding environment secret var to default will fail using example helper" {
  export VAULT_ADDR=https://vault_svr_url

  run bash -c "$PWD/examples/update-env-secret --var MY_SECRET --value fooblah"

  assert_failure

  assert_output --partial "--pipeline is a required argument."
  unset VAULT_ADDR
}

@test "Will environment helper exit if Vault_ADDR is not defined" {
  export BUILDKITE_PIPELINE_SLUG=testpipe
  run bash -c "$PWD/examples/update-env-secret --pipeline ${BUILDKITE_PIPELINE_SLUG} --var MY_SECRET --value fooblah"

  assert_failure

  assert_output --partial "set env var VAULT_ADDR for your vault server"

  unset BUILDKITE_PIPELINE_SLUG
}
