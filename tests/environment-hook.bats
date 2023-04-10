#!/usr/bin/env bats

load '/usr/local/lib/bats/load.bash'

# export SSH_AGENT_STUB_DEBUG=/dev/tty
# export SSH_ADD_STUB_DEBUG=/dev/tty
# export VAULT_STUB_DEBUG=/dev/tty
# export GIT_STUB_DEBUG=/dev/tty

#-------
# Default scope
@test "Load default env file from vault server" {
  export BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER=https://vault_svr_url
  export BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV=true
  export TESTDATA='MY_SECRET=fooblah'
  export BUILDKITE_PIPELINE_SLUG=testpipe

  stub vault \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite/testpipe : exit 0" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite : echo 'env'" \
    "kv get -address=https://vault_svr_url -field=data -format=yaml data/buildkite/env : echo ${TESTDATA}"

  run bash -c "$PWD/hooks/environment && $PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "MY_SECRET=fooblah"
  refute_output --partial "ANOTHER_SECRET=baa"

  unstub vault
}

@test "Load default env file containing secrets with special characters from vault server" {
  export BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER=https://vault_svr_url
  export BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV=true
  export TESTDATA="MY_SECRET=\"|- $:fooblah\""
  export BUILDKITE_PIPELINE_SLUG=testpipe

  stub vault \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite/testpipe : exit 0" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite : echo 'env'" \
    "kv get -address=https://vault_svr_url -field=data -format=yaml data/buildkite/env : echo ${TESTDATA}"

  run bash -c "$PWD/hooks/environment && $PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "MY_SECRET=|- $:fooblah"
  refute_output --partial "ANOTHER_SECRET=baa"

  unstub vault
}


@test "Load default env file and convert secrets with \": \" pattern from vault server" {
  export BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER=https://vault_svr_url
  export BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV=true
  export TESTDATA="MY_SECRET=\"Likes: llamas\""
  export BUILDKITE_PIPELINE_SLUG=testpipe

  stub vault \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite/testpipe : exit 0" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite : echo 'env'" \
    "kv get -address=https://vault_svr_url -field=data -format=yaml data/buildkite/env : echo ${TESTDATA}"

  run bash -c "$PWD/hooks/environment && $PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "MY_SECRET=Likes=llamas"
  refute_output --partial "ANOTHER_SECRET=baa"

  unstub vault
}


@test "Load default environment file from vault server" {
  export BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER=https://vault_svr_url
  export BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV=true
  export TESTDATA='MY_SECRET=fooblah'
  export BUILDKITE_PIPELINE_SLUG=testpipe

  stub vault \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite/testpipe : exit 0" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite : echo 'environment'" \
    "kv get -address=https://vault_svr_url -field=data -format=yaml data/buildkite/environment : echo ${TESTDATA}"

  run bash -c "$PWD/hooks/environment && $PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "MY_SECRET=fooblah"
  refute_output --partial "ANOTHER_SECRET=baa"

  unstub vault
}

@test "Load default env and environments files from vault server" {
  export BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER=https://vault_svr_url
  export BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV=true
  export TESTDATA_ENV1='MY_SECRET=fooblah'
  export TESTDATA_ENV2='ANOTHER_SECRET=baa'
  export BUILDKITE_PIPELINE_SLUG=testpipe



  stub vault \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite/testpipe : exit 0" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite : echo 'env environment'" \
    "kv get -address=https://vault_svr_url -field=data -format=yaml data/buildkite/env : echo ${TESTDATA_ENV1}" \
    "kv get -address=https://vault_svr_url -field=data -format=yaml data/buildkite/environment : echo ${TESTDATA_ENV2}"

  run bash -c "$PWD/hooks/environment && $PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "MY_SECRET=fooblah"
  assert_output --partial "ANOTHER_SECRET=baa"

  unstub vault
}

#-------
# Project scope
@test "Load project env file from vault server" {
  export BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER=https://vault_svr_url
  export BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV=true
  export BUILDKITE_PIPELINE_SLUG=testpipe
  export TESTDATA='MY_SECRET=fooblah'

  stub vault \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite/testpipe : echo 'env'" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite : exit 0" \
    "kv get -address=https://vault_svr_url -field=data -format=yaml data/buildkite/testpipe/env : echo '${TESTDATA}'" \

  run bash -c "$PWD/hooks/environment && $PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "MY_SECRET=fooblah"
  refute_output --partial "ANOTHER_SECRET=baa"

  unstub vault
}

@test "Load project environment file from vault server" {
  export BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER=https://vault_svr_url
  export BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV=true
  export BUILDKITE_PIPELINE_SLUG=testpipe
  export TESTDATA='echo MY_SECRET=fooblah'

  stub vault \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite/testpipe : echo 'environment'" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite : exit 0" \
    "kv get -address=https://vault_svr_url -field=data -format=yaml data/buildkite/testpipe/environment : echo ${TESTDATA}" \

  run bash -c "$PWD/hooks/environment && $PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "MY_SECRET=fooblah"
  refute_output --partial "ANOTHER_SECRET=baa"

  unstub vault


}

@test "Load project env and environments files from vault server" {
  export BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER=https://vault_svr_url
  export BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV=true
  export BUILDKITE_PIPELINE_SLUG=testpipe
  export TESTDATA_ENV1='echo MY_SECRET=fooblah'
  export TESTDATA_ENV2='echo ANOTHER_SECRET=baa'

  stub vault \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite/testpipe : echo 'env environment'" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite : exit 0" \
    "kv get -address=https://vault_svr_url -field=data -format=yaml data/buildkite/testpipe/env : echo ${TESTDATA_ENV1}" \
    "kv get -address=https://vault_svr_url -field=data -format=yaml data/buildkite/testpipe/environment : echo ${TESTDATA_ENV2}"

  run bash -c "$PWD/hooks/environment && $PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "MY_SECRET=fooblah"
  assert_output --partial "ANOTHER_SECRET=baa"

  unstub vault

}

#-------
# Combinations of scopes
@test "Load default and project env files from vault server" {
  export BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER=https://vault_svr_url
  export BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV=true
  export BUILDKITE_PIPELINE_SLUG=testpipe
  export TESTDATA_ENV1='echo MY_SECRET=fooblah'
  export TESTDATA_ENV2='echo ANOTHER_SECRET=baa'

  stub vault \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite/testpipe : echo 'env'" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite : echo 'env'" \
    "kv get -address=https://vault_svr_url -field=data -format=yaml data/buildkite/testpipe/env : echo ${TESTDATA_ENV1}" \
    "kv get -address=https://vault_svr_url -field=data -format=yaml data/buildkite/env : echo ${TESTDATA_ENV2}"

  run bash -c "$PWD/hooks/environment && $PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "MY_SECRET=fooblah"
  assert_output --partial "ANOTHER_SECRET=baa"

  unstub vault


}

@test "Load default and project environment files from vault server" {
  export BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER=https://vault_svr_url
  export BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV=true
  export BUILDKITE_PIPELINE_SLUG=testpipe
  export TESTDATA_ENV1='echo MY_SECRET=fooblah'
  export TESTDATA_ENV2='echo ANOTHER_SECRET=baa'

  stub vault \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite/testpipe : echo 'environment'" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite : echo 'environment'" \
    "kv get -address=https://vault_svr_url -field=data -format=yaml data/buildkite/testpipe/environment : echo ${TESTDATA_ENV1}" \
    "kv get -address=https://vault_svr_url -field=data -format=yaml data/buildkite/environment : echo ${TESTDATA_ENV2}"

  run bash -c "$PWD/hooks/environment && $PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "MY_SECRET=fooblah"
  assert_output --partial "ANOTHER_SECRET=baa"

  unstub vault

}

#-------
# All scopes and env, environment files
@test "Load env and environments files for project and default from vault server" {
  export BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER=https://vault_svr_url
  export BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV=true
  export BUILDKITE_PIPELINE_SLUG=testpipe
  export TESTDATA_ENV1='echo MY_SECRET1=baa1'
  export TESTDATA_ENV2='echo MY_SECRET2=baa2'
  export TESTDATA_ENV3='echo MY_SECRET3=baa3'
  export TESTDATA_ENV4='echo MY_SECRET4=baa4'

  stub vault \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite/testpipe : echo 'env environment'" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite : echo 'env environment'" \
    "kv get -address=https://vault_svr_url -field=data -format=yaml data/buildkite/testpipe/env : echo ${TESTDATA_ENV1}" \
    "kv get -address=https://vault_svr_url -field=data -format=yaml data/buildkite/testpipe/environment : echo ${TESTDATA_ENV2}" \
    "kv get -address=https://vault_svr_url -field=data -format=yaml data/buildkite/env : echo ${TESTDATA_ENV3}" \
    "kv get -address=https://vault_svr_url -field=data -format=yaml data/buildkite/environment : echo ${TESTDATA_ENV4}"
    

  run bash -c "$PWD/hooks/environment && $PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "MY_SECRET1=baa1"
  assert_output --partial "MY_SECRET2=baa2"
  assert_output --partial "MY_SECRET3=baa3"
  assert_output --partial "MY_SECRET4=baa4"

  unstub vault

}

#-------
# Git Credentials
@test "Load default git-credentials from vault into GIT_CONFIG_PARAMETERS" {
  export BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER=https://vault_svr_url
  export BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV=true
  export BUILDKITE_PIPELINE_SLUG=testpipe

  stub vault \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite/testpipe : exit 0 " \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite : echo -e '- git-credentials'"

  run bash -c "$PWD/hooks/environment && $PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "Adding git-credentials in data/buildkite/git-credentials as a credential helper"
  assert_output --partial "GIT_CONFIG_PARAMETERS='credential.helper="

  unstub vault
}

@test "Load pipeline git-credentials from vault into GIT_CONFIG_PARAMETERS" {
  export BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER=https://vault_svr_url
  export BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV=true
  export BUILDKITE_PIPELINE_SLUG=testpipe
  export TESTDATA_ENV1='MY_SECRET1=baa1'

  stub vault \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite/testpipe : echo -e '- git-credentials'" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite : exit 0"

  run bash -c "$PWD/hooks/environment && $PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "Adding git-credentials in data/buildkite/testpipe/git-credentials as a credential helper"
  assert_output --partial "GIT_CONFIG_PARAMETERS='credential.helper="
  unstub vault

  unset TESTDATA_ENV1
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER
  unset BUILDKITE_PIPELINE_SLUG
}

#-------
# ssh-keys
@test "Load default ssh-key from vault into ssh-agent" {
  export BUILDKITE_PIPELINE_SLUG=testpipe
  export BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER=https://vault_svr_url
  export BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV=true
  export BUILDKITE_PIPELINE_SLUG=testpipe
  export TESTDATA='echo foobar'

  stub ssh-agent "-s : echo export SSH_AGENT_PID=26345"

  stub vault \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite/testpipe : exit 0" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite : echo -e '- private_ssh_key'" \
    "kv get -address=https://vault_svr_url -field=data -format=yaml data/buildkite/private_ssh_key : echo ${TESTDATA}"

  stub ssh-add \
    '- : echo added ssh key'

  run bash -c "$PWD/hooks/environment && $PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "ssh-agent (pid 26345)"
  assert_output --partial "added ssh key"

  unstub ssh-agent
  unstub vault
  unstub ssh-add
}

@test "Load project ssh-key from vault into ssh-agent" {
  export BUILDKITE_PIPELINE_SLUG=testpipe
  export BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER=https://vault_svr_url
  export BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV=true
  export BUILDKITE_PIPELINE_SLUG=testpipe
  export TESTDATA='echo foobar'

  stub ssh-agent "-s : echo export SSH_AGENT_PID=26345"

  stub vault \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite/testpipe : echo -e '- private_ssh_key'" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite : exit 0" \
    "kv get -address=https://vault_svr_url -field=data -format=yaml data/buildkite/testpipe/private_ssh_key : echo ${TESTDATA}"

  stub ssh-add \
    '- : echo added ssh key'

  run bash -c "$PWD/hooks/environment && $PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "ssh-agent (pid 26345)"
  assert_output --partial "added ssh key"

  unstub ssh-agent
  unstub vault
  unstub ssh-add
}

@test "Load default and project ssh-keys from vault into ssh-agent" {
  export BUILDKITE_PIPELINE_SLUG=testpipe
  export BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER=https://vault_svr_url
  export BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV=true
  export BUILDKITE_PIPELINE_SLUG=testpipe
  export TESTDATA='echo foobar'
  export TESTDATA2='echo foobar2'

  stub ssh-agent "-s : echo export SSH_AGENT_PID=26345"

  stub vault \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite/testpipe : echo -e '- private_ssh_key'" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite : echo -e '- private_ssh_key'" \
    "kv get -address=https://vault_svr_url -field=data -format=yaml data/buildkite/testpipe/private_ssh_key : echo ${TESTDATA}" \
    "kv get -address=https://vault_svr_url -field=data -format=yaml data/buildkite/private_ssh_key : echo ${TESTDATA2}"

  stub ssh-add \
    '- : echo added ssh key' \
    '- : echo added ssh key'

  run bash -c "$PWD/hooks/environment && $PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "ssh-agent (pid 26345)"
  assert_output --partial "added ssh key"

  unstub ssh-agent
  unstub vault
  unstub ssh-add

}
#-------
#
@test "Load default ssh-key and env from vault" {
  export BUILDKITE_PIPELINE_SLUG=testpipe
  export BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER=https://vault_svr_url
  export BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV=true
  export BUILDKITE_PIPELINE_SLUG=testpipe
  export TESTDATA_KEY='echo foobar'
  export TESTDATA_ENV='MY_SECRET=fooblah'

  stub ssh-agent "-s : echo export SSH_AGENT_PID=54252"

  stub vault \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite/testpipe : exit 0" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite : echo -e 'private_ssh_key env'" \
    "kv get -address=https://vault_svr_url -field=data -format=yaml data/buildkite/private_ssh_key : echo ${TESTDATA_KEY}" \
    "kv get -address=https://vault_svr_url -field=data -format=yaml data/buildkite/env : echo ${TESTDATA_ENV}" \

  stub ssh-add \
    '- : echo added ssh key'

  run bash -c "$PWD/hooks/environment && $PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "ssh-agent (pid 54252)"
  assert_output --partial "added ssh key"
  assert_output --partial "MY_SECRET=fooblah"

  unstub ssh-agent
  unstub vault
  unstub ssh-add
}

@test "Load project ssh-key and env from vault" {
  export BUILDKITE_PIPELINE_SLUG=testpipe
  export BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER=https://vault_svr_url
  export BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV=true
  export BUILDKITE_PIPELINE_SLUG=testpipe
  export TESTDATA_KEY='echo foobar'
  export TESTDATA_ENV='MY_SECRET=fooblah'

  stub ssh-agent "-s : echo export SSH_AGENT_PID=12423"

  stub vault \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite/testpipe : echo 'private_ssh_key env'" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite : exit 0 " \
    "kv get -address=https://vault_svr_url -field=data -format=yaml data/buildkite/testpipe/private_ssh_key : echo ${TESTDATA_KEY}" \
    "kv get -address=https://vault_svr_url -field=data -format=yaml data/buildkite/testpipe/env : echo ${TESTDATA_ENV}" \

  stub ssh-add \
    '- : echo added ssh key'

  run bash -c "$PWD/hooks/environment && $PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "ssh-agent (pid 12423)"
  assert_output --partial "added ssh key"
  assert_output --partial "MY_SECRET=fooblah"

  unstub ssh-agent
  unstub vault
  unstub ssh-add
}

#-------
#
@test "Load default ssh-key, env and git-credentials from vault into ssh-agent" {
  export BUILDKITE_PIPELINE_SLUG=testpipe
  export BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER=https://vault_svr_url
  export BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV=true
  export BUILDKITE_PIPELINE_SLUG=testpipe
  export TESTDATA_KEY='echo foobar'
  export TESTDATA_ENV='MY_SECRET=fooblah'
  export TESTDATA_GIT='me@pass'

  stub ssh-agent "-s : echo export SSH_AGENT_PID=24124"

  stub vault \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite/testpipe : exit 0" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite : echo -e 'env private_ssh_key git-credentials'" \
    "kv get -address=https://vault_svr_url -field=data -format=yaml data/buildkite/env : echo ${TESTDATA_ENV}" \
    "kv get -address=https://vault_svr_url -field=data -format=yaml data/buildkite/private_ssh_key : echo ${TESTDATA_KEY}"

  stub ssh-add \
    '- : echo added ssh key'

  run bash -c "$PWD/hooks/environment && $PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "ssh-agent (pid 24124)"
  assert_output --partial "added ssh key"
  assert_output --partial "MY_SECRET=fooblah"
  assert_output --partial "Adding git-credentials in data/buildkite/git-credentials as a credential helper"
  assert_output --partial "GIT_CONFIG_PARAMETERS='credential.helper="
  # assert_output --partial "Could not open a connection to your authentication agent"

  unstub ssh-agent
  unstub vault
  unstub ssh-add
}

@test "Load project ssh-key, env and git-credentials from vault into ssh-agent" {
  export BUILDKITE_PIPELINE_SLUG=testpipe
  export BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER=https://vault_svr_url
  export BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV=true
  export BUILDKITE_PIPELINE_SLUG=testpipe
  export TESTDATA_KEY='echo foobar'
  export TESTDATA_ENV='MY_SECRET=fooblah'
  export TESTDATA_GIT='me@pass'

  stub ssh-agent "-s : echo export SSH_AGENT_PID=12423"

  stub vault \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite/testpipe : echo -e 'env private_ssh_key git-credentials'" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite : exit 0" \
    "kv get -address=https://vault_svr_url -field=data -format=yaml data/buildkite/testpipe/env : echo ${TESTDATA_ENV}" \
    "kv get -address=https://vault_svr_url -field=data -format=yaml data/buildkite/testpipe/private_ssh_key : echo ${TESTDATA_KEY}"

  stub ssh-add \
    '- : echo added ssh key'

  run bash -c "$PWD/hooks/environment && $PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "ssh-agent (pid 12423)"
  assert_output --partial "added ssh key"
  assert_output --partial "MY_SECRET=fooblah"
  assert_output --partial "Adding git-credentials in data/buildkite/testpipe/git-credentials as a credential helper"
  assert_output --partial "GIT_CONFIG_PARAMETERS='credential.helper="

  unstub ssh-agent
  unstub vault
  unstub ssh-add
}

@test "Dump env secrets" {
  export BUILDKITE_PIPELINE_SLUG=testpipe
  export BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER=https://vault_svr_url
  export BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV=true
  export BUILDKITE_PIPELINE_SLUG=testpipe
  export TESTDATA_ENV_1='TEST_SECRET=foobar'
  export TESTDATA_ENV_2='ANOTHER_SECRET=foo'

  stub vault \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite/testpipe : echo -e 'env'" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite : exit 0" \
    "kv get -address=https://vault_svr_url -field=data -format=yaml data/buildkite/testpipe/env : echo '${TESTDATA_ENV_1}\n ${TESTDATA_ENV_2}'" \

  run bash -c "$PWD/hooks/environment && $PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "TEST_SECRET=foobar"
  assert_output --partial "ANOTHER_SECRET=foo"

  unstub vault

  unset TESTDATA
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER
  unset BUILDKITE_PIPELINE_SLUG
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV
}

@test "test path option" {
  export BUILDKITE_PLUGIN_VAULT_SECRETS_PATH=foobar
  export BUILDKITE_PIPELINE_SLUG=testpipe
  export BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER=https://vault_svr_url
  export BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV=false
  export BUILDKITE_PIPELINE_SLUG=testpipe

  stub vault \
    "kv list -address=https://vault_svr_url -format=yaml foobar/testpipe : exit 0" \
    "kv list -address=https://vault_svr_url -format=yaml foobar : exit 0"

  run bash -c "$PWD/hooks/environment && $PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "Checking vault secrets foobar/testpipe"
  assert_output --partial "Checking vault secrets foobar"

  unstub vault

  unset BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER
  unset BUILDKITE_PIPELINE_SLUG
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_PATH
}

@test "Custom Namespace is set in environment hook" {
  export BUILDKITE_PLUGIN_VAULT_SECRETS_NAMESPACE=llamas
  export BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER=https://vault_svr_url
  export BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV=true
  export TESTDATA='MY_SECRET=fooblah'
  export BUILDKITE_PIPELINE_SLUG=testpipe

  stub vault \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite/testpipe : exit 0" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite : echo 'env'" \
    "kv get -address=https://vault_svr_url -field=data -format=yaml data/buildkite/env : echo ${TESTDATA}"

  run bash -c "$PWD/hooks/environment && $PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "Using namespace: llamas"
  assert_output --partial "MY_SECRET=fooblah"
  refute_output --partial "ANOTHER_SECRET=baa"

  unstub vault
}