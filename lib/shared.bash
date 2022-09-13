#!/bin/bash
set -ueo pipefail

BASE64_DECODE_ARGS="-d"

case "$(uname -s)" in
  Darwin) BASE64_DECODE_ARGS="--decode" ;;
esac

[ -z "${TMPDIR:-}" ] && TMPDIR=${TMPDIR:-/tmp}

vault_auth() {
  local server="$1"
  local auth_params=''

  # Currently we only support AppRole authentication.
  # These values are referenced when authenticating to the Vault server:
  #   BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_METHOD - approle

  #   RoleID and SecretID should be stored securely on the agent, there are probably better ways to do this, but here is a start.

  #   BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_SECRET_ID
  #   BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_ROLE_ID

  [ -n "${server:-}" ] && auth_params="${auth_params} -address=${server}"
  [ -n "${BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_METHOD:-}" ] && auth_params="${auth_params} -method=${BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_METHOD}"

  if [ "${BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_METHOD}" = "approle" ]; then
    echo "$BUILDKITE_PLUGIN_VAULT_SECRETS_ROLE_ID"
    echo "$BUILDKITE_PLUGIN_VAULT_SECRETS_SECRET_ID"

    [ -n "${BUILDKITE_PLUGIN_VAULT_SECRETS_ROLE_ID:-}" ] && auth_params="${auth_params} role_id=${BUILDKITE_PLUGIN_VAULT_SECRETS_ROLE_ID}"
    [ -n "${BUILDKITE_PLUGIN_VAULT_SECRETS_SECRET_ID:-}" ] && auth_params="${auth_params} secret_id=${BUILDKITE_PLUGIN_VAULT_SECRETS_SECRET_ID}"

    vault write -field=token auth/approle/login "$auth_params" \
     role_id="$BUILDKITE_PLUGIN_VAULT_SECRETS_ROLE_ID" \
     secrets_id= "$BUILDKITE_PLUGIN_VAULT_SECRETS_SECRET_ID"
    return "${PIPESTATUS[0]}"
  fi

}

## This is the old auth method for reference
# vault_auth() {
#   local server="$1"
#   local auth_params=''
#   # role is defined in Vault Configuration
#   # -header=<foo> # used to set X-Auth
#   # BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_METHOD - aws
#   # BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_HEADER
#   # BUILDKITE_PLUGIN_VAULT_SECRETS_ROLE
#   [ -n "${server:-}" ] && auth_params="${auth_params} -address=${server}"
#   [ -n "${BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_METHOD:-}" ] && auth_params="${auth_params} -method=${BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_METHOD}"
#   [ -n "${BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_HEADER:-}" ] && auth_params="${auth_params} -header_value=${BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_HEADER}"
#   [ -n "${BUILDKITE_PLUGIN_VAULT_SECRETS_ROLE:-}" ] && auth_params="${auth_params} role=${BUILDKITE_PLUGIN_VAULT_SECRETS_ROLE}"

#   if [ -n "${BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_METHOD:-}" ] ; then
#     # don't output the token to log, even though it's a temporary token
#     # shellcheck disable=SC2086
#     vault auth $auth_params | grep -v ^token:
#     return "${PIPESTATUS[0]}"
#   else
#     # shellcheck disable=SC2086
#     echo "${BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_TOKEN:-}" | vault auth ${auth_params:-} -
#   fi
# }

list_secrets() {
  local server="$1"
  local key="$2"

  local _list
  _list=$(vault list -address="$server" -format=yaml "$key" | sed 's/^- //g' )
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
  _list=$(vault list -address="$server" -format=yaml "$_key_base" )

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

  _secret=$(vault read -address="${server}" -field=value "$key" | base64 $BASE64_DECODE_ARGS)
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
