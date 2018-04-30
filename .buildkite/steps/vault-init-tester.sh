#!/bin/bash

# This token is defined in docker-compoise.yml and is for testing ONLY!!!!!!
AUTH_TOKEN="${BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_TOKEN:-}"
PROJECT=${BUILDKITE_PIPELINE_SLUG:-foobar_project}
vault auth - <<< "$AUTH_TOKEN"

[ $? -eq 0 ] && vault mount -path data/buildkite kv

TESTDATA_1=`echo TESTDATA_1=\"foo bar 1\" | base64`
TESTDATA_2=`echo TESTDATA_2=\"foo bar 2\" | base64`

[ $? -ne 1 ] && {
   echo "${TESTDATA_1}" | vault write data/buildkite/env/TESTDATA_1 value=-
   echo "${TESTDATA_2}" | vault write data/buildkite/${PROJECT}/env/TESTDATA_2 value=-
}
