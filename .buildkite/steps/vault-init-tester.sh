#!/bin/bash

# This token is defined in docker-compose.yml and is for testing ONLY!!!!!!
AUTH_TOKEN="${BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_TOKEN:-}"
PROJECT=${BUILDKITE_PIPELINE_SLUG:-foobar_project}
export VAULT_ADDR="http://vault-svc:8200"


if [ ! "$(vault login token="$AUTH_TOKEN")" ]; then
   echo "Vault login failed"
   exit 1
fi

if [ ! "$(vault secrets enable -path=data/buildkite kv)" ];then
   echo "Failed to enable secrets engine"
   exit 1
fi

# [ $? -eq 0 ] && vault secrets enable -path=data/buildkite kv

TESTDATA_1="foobar1"
TESTDATA_2="foobar2"

# [ $? -ne 1 ] && {
   vault kv put data/buildkite/env TESTDATA_1="${TESTDATA_1}"
   vault kv put data/buildkite/"${PROJECT}"/env TESTDATA_2="${TESTDATA_2}"
# }