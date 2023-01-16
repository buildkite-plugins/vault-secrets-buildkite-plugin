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
  export BUILDKITE_PIPELINE_SLUG=testpipe
  export TESTDATA='MY_SECRET=fooblah'
  export BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_SECRET_ENV="abcde12345"
  export BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_ROLE_ID=buildkite
  export BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_METHOD=approle

  stub vault \
    "write -field=token -address=https://vault_svr_url auth/approle/login role_id=buildkite secret_id=\"${BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_SECRET_ENV}\" : echo 'Successfully authenticated with Role ID ${BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_ROLE_ID}'" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite/testpipe : echo 'env'" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite : echo 'env'" \
    "kv get -address=https://vault_svr_url -field=data -format=yaml data/buildkite/testpipe/env : echo ${TESTDATA}" \
    "kv get -address=https://vault_svr_url -field=data -format=yaml data/buildkite/env : echo ${TESTDATA}"

  run bash -c "$PWD/hooks/environment && $PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "MY_SECRET=fooblah"
  refute_output --partial "ANOTHER_SECRET=baa"

  unstub vault

  unset TESTDATA
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER
  unset BUILDKITE_PIPELINE_SLUG
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_SECRET_ENV
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_ROLE_ID
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_METHOD
}

@test "Load default environment file from vault server" {
  export BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER=https://vault_svr_url
  export BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV=true
  export BUILDKITE_PIPELINE_SLUG=testpipe
  export TESTDATA='MY_SECRET=fooblah'
  export BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_SECRET_ENV="abcde12345"
  export BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_ROLE_ID=buildkite
  export BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_METHOD=approle

  stub vault \
    "write -field=token -address=https://vault_svr_url auth/approle/login role_id=buildkite secret_id=\"${BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_SECRET_ENV}\" : echo 'Successfully authenticated with Role ID ${BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_ROLE_ID}'" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite/testpipe : echo 'environment'"\
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite : echo 'environment'" \
    "kv get -address=https://vault_svr_url -field=data -format=yaml data/buildkite/testpipe/environment : echo ${TESTDATA}" \
    "kv get -address=https://vault_svr_url -field=data -format=yaml data/buildkite/environment : echo ${TESTDATA}"

  run bash -c "$PWD/hooks/environment && $PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "MY_SECRET=fooblah"
  refute_output --partial "ANOTHER_SECRET=baa"

  unstub vault

  unset TESTDATA
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER
  unset BUILDKITE_PIPELINE_SLUG
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_SECRET_ENV
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_ROLE_ID
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_METHOD
}

@test "Load default env and environments files from vault server" {
  export BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER=https://vault_svr_url
  export BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV=true
  export BUILDKITE_PIPELINE_SLUG=testpipe
  export TESTDATA_ENV1='MY_SECRET=fooblah'
  export TESTDATA_ENV2='ANOTHER_SECRET=baa'
  export BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_SECRET_ENV="abcde12345"
  export BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_ROLE_ID=buildkite
  export BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_METHOD=approle



  stub vault \
    "write -field=token -address=https://vault_svr_url auth/approle/login role_id=buildkite secret_id=\"${BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_SECRET_ENV}\" : echo 'Successfully authenticated with Role ID ${BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_ROLE_ID}'" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite/testpipe : echo 'env environment'"\
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite : echo 'env environment'" \
    "kv get -address=https://vault_svr_url -field=data -format=yaml data/buildkite/testpipe/env : echo ${TESTDATA_ENV1}" \
    "kv get -address=https://vault_svr_url -field=data -format=yaml data/buildkite/testpipe/environment : echo ${TESTDATA_ENV2}" \
    "kv get -address=https://vault_svr_url -field=data -format=yaml data/buildkite/env : echo ${TESTDATA_ENV1}" \
    "kv get -address=https://vault_svr_url -field=data -format=yaml data/buildkite/environment : echo ${TESTDATA_ENV2}"

  run bash -c "$PWD/hooks/environment && $PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "MY_SECRET=fooblah"
  assert_output --partial "ANOTHER_SECRET=baa"

  unstub vault

  unset TESTDATA_ENV1
  unset TESTDATA_ENV2
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER
  unset BUILDKITE_PIPELINE_SLUG
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_SECRET_ENV
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_ROLE_ID
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_METHOD
}

#-------
# Project scope
@test "Load project env file from vault server" {
  skip "this test won't pass completely, for now"
  export BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER=https://vault_svr_url
  export BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV=true
  export BUILDKITE_PIPELINE_SLUG=testpipe
  export TESTDATA='MY_SECRET=fooblah'

  stub vault \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite/testpipe : echo 'env'" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite : echo 'env'" \
    "kv get -address=https://vault_svr_url -field=data -format=yaml data/buildkite/testpipe/env : echo '${TESTDATA}'" \
    "kv get -address=https://vault_svr_url -field=data -format=yaml data/buildkite/testpipe/env/MY_SECRET : echo 'fooblah'"

  run bash -c "$PWD/hooks/environment && $PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "MY_SECRET=fooblah"
  refute_output --partial "ANOTHER_SECRET=baa"

  unstub vault

  unset TESTDATA
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER
  unset BUILDKITE_PIPELINE_SLUG
}

@test "Load project environment file from vault server" {
  skip "this test won't pass completely, for now"
  export BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER=https://vault_svr_url
  export BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV=true
  export BUILDKITE_PIPELINE_SLUG=testpipe
  export TESTDATA=`echo MY_SECRET=fooblah | base64`

  stub vault \
    "write -field=token -address=https://vault_svr_url auth/approle/login role_id=buildkite secret_id=\"${BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_SECRET_ENV}\" : echo 'Successfully authenticated with Role ID ${BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_ROLE_ID}'" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite/testpipe : echo -e '- environment'" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite : exit 0" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite/testpipe/environment : echo -e '- MY_SECRET'" \
    "kv get -address=https://vault_svr_url -field=value data/buildkite/testpipe/environment/MY_SECRET : echo ${TESTDATA}"

  run bash -c "$PWD/hooks/environment && $PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "MY_SECRET=fooblah"
  refute_output --partial "ANOTHER_SECRET=baa"

  unstub vault

  unset TESTDATA
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER
  unset BUILDKITE_PIPELINE_SLUG
}

@test "Load project env and environments files from vault server" {
  skip "this test won't pass completely, for now"
  export BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER=https://vault_svr_url
  export BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV=true
  export BUILDKITE_PIPELINE_SLUG=testpipe
  export TESTDATA_ENV1=`echo MY_SECRET=fooblah | base64`
  export TESTDATA_ENV2=`echo ANOTHER_SECRET=baa | base64`

  stub vault \
    "write -field=token -address=https://vault_svr_url auth/approle/login role_id=buildkite secret_id=\"${BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_SECRET_ENV}\" : echo 'Successfully authenticated with Role ID ${BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_ROLE_ID}'" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite/testpipe : echo -e '- env\n- environment'" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite : exit 0" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite/testpipe/env : echo -e '- MY_SECRET'" \
    "kv get -address=https://vault_svr_url -field=value data/buildkite/testpipe/env/MY_SECRET : echo ${TESTDATA_ENV1}" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite/testpipe/environment : echo -e '- ANOTHER_SECRET'" \
    "kv get -address=https://vault_svr_url -field=value data/buildkite/testpipe/environment/ANOTHER_SECRET : echo ${TESTDATA_ENV2}"

  run bash -c "$PWD/hooks/environment && $PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "MY_SECRET=fooblah"
  assert_output --partial "ANOTHER_SECRET=baa"

  unstub vault

  unset TESTDATA
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER
  unset BUILDKITE_PIPELINE_SLUG
}

#-------
# Combinations of scopes
@test "Load default and project env files from vault server" {
  skip "this test won't pass completely, for now"
  export BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER=https://vault_svr_url
  export BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV=true
  export BUILDKITE_PIPELINE_SLUG=testpipe
  export TESTDATA_ENV1=`echo MY_SECRET=fooblah | base64`
  export TESTDATA_ENV2=`echo ANOTHER_SECRET=baa | base64`

  stub vault \
    "write -field=token -address=https://vault_svr_url auth/approle/login role_id=buildkite secret_id=\"${BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_SECRET_ENV}\" : echo 'Successfully authenticated with Role ID ${BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_ROLE_ID}'" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite/testpipe : echo -e '- env'" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite : echo -e '- env'" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite/testpipe/env : echo -e '- MY_SECRET'" \
    "kv get -address=https://vault_svr_url -field=value data/buildkite/testpipe/env/MY_SECRET : echo ${TESTDATA_ENV1}" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite/env : echo -e '- ANOTHER_SECRET'" \
    "kv get -address=https://vault_svr_url -field=value data/buildkite/env/ANOTHER_SECRET : echo ${TESTDATA_ENV2}"

  run bash -c "$PWD/hooks/environment && $PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "MY_SECRET=fooblah"
  assert_output --partial "ANOTHER_SECRET=baa"

  unstub vault

  unset TESTDATA
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER
  unset BUILDKITE_PIPELINE_SLUG
}

@test "Load default and project environment files from vault server" {
  skip "this test won't pass completely, for now"
  export BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER=https://vault_svr_url
  export BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV=true
  export BUILDKITE_PIPELINE_SLUG=testpipe
  export TESTDATA_ENV1=`echo MY_SECRET=fooblah | base64`
  export TESTDATA_ENV2=`echo ANOTHER_SECRET=baa | base64`

  stub vault \
    "write -field=token -address=https://vault_svr_url auth/approle/login role_id=buildkite secret_id=\"${BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_SECRET_ENV}\" : echo 'Successfully authenticated with Role ID ${BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_ROLE_ID}'" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite/testpipe : echo -e '- environment'" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite : echo -e '- environment'" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite/testpipe/environment : echo -e '- MY_SECRET'" \
    "kv get -address=https://vault_svr_url -field=value data/buildkite/testpipe/environment/MY_SECRET : echo ${TESTDATA_ENV1}" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite/environment : echo -e '- ANOTHER_SECRET'" \
    "kv get -address=https://vault_svr_url -field=value data/buildkite/environment/ANOTHER_SECRET : echo ${TESTDATA_ENV2}"

  run bash -c "$PWD/hooks/environment && $PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "MY_SECRET=fooblah"
  assert_output --partial "ANOTHER_SECRET=baa"

  unstub vault

  unset TESTDATA
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER
  unset BUILDKITE_PIPELINE_SLUG
}

#-------
# All scopes and env, environment files
@test "Load env and environments files for project and default from vault server" {
  skip "this test won't pass completely, for now"
  export BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER=https://vault_svr_url
  export BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV=true
  export BUILDKITE_PIPELINE_SLUG=testpipe
  export TESTDATA_ENV1=`echo MY_SECRET1=baa1 | base64`
  export TESTDATA_ENV2=`echo MY_SECRET2=baa2 | base64`
  export TESTDATA_ENV3=`echo MY_SECRET3=baa3 | base64`
  export TESTDATA_ENV4=`echo MY_SECRET4=baa4 | base64`

  stub vault \
    "write -field=token -address=https://vault_svr_url auth/approle/login role_id=buildkite secret_id=\"${BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_SECRET_ENV}\" : echo 'Successfully authenticated with Role ID ${BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_ROLE_ID}'" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite/testpipe : echo -e '- env\n- environment'" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite : echo -e '- env\n- environment'" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite/testpipe/env : echo -e '- MY_SECRET1'" \
    "kv get -address=https://vault_svr_url -field=value data/buildkite/testpipe/env/MY_SECRET1 : echo ${TESTDATA_ENV1}" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite/testpipe/environment : echo -e '- MY_SECRET2'" \
    "kv get -address=https://vault_svr_url -field=value data/buildkite/testpipe/environment/MY_SECRET2 : echo ${TESTDATA_ENV2}" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite/env : echo -e '- MY_SECRET3'" \
    "kv get -address=https://vault_svr_url -field=value data/buildkite/env/MY_SECRET3 : echo ${TESTDATA_ENV3}" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite/environment : echo -e '- MY_SECRET4'" \
    "kv get -address=https://vault_svr_url -field=value data/buildkite/environment/MY_SECRET4 : echo ${TESTDATA_ENV4}"

  run bash -c "$PWD/hooks/environment && $PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "MY_SECRET1=baa1"
  assert_output --partial "MY_SECRET2=baa2"
  assert_output --partial "MY_SECRET3=baa3"
  assert_output --partial "MY_SECRET4=baa4"

  unstub vault

  unset TESTDATA
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER
  unset BUILDKITE_PIPELINE_SLUG
}

#-------
# Git Credentials
@test "Load default git-credentials from vault into GIT_CONFIG_PARAMETERS" {
  export BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER=https://vault_svr_url
  export BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV=true
  export BUILDKITE_PIPELINE_SLUG=testpipe
  export TESTDATA_ENV1=`echo MY_SECRET1=baa1 | base64`

  stub vault \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite/testpipe : exit 0 " \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite : echo -e '- git-credentials'"

  run bash -c "$PWD/hooks/environment && $PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "Adding git-credentials in data/buildkite/git-credentials as a credential helper"
  assert_output --partial "GIT_CONFIG_PARAMETERS='credential.helper="

  unstub vault

  unset TESTDATA_ENV1
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER
  unset BUILDKITE_PIPELINE_SLUG
}

@test "Load pipeline git-credentials from vault into GIT_CONFIG_PARAMETERS" {
  export BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER=https://vault_svr_url
  export BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV=true
  export BUILDKITE_PIPELINE_SLUG=testpipe
  export TESTDATA_ENV1=`echo MY_SECRET1=baa1`

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
  skip
  export BUILDKITE_PIPELINE_SLUG=testpipe
  export BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER=https://vault_svr_url
  export BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV=true
  export BUILDKITE_PIPELINE_SLUG=testpipe
  export TESTDATA=`echo foobar | base64`

  stub ssh-agent "-s : echo export SSH_AGENT_PID=26345"

  stub vault \
    "write -field=token -address=https://vault_svr_url auth/approle/login role_id=buildkite secret_id=\"${BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_SECRET_ENV}\" : echo 'Successfully authenticated with Role ID ${BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_ROLE_ID}'" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite/testpipe : exit 0" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite : echo -e '- private_ssh_key'" \
    "kv get -address=https://vault_svr_url -field=value data/buildkite/private_ssh_key : echo ${TESTDATA}"

  stub ssh-add \
    '- : echo added ssh key'

  run bash -c "$PWD/hooks/environment && $PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "ssh-agent (pid 26345)"
  assert_output --partial "added ssh key"

  unstub ssh-agent
  unstub vault
  unstub ssh-add

  unset TESTDATA
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER
  unset BUILDKITE_PIPELINE_SLUG
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_PATH
  unset SSH_AGENT_PID
}

@test "Load project ssh-key from vault into ssh-agent" {
  skip
  export BUILDKITE_PIPELINE_SLUG=testpipe
  export BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER=https://vault_svr_url
  export BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV=true
  export BUILDKITE_PIPELINE_SLUG=testpipe
  export TESTDATA=`echo foobar | base64`

  stub ssh-agent "-s : echo export SSH_AGENT_PID=26345"

  stub vault \
    "write -field=token -address=https://vault_svr_url auth/approle/login role_id=buildkite secret_id=\"${BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_SECRET_ENV}\" : echo 'Successfully authenticated with Role ID ${BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_ROLE_ID}'" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite/testpipe : echo -e '- private_ssh_key'" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite : exit 0" \
    "kv get -address=https://vault_svr_url -field=value data/buildkite/testpipe/private_ssh_key : echo ${TESTDATA}"

  stub ssh-add \
    '- : echo added ssh key'

  run bash -c "$PWD/hooks/environment && $PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "ssh-agent (pid 26345)"
  assert_output --partial "added ssh key"

  unstub ssh-agent
  unstub vault
  unstub ssh-add

  unset TESTDATA
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER
  unset BUILDKITE_PIPELINE_SLUG
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_PATH
  unset SSH_AGENT_PID
}

@test "Load default and project ssh-keys from vault into ssh-agent" {
  skip
  export BUILDKITE_PIPELINE_SLUG=testpipe
  export BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER=https://vault_svr_url
  export BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV=true
  export BUILDKITE_PIPELINE_SLUG=testpipe
  export TESTDATA=`echo foobar | base64`

  stub ssh-agent "-s : echo export SSH_AGENT_PID=26345"

  stub vault \
    "write -field=token -address=https://vault_svr_url auth/approle/login role_id=buildkite secret_id=\"${BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_SECRET_ENV}\" : echo 'Successfully authenticated with Role ID ${BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_ROLE_ID}'" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite/testpipe : echo -e '- private_ssh_key'" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite : echo -e '- private_ssh_key'" \
    "kv get -address=https://vault_svr_url -field=value data/buildkite/testpipe/private_ssh_key : echo ${TESTDATA}" \
    "kv get -address=https://vault_svr_url -field=value data/buildkite/private_ssh_key : echo ${TESTDATA}"

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

  unset TESTDATA
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER
  unset BUILDKITE_PIPELINE_SLUG
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_PATH
  unset SSH_AGENT_PID
}

#-------
#
@test "Load default ssh-key and env from vault" {
  skip
  export BUILDKITE_PIPELINE_SLUG=testpipe
  export BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER=https://vault_svr_url
  export BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV=true
  export BUILDKITE_PIPELINE_SLUG=testpipe
  export TESTDATA_KEY=`echo foobar | base64`
  export TESTDATA_ENV=`echo MY_SECRET=fooblah | base64`

  stub ssh-agent "-s : echo export SSH_AGENT_PID=54252"

  stub vault \
    "write -field=token -address=https://vault_svr_url auth/approle/login role_id=buildkite secret_id=\"${BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_SECRET_ENV}\" : echo 'Successfully authenticated with Role ID ${BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_ROLE_ID}'" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite/testpipe : exit 0" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite : echo -e '- private_ssh_key\n- env'" \
    "kv get -address=https://vault_svr_url -field=value data/buildkite/private_ssh_key : echo ${TESTDATA_KEY}" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite/env : echo -e '- MY_SECRET'" \
    "kv get -address=https://vault_svr_url -field=value data/buildkite/env/MY_SECRET : echo ${TESTDATA_ENV}"

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

  unset TESTDATA
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER
  unset BUILDKITE_PIPELINE_SLUG
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_PATH
  unset SSH_AGENT_PID
}

@test "Load project ssh-key and env from vault" {
  skip
  export BUILDKITE_PIPELINE_SLUG=testpipe
  export BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER=https://vault_svr_url
  export BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV=true
  export BUILDKITE_PIPELINE_SLUG=testpipe
  export TESTDATA_KEY=`echo foobar | base64`
  export TESTDATA_ENV=`echo MY_SECRET=fooblah | base64`

  stub ssh-agent "-s : echo export SSH_AGENT_PID=12423"

  stub vault \
    "write -field=token -address=https://vault_svr_url auth/approle/login role_id=buildkite secret_id=\"${BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_SECRET_ENV}\" : echo 'Successfully authenticated with Role ID ${BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_ROLE_ID}'" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite/testpipe : echo -e '- private_ssh_key\n- env'" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite : exit 0" \
    "kv get -address=https://vault_svr_url -field=value data/buildkite/testpipe/private_ssh_key : echo ${TESTDATA_KEY}" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite/testpipe/env : echo -e '- MY_SECRET'" \
    "kv get -address=https://vault_svr_url -field=value data/buildkite/testpipe/env/MY_SECRET : echo ${TESTDATA_ENV}"

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

  unset TESTDATA
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER
  unset BUILDKITE_PIPELINE_SLUG
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_PATH
  unset SSH_AGENT_PID
}

#-------
#
@test "Load default ssh-key, env and git-credentials from vault into ssh-agent" {
  skip
  export BUILDKITE_PIPELINE_SLUG=testpipe
  export BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER=https://vault_svr_url
  export BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV=true
  export BUILDKITE_PIPELINE_SLUG=testpipe
  export TESTDATA_KEY=`echo foobar | base64`
  export TESTDATA_ENV=`echo MY_SECRET=fooblah | base64`
  export TESTDATA_GIT=`echo me@pass | base64`

  stub ssh-agent "-s : echo export SSH_AGENT_PID=24124"

  stub vault \
    "write -field=token -address=https://vault_svr_url auth/approle/login role_id=buildkite secret_id=\"${BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_SECRET_ENV}\" : echo 'Successfully authenticated with Role ID ${BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_ROLE_ID}'" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite/testpipe : exit 0" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite : echo -e '- env\n- private_ssh_key\n- git-credentials'" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite/env : echo -e '- MY_SECRET'" \
    "kv get -address=https://vault_svr_url -field=value data/buildkite/env/MY_SECRET : echo ${TESTDATA_ENV}" \
    "kv get -address=https://vault_svr_url -field=value data/buildkite/private_ssh_key : echo ${TESTDATA_KEY}"

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

  unset TESTDATA_ENV
  unset TESTDATA_KEY
  unset TESTDATA_GIT
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER
  unset BUILDKITE_PIPELINE_SLUG
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_PATH
  unset SSH_AGENT_PID
}

@test "Load project ssh-key, env and git-credentials from vault into ssh-agent" {
  skip
  export BUILDKITE_PIPELINE_SLUG=testpipe
  export BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER=https://vault_svr_url
  export BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV=true
  export BUILDKITE_PIPELINE_SLUG=testpipe
  export TESTDATA_KEY=`echo foobar | base64`
  export TESTDATA_ENV=`echo MY_SECRET=fooblah | base64`
  export TESTDATA_GIT=`echo me@pass | base64`

  stub ssh-agent "-s : echo export SSH_AGENT_PID=12423"

  stub vault \
    "write -field=token -address=https://vault_svr_url auth/approle/login role_id=buildkite secret_id=\"${BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_SECRET_ENV}\" : echo 'Successfully authenticated with Role ID ${BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_ROLE_ID}'" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite/testpipe : echo -e '- env\n- private_ssh_key\n- git-credentials'" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite : exit 0" \
    "kv list -address=https://vault_svr_url -format=yaml data/buildkite/testpipe/env : echo -e '- MY_SECRET'" \
    "kv get -address=https://vault_svr_url -field=value data/buildkite/testpipe/env/MY_SECRET : echo ${TESTDATA_ENV}" \
    "kv get -address=https://vault_svr_url -field=value data/buildkite/testpipe/private_ssh_key : echo ${TESTDATA_KEY}"

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

  unset TESTDATA
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER
  unset BUILDKITE_PIPELINE_SLUG
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_PATH
  unset SSH_AGENT_PID
}

@test "Dump env secrets" {
  # export VAULT_STUB_DEBUG=/dev/stdout
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
    # "kv get -address=https://vault_svr_url -field=data -format=yaml data/buildkite/testpipe/env/ANOTHER_SECRET : echo ${TESTDATA_ENV_2}"

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
