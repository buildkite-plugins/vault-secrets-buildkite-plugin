#!/bin/bash

set -eu

configEnv() {
  basedir="$( cd "$( dirname "$0" )" && cd ../.. && pwd )"
}

setupTestData() {
  . "${basedir}/.buildkite/steps/vault-init-tester.sh"
}

runTest() {
  export VAULT_TOKEN="${VAULT_DEV_ROOT_TOKEN_ID:-}"
  export BUILDKITE_PIPELINE_SLUG="${BUILDKITE_PIPELINE_SLUG:-}"
  export BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER="${BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER:-}"

  . "${basedir}"/hooks/environment


  if [ "${TESTDATA_1:-}" == "foobar1" ] ; then
    echo "TESTDATA_1 is correct"
  else
    echo "TESTDATA_1 is not set and/or correct"
    exit 1
  fi

  if [ "${TESTDATA_2:-}" == "foobar2" ] ; then
    echo "TESTDATA_2 is correct"
  else
    echo "TESTDATA_2 is not set and/or correct"
    exit 1
  fi
}

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
