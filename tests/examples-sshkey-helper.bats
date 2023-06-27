#!/usr/bin/env bats

load "${BATS_PLUGIN_PATH}/load.bash"

# export SSH_AGENT_STUB_DEBUG=/dev/tty
# export SSH_KEYGEN_STUB_DEBUG=/dev/tty
# export SSH_ADD_STUB_DEBUG=/dev/tty
# export VAULT_STUB_DEBUG=/dev/tty
# export GIT_STUB_DEBUG=/dev/tty

#-------
@test "Add sshkey secret var to project using example helper" {
  skip "deprecating this example script"
  export VAULT_ADDR=https://vault_svr_url
  export BUILDKITE_PIPELINE_SLUG=testpipe

  stub ssh-keygen \
    "-f \* -N '' : touch \$2 ; touch \$2.pub"

  stub vault \
    "token-lookup : exit 0" \
    "write kv/buildkite/testpipe/private_ssh_key value=- : exit 0" \
    "write kv/buildkite/testpipe/private_ssh_key.pub value=- : exit 0"

  run bash -c "$PWD/examples/update-sshkey-secret --pipeline ${BUILDKITE_PIPELINE_SLUG}"

  assert_success

  unstub ssh-keygen
  unstub vault
}

@test "Adding sshkey secret var to default will fail using example helper" {
  skip "deprecating this example script"
  export VAULT_ADDR=https://vault_svr_url

  run bash -c "$PWD/examples/update-sshkey-secret"

  assert_failure

  assert_output --partial "--pipeline is a required argument."
  unset VAULT_ADDR
}

@test "Will sshkey helper exit if Vault_ADDR is not defined" {
  skip "deprecating this example script"
  export BUILDKITE_PIPELINE_SLUG=testpipe
  run bash -c "$PWD/examples/update-sshkey-secret --pipeline ${BUILDKITE_PIPELINE_SLUG}"

  assert_failure

  assert_output --partial "define VAULT_ADDR"

  unset BUILDKITE_PIPELINE_SLUG
}
