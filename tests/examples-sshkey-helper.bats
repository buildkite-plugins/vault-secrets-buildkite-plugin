#!/usr/bin/env bats

load '/usr/local/lib/bats/load.bash'

# export SSH_AGENT_STUB_DEBUG=/dev/tty
# export SSH_KEYGEN_STUB_DEBUG=/dev/tty
# export SSH_ADD_STUB_DEBUG=/dev/tty
# export VAULT_STUB_DEBUG=/dev/tty
# export GIT_STUB_DEBUG=/dev/tty

#-------
@test "Add sshkey secret var to project using example helper" {
  export VAULT_ADDR=https://vault_svr_url
  export BUILDKITE_PIPELINE_SLUG=testpipe
  export TESTDATA=`echo MY_SECRET=fooblah | base64`

  stub ssh-keygen \
    "-f ./private_ssh_key -N : touch private_ssh_key ; touch private_ssh_key.pub"
  # Due to the anonyances of escaping variables etc ...
  # ssh-keygen is actually run with -N '', but that doesn't play nice with the stub so we ignore it

  stub vault \
    "token-lookup : exit 0" \
    "write kv/buildkite/testpipe/private_ssh_key value=- : exit 0" \
    "write kv/buildkite/testpipe/private_ssh_key.pub value=- : exit 0"

  run bash -c "$PWD/examples/update-sshkey-secret --pipeline ${BUILDKITE_PIPELINE_SLUG}"

  assert_success

  unstub ssh-keygen
  unstub vault

  unset TESTDATA
  unset BUILDKITE_PIPELINE_SLUG
  unset VAULT_ADDR
}

@test "Adding sshkey secret var to default will fail using example helper" {
  export VAULT_ADDR=https://vault_svr_url

  run bash -c "$PWD/examples/update-sshkey-secret"

  assert_failure

  assert_output --partial "--pipeline is a required argument."
  unset VAULT_ADDR
}

@test "Will sshkey helper exit if Vault_ADDR is not defined" {
  export BUILDKITE_PIPELINE_SLUG=testpipe
  run bash -c "$PWD/examples/update-sshkey-secret --pipeline ${BUILDKITE_PIPELINE_SLUG}"

  assert_failure

  assert_output --partial "define VAULT_ADDR"

  unset BUILDKITE_PIPELINE_SLUG
}
