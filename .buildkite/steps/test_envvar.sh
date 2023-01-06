#!/bin/bash

set -eu

configEnv() {
  _source="$0"
  [ -z "${_source:-}" ] && _source="${0}"
  basedir="$( cd "$( dirname "${_source}" )" && cd ../.. && pwd )"
}

setupTestData() {
  export VAULT_TOKEN="${VAULT_DEV_ROOT_TOKEN_ID:-}"
  sh "${basedir}/.buildkite/steps/vault-init-tester.sh"
}

runTest() {
  export VAULT_TOKEN="${VAULT_DEV_ROOT_TOKEN_ID:-}"
  export BUILDKITE_PIPELINE_SLUG="${BUILDKITE_PIPELINE_SLUG:-}"
  export BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER="${BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER:-}"

  . "${basedir}"/hooks/environment


  if [[ -n "${TESTDATA_1:-}" ]] && [[ "${TESTDATA_1}" == "foobar1" ]] ; then
    echo "TESTDATA_1 is correct"
  else
    echo "TESTDATA_1 is not set and/or correct"
    exit 1
  fi

  if [[ ! -z "${TESTDATA_2:-}" ]] && [[ "${TESTDATA_2}" == "foobar2" ]] ; then
    echo "TESTDATA_2 is correct"
  else
    echo "TESTDATA_2 is not set and/or correct"
    exit 1
  fi
}

# cmd="$0"
configEnv
if [ -d /app ]; then
  echo "--- setup test data"
  setupTestData
  echo "--- run test"
  runTest
else
  echo "--- not in test container"
  exit 99
fi
