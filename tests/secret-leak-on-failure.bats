#!/usr/bin/env bats

# These tests guard against secret material being echoed to the build log when a
# `vault kv get` call fails. Vault writes the secret to *stdout*; if that stdout
# is captured (e.g. via `2>&1`) and then printed as part of an error message, the
# secret leaks. This happens in practice when a request fails mid-transfer
# (EOF / connection reset / 5xx) after Vault has already streamed secret bytes.

setup() {
  load "${BATS_PLUGIN_PATH}/load.bash"

  # Source the library under test so we can call secret_download directly.
  source "${PWD}/lib/shared.bash"

  export BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER=https://vault_svr_url
}

# export VAULT_STUB_DEBUG=/dev/tty

@test "yaml output: secret is not leaked when vault fails mid-transfer" {
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_OUTPUT  # defaults to yaml

  # vault streams the secret to stdout, then drops the connection (EOF) and exits non-zero.
  stub vault \
    "kv get -address=https://vault_svr_url -field=data -format=yaml secret/leaky : echo 'MY_SECRET: hunter2-leaked-value'; echo 'Error making API request. Code: 500. Errors: EOF' >&2; exit 1"

  run secret_download "https://vault_svr_url" "secret/leaky"

  assert_failure
  # We still want a useful, non-secret error message...
  assert_output --partial "Failed to download secret from secret/leaky"
  # ...but the secret value must never appear in the output.
  refute_output --partial "hunter2-leaked-value"

  unstub vault
}

@test "json output: secret is not leaked when vault fails mid-transfer" {
  export BUILDKITE_PLUGIN_VAULT_SECRETS_OUTPUT=json

  stub vault \
    "kv get -address=https://vault_svr_url -field=data -format=json secret/leaky : echo '{\"MY_SECRET\":\"hunter2-leaked-value\"}'; echo 'Error making API request. Code: 500. Errors: EOF' >&2; exit 1"

  run secret_download "https://vault_svr_url" "secret/leaky"

  assert_failure
  assert_output --partial "Failed to download secret from secret/leaky"
  refute_output --partial "hunter2-leaked-value"

  unstub vault
}

@test "yaml output: secret is not leaked when the JSON re-fetch fails mid-transfer" {
  unset BUILDKITE_PLUGIN_VAULT_SECRETS_OUTPUT  # defaults to yaml

  # When the (sed-processed) YAML output starts with '{', secret_download re-fetches
  # the secret as JSON. That second call must be hardened just like the first: if it
  # streams secret bytes and then fails, none of it may reach the build log.
  stub vault \
    "kv get -address=https://vault_svr_url -field=data -format=yaml secret/jsonish : echo '{\"foo\": \"bar\"}'" \
    "kv get -address=https://vault_svr_url -field=data -format=json secret/jsonish : echo 'refetch-leaked-value'; echo 'Error making API request. Code: 500. Errors: EOF' >&2; exit 1"

  run secret_download "https://vault_svr_url" "secret/jsonish"

  assert_failure
  assert_output --partial "Failed to download secret from secret/jsonish"
  refute_output --partial "refetch-leaked-value"

  unstub vault
}

@test "json output: secret is not leaked when JSON parsing fails" {
  export BUILDKITE_PLUGIN_VAULT_SECRETS_OUTPUT=json

  # Download succeeds but returns content jq cannot parse. jq's diagnostics can echo
  # fragments of its input (the secret), so the parse-error path must not surface
  # either the captured output or jq's stderr.
  stub vault \
    "kv get -address=https://vault_svr_url -field=data -format=json secret/badjson : echo 'not-valid-json-leaked-value'"

  run secret_download "https://vault_svr_url" "secret/badjson"

  assert_failure
  assert_output --partial "Failed to parse JSON secret from secret/badjson"
  refute_output --partial "not-valid-json-leaked-value"

  unstub vault
}
