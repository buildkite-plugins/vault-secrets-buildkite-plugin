#!/bin/bash
set -eu

# If you build HEAD the pipeline.sh step, because it runs first, won't yet
# have the updated commit SHA. So we have to figure it out ourselves.
if [[ "${BUILDKITE_COMMIT:-HEAD}" == "HEAD" ]]; then
  commit=$(git show HEAD -s --pretty='%h')
else
  commit="${BUILDKITE_COMMIT}"
fi

# We have to use cat because pipeline.yml $ interpolation doesn't work in YAML
# keys, only values

cat <<YAML
env:
  BK_QUEUE_NAME: "testqueue"
  TESTER_VAULT_VERSION: "0.10.0"
  SVC_VAULT_VERSION: "0.10.0"
  VAULT_ADDR: "http://vault-svc:8200"
  BUILDKITE_PIPELINE_SLUG: "my_pipeline"
  DUMP_ENV: "true"
  VAULT_DEV_ROOT_TOKEN_ID: "88F4384B-98E9-4AE3-B00C-F55678F89080"
steps:
  - label: ":bash: :hammer:"
    agents:
      queue: ${BUILDKITE_AGENT_META_DATA_QUEUE?}
    plugins:
      docker-compose#v1.8.2:
        run: tests

  - label: ":hammer: env variable test"
    command: /app/.buildkite/steps/test_envvar.sh
    agents:
      queue: ${BUILDKITE_AGENT_META_DATA_QUEUE?}
    plugins:
      docker-compose#v1.8.2:
        config:
        - docker-compose-integration.yml
        run: vault-tester
        env:
        - VAULT_ADDR=\${VAULT_ADDR}
        - BUILDKITE_PLUGIN_VAULT_SECRETS_SERVER=\${VAULT_ADDR}
        - BUILDKITE_PIPELINE_SLUG=\${BUILDKITE_PIPELINE_SLUG}
        - BUILDKITE_PLUGIN_VAULT_SECRETS_DUMP_ENV=\${DUMP_ENV}
        - VAULT_DEV_ROOT_TOKEN_ID=\${VAULT_DEV_ROOT_TOKEN_ID}
        - BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_TOKEN=\${VAULT_DEV_ROOT_TOKEN_ID}
        - SVC_VAULT_VERSION=\${SVC_VAULT_VERSION}
        - TESTER_VAULT_VERSION=\${TESTER_VAULT_VERSION}
      # Cannot run the plugin on the agent yet, as the agent does not have Vault installed
      # ssh://git@github.com/PromisePay/vault-secrets-buildkite-plugin.git#${commit}:
        # server: http://vault:8200
        # env: true
        # auth_token: "88F4384B-98E9-4AE3-B00C-F55678F89080"
YAML
