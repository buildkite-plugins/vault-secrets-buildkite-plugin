#!/usr/bin/env bats

# export SSH_AGENT_STUB_DEBUG=/dev/tty
# export SSH_ADD_STUB_DEBUG=/dev/tty
# export VAULT_STUB_DEBUG=/dev/tty
# export GIT_STUB_DEBUG=/dev/tty

setup() {
  load "${BATS_PLUGIN_PATH}/load.bash"

  export VAULT_ADDR=https://vault_svr_url
  export BUILDKITE_PIPELINE_SLUG=testpipe
}

#-------
@test "Add environment secret var to project using example helper" {
  EXPECTED_DATA='TVlfU0VDUkVUPSdmb29ibGFoJwo=' # MY_SECRET='fooblah'
  INPUT_DATA=$(mktemp)

  stub vault \
    "token-lookup : exit 0" \
    "write kv/buildkite/testpipe/env/MY_SECRET value=- : cat >${INPUT_DATA}"

  run bash -c "$PWD/examples/update-env-secret --pipeline ${BUILDKITE_PIPELINE_SLUG} --var MY_SECRET --value fooblah"

  assert_success
  assert_equal "$(cat "${INPUT_DATA}")" "${EXPECTED_DATA}"

  unstub vault
  rm "${INPUT_DATA}"
}

@test "Add environment secret var to project using example helper via stdin" {
  EXPECTED_DATA='TVlfU0VDUkVUPSdmb29ibGFoJwo=' # MY_SECRET='fooblah'
  INPUT_DATA=$(mktemp)

  stub vault \
    "token-lookup : exit 0" \
    "write kv/buildkite/testpipe/env/MY_SECRET value=- : cat >${INPUT_DATA}"

  run bash -c "echo fooblah | $PWD/examples/update-env-secret --pipeline ${BUILDKITE_PIPELINE_SLUG} --var MY_SECRET"

  assert_success
  assert_equal "$(cat "${INPUT_DATA}")" "${EXPECTED_DATA}"

  unstub vault
  rm "${INPUT_DATA}"
}

@test "Adding environment secret var to default will fail using example helper" {
  unset BUILDKITE_PIPELINE_SLUG

  run bash -c "$PWD/examples/update-env-secret --var MY_SECRET --value fooblah"

  assert_failure

  assert_output --partial "--pipeline is a required argument."
}

@test "Will environment helper exit if Vault_ADDR is not defined" {
  unset VAULT_ADDR

  run bash -c "$PWD/examples/update-env-secret --pipeline ${BUILDKITE_PIPELINE_SLUG} --var MY_SECRET --value fooblah"

  assert_failure

  assert_output --partial "set env var VAULT_ADDR for your vault server"
}
