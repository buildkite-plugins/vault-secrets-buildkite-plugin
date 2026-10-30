#!/usr/bin/env bats

load "${BATS_PLUGIN_PATH}/load.bash"

# export SSH_AGENT_STUB_DEBUG=/dev/tty
# export SSH_ADD_STUB_DEBUG=/dev/tty
# export VAULT_STUB_DEBUG=/dev/tty
# export CURL_STUB_DEBUG=/dev/tty
# export GIT_STUB_DEBUG=/dev/tty

setup() {
  # if this is not defined, the hook will try to use EC2 metadata to get the instance role
  export BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_AWS_ROLE_NAME='role'
}

@test "approle auth method" {
  export BUILDKITE_PLUGIN_VAULT_SECRETS_PATH=foobar
  export BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER=https://vault_svr_url
  export BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV=false
  export BUILDKITE_PIPELINE_SLUG=testpipe
  export VAULT_SECRET_ID=abcde12345
  export BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_ROLE_ID=buildkite
  export BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_METHOD=approle

  stub vault \
    "write -field=token -address=https://vault_svr_url auth/approle/login role_id=buildkite secret_id=abcde12345 : echo 'Successfully authenticated with Role ID ${6}'"  \
    "kv list -address=https://vault_svr_url -format=yaml foobar/testpipe : exit 0" \
    "kv list -address=https://vault_svr_url -format=yaml foobar : exit 0"

  run bash -c "$PWD/hooks/environment && $PWD/hooks/pre-exit"

  assert_success
  assert_output --partial 'Successfully authenticated with RoleID'

  unstub vault
}

@test "aws auth method with role name" {
  export BUILDKITE_PLUGIN_VAULT_SECRETS_PATH=foobar
  export BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER=https://vault_svr_url
  export BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV=false
  export BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_METHOD=aws
  export BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_AWS_ROLE_NAME="llamas"
  export BUILDKITE_PIPELINE_SLUG=testpipe

  stub vault \
    "login -field=token -address=https://vault_svr_url -method=aws role=\"llamas\" : echo 'Successfully authenticated with IAM Role ${5}'"\
    "kv list -address=https://vault_svr_url -format=yaml foobar/testpipe : exit 0" \
    "kv list -address=https://vault_svr_url -format=yaml foobar : exit 0"

  run bash -c "$PWD/hooks/environment && $PWD/hooks/pre-exit"

  assert_success
  assert_output --partial 'Successfully authenticated with IAM Role'

  unstub vault
}

@test "aws auth using instance IAM role" {
  export BUILDKITE_PLUGIN_VAULT_SECRETS_PATH=foobar
  export BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER=https://vault_svr_url
  export BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV=false
  export BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_METHOD=aws
  export BUILDKITE_PIPELINE_SLUG=testpipe

  # force check
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_AWS_ROLE_NAME

  stub vault \
    "login -field=token -address=https://vault_svr_url -method=aws role=\"llamas\" : echo 'Successfully authenticated with IAM Role ${5}'"\
    "kv list -address=https://vault_svr_url -format=yaml foobar/testpipe : exit 0" \
    "kv list -address=https://vault_svr_url -format=yaml foobar : exit 0"

  stub curl \
    "\* : echo llamas"

  run bash -c "$PWD/hooks/environment && $PWD/hooks/pre-exit"

  assert_success
  assert_output --partial 'Successfully authenticated with IAM Role'

  unstub vault
  unstub curl
}

@test "auth using jwt and default env var" {
  export BUILDKITE_PLUGIN_VAULT_SECRETS_PATH=foobar
  export BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER=https://vault_svr_url
  export BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV=false
  export BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_METHOD=jwt
  export VAULT_JWT=llamas
  export BUILDKITE_PIPELINE_SLUG=testpipe

  stub vault \
    "write -field=token auth/jwt/login role=buildkite jwt=llamas : echo 'Successfully authenticated.'"\
    "kv list -address=https://vault_svr_url -format=yaml foobar/testpipe : exit 0" \
    "kv list -address=https://vault_svr_url -format=yaml foobar : exit 0"

  run bash -c "$PWD/hooks/environment && $PWD/hooks/pre-exit"

  assert_success
  assert_output --partial 'Successfully authenticated with JWT'

  unstub vault
}

@test "auth using jwt with default jwt values" {
  export BUILDKITE_PLUGIN_VAULT_SECRETS_PATH=foobar
  export BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER=https://vault_svr_url
  export BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV=false
  export BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_METHOD=jwt
  export VAULT_JWT=llamas
  export BUILDKITE_PIPELINE_SLUG=testpipe

  stub vault \
    "write -field=token auth/jwt/login role=buildkite jwt=llamas : echo 'Successfully authenticated.'"\
    "kv list -address=https://vault_svr_url -format=yaml foobar/testpipe : exit 0" \
    "kv list -address=https://vault_svr_url -format=yaml foobar : exit 0"

  run bash -c "$PWD/hooks/environment && $PWD/hooks/pre-exit"

  assert_success
  assert_output --partial 'Successfully authenticated with JWT'

  unstub vault
}

@test "auth using jwt and jwt_var option set" {
  export BUILDKITE_PLUGIN_VAULT_SECRETS_PATH=foobar
  export BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER=https://vault_svr_url
  export BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV=false
  export BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_METHOD=jwt
  export BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_JWT_ENV=VERY_COOL
  export VERY_COOL=llamas
  export BUILDKITE_PIPELINE_SLUG=testpipe

  stub vault \
    "write -field=token auth/jwt/login role=buildkite jwt=llamas : echo 'Successfully authenticated.'"\
    "kv list -address=https://vault_svr_url -format=yaml foobar/testpipe : exit 0" \
    "kv list -address=https://vault_svr_url -format=yaml foobar : exit 0"

  run bash -c "$PWD/hooks/environment && $PWD/hooks/pre-exit"

  assert_success
  assert_output --partial 'Successfully authenticated with JWT'

  unstub vault
}

@test "auth using jwt with role and jwt_var set" {
  export BUILDKITE_PLUGIN_VAULT_SECRETS_PATH=foobar
  export BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER=https://vault_svr_url
  export BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV=false
  export BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_METHOD=jwt
  export BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_JWT_ENV=VERY_COOL
  export BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_JWT_ROLE="bkbkbk"
  export VERY_COOL=llamas
  export BUILDKITE_PIPELINE_SLUG=testpipe

  stub vault \
    "write -field=token auth/jwt/login role=bkbkbk jwt=llamas : echo 'Successfully authenticated.'"\
    "kv list -address=https://vault_svr_url -format=yaml foobar/testpipe : exit 0" \
    "kv list -address=https://vault_svr_url -format=yaml foobar : exit 0"

  run bash -c "$PWD/hooks/environment && $PWD/hooks/pre-exit"

  assert_success
  assert_output --partial 'Successfully authenticated with JWT'

  unstub vault
}
setup_approle() {
  export BUILDKITE_PLUGIN_VAULT_SECRETS_PATH=foobar
  export BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER=https://vault_svr_url
  export BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV=false
  export BUILDKITE_PIPELINE_SLUG=testpipe
  export VAULT_SECRET_ID=abcde12345
  export BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_ROLE_ID=buildkite
  export BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_METHOD=approle
}

APPROLE_LOGIN="write -field=token -address=https://vault_svr_url auth/approle/login role_id=buildkite secret_id=abcde12345"
HEALTH_PROBE="--silent --output /dev/null --max-time 5 https://vault_svr_url/v1/sys/health"

@test "approle login fails with exit 1 when server is unreachable and no exit code is configured" {
  setup_approle

  stub vault "${APPROLE_LOGIN} : exit 2"
  stub curl "${HEALTH_PROBE} : exit 7"

  run bash -c "$PWD/hooks/environment"

  assert_failure 1
  assert_output --partial 'is unreachable'
  assert_output --partial 'Failed to get vault token'

  unstub vault
  unstub curl
}

@test "approle login uses unreachable-exit-code when server is unreachable" {
  setup_approle
  export BUILDKITE_PLUGIN_VAULT_SECRETS_UNREACHABLE_EXIT_CODE=75

  stub vault "${APPROLE_LOGIN} : exit 2"
  stub curl "${HEALTH_PROBE} : exit 7"

  run bash -c "$PWD/hooks/environment"

  assert_failure 75
  assert_output --partial 'is unreachable'

  unstub vault
  unstub curl
}

@test "approle login retries while server is unreachable and succeeds once it is reachable" {
  setup_approle
  export BUILDKITE_PLUGIN_VAULT_SECRETS_CONNECTION_RETRIES=2
  export BUILDKITE_PLUGIN_VAULT_SECRETS_CONNECTION_RETRY_DELAY=3

  stub vault \
    "${APPROLE_LOGIN} : exit 2" \
    "${APPROLE_LOGIN} : echo token" \
    "kv list -address=https://vault_svr_url -format=yaml foobar/testpipe : exit 0" \
    "kv list -address=https://vault_svr_url -format=yaml foobar : exit 0"
  stub curl "${HEALTH_PROBE} : exit 28"
  stub sleep "3 : exit 0"

  run bash -c "$PWD/hooks/environment"

  assert_success
  assert_output --partial 'retrying in 3s (1/2)'
  assert_output --partial 'Successfully authenticated with RoleID'

  unstub vault
  unstub curl
  unstub sleep
}

@test "approle login gives up with unreachable-exit-code after exhausting retries" {
  setup_approle
  export BUILDKITE_PLUGIN_VAULT_SECRETS_CONNECTION_RETRIES=1
  export BUILDKITE_PLUGIN_VAULT_SECRETS_UNREACHABLE_EXIT_CODE=75

  stub vault \
    "${APPROLE_LOGIN} : exit 2" \
    "${APPROLE_LOGIN} : exit 2"
  stub curl \
    "${HEALTH_PROBE} : exit 7" \
    "${HEALTH_PROBE} : exit 7"
  stub sleep "5 : exit 0"

  run bash -c "$PWD/hooks/environment"

  assert_failure 75
  assert_output --partial 'retrying in 5s (1/1)'

  unstub vault
  unstub curl
  unstub sleep
}

@test "approle login does not retry or use unreachable-exit-code when server is reachable" {
  setup_approle
  export BUILDKITE_PLUGIN_VAULT_SECRETS_CONNECTION_RETRIES=2
  export BUILDKITE_PLUGIN_VAULT_SECRETS_UNREACHABLE_EXIT_CODE=75

  stub vault "${APPROLE_LOGIN} : exit 2"
  stub curl "${HEALTH_PROBE} : exit 0"

  run bash -c "$PWD/hooks/environment"

  assert_failure 1
  refute_output --partial 'is unreachable'
  assert_output --partial 'Failed to get vault token'

  unstub vault
  unstub curl
}

@test "aws login failure fails the hook" {
  export BUILDKITE_PLUGIN_VAULT_SECRETS_PATH=foobar
  export BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER=https://vault_svr_url
  export BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_METHOD=aws
  export BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_AWS_ROLE_NAME="llamas"

  stub vault "login -field=token -address=https://vault_svr_url -method=aws role=\"llamas\" : exit 2"
  stub curl "${HEALTH_PROBE} : exit 0"

  run bash -c "$PWD/hooks/environment"

  assert_failure 1
  assert_output --partial 'Failed to get vault token'
  refute_output --partial 'Successfully authenticated'

  unstub vault
  unstub curl
}
