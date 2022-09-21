#!/bin/bash
set -ueo pipefail

BASE64_DECODE_ARGS="-d"

case "$(uname -s)" in
  Darwin) BASE64_DECODE_ARGS="--decode" ;;
esac

[ -z "${TMPDIR:-}" ] && TMPDIR=${TMPDIR:-/tmp}

vault_auth() {
  local server="$1"

  # Currently we only support AppRole authentication.
  # These values are referenced when authenticating to the Vault server:
  #   BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_METHOD - approle

  #   RoleID and SecretID should be stored securely on the agent, there are probably better ways to do this, but here is a start
  #   We'll use these two values for the RoleID and SecretID:
  #     BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_SECRET_ID
  #     BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_ROLE_ID
  #
  #   For now, you will need to define the secret ID oustide of the plugin, though this will probably change.

   # approle authentication
  if [ "${BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_METHOD:-}" = "approle" ]; then
    
    secret_var="${BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_SECRET_ENV:-$VAULT_SECRET_ID}"

    if [[ -z "${!secret_var:-}" ]]; then
      echo "+++  🚨 No vault secret id found in \$${secret_var}"
      exit 1
    fi
    
    # export the vault token to be used for this job - this command writes to the auth/approle/login endpoint
    # on success, vault will return the token which we export as VAULT_TOKEN for this shell
    export VAULT_TOKEN
    if ! VAULT_TOKEN=$(vault write -field=token -address="$server" auth/approle/login \
     role_id="$BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_ROLE_ID" \
     secret_id="${!secret_var:-}"); then
      echo "Failed to get vault token"
    fi

    echo "Successfully authenticated with RoleID ${BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_ROLE_ID} and updated vault token"

    return "${PIPESTATUS[0]}"
  fi
}

list_secrets() {
  local server="$1"
  local key="$2"

  local _list

  if ! _list=$(vault kv list -address="$server" -format=yaml "$key" | sed 's/^- //g'); then
    echo "unable to list secrets" >&2;
    return "${PIPESTATUS[0]}"
  fi
  local retVal=${PIPESTATUS[0]}

  for lineItem in ${_list} ; do
    echo "$key/${lineItem}"
  done

  return "$retVal"
}

secret_exists() {
  local server="$1"
  local key="$2"

  local _key_base
  _key_base="$(dirname "$key")"
  local _key_name
  _key_name="$(basename "$key")"
  local _list
  _list=$(vault kv list -address="$server" -format=yaml "$_key_base" )

  echo "${_list}" | grep "^- ${_key_name}$" >& /dev/null
  # shellcheck disable=SC2181
  if [ "$?" -ne 0 ] ; then
    return 1
  else
    return 0
  fi
}

secret_download() {
  local server="$1"
  local key="$2"
  if ! _secret=$(vault kv get -field=data -format=yaml secret/buildkite/env | sed 's/: /=/g' ); then
    echo "Failed to download secrets"
    exit 1
  fi
  # shellcheck disable=SC2181
  if [ "$?" -ne 0 ] ; then
    return 1
  fi
  echo "$_secret"
}

add_ssh_private_key_to_agent() {
  local ssh_key="$1"

  if [[ -z "${SSH_AGENT_PID:-}" ]] ; then
    echo "Starting an ephemeral ssh-agent" >&2;
    eval "$(ssh-agent -s)"
  fi

  echo "Loading ssh-key into ssh-agent (pid ${SSH_AGENT_PID:-})" >&2;

  echo "$ssh_key" | env SSH_ASKPASS="/bin/false" ssh-add -
}

grep_secrets() {
  grep -E 'private_ssh_key|id_rsa_github|env|environment|git-credentials$' "$@"
}
