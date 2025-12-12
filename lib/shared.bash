#!/bin/bash
set -ueo pipefail

[ -z "${TMPDIR:-}" ] && TMPDIR=${TMPDIR:-/tmp}

vault_auth() {
  local server="$1"

  # The plugin currently supports AppRole and AWS authentication
  # These values are referenced when authenticating to the Vault server:
  #   BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_METHOD - 'approle' or 'aws'

  ##  AppRole Authentication
  #   SecretID should be stored securely on the agent when using AppRole authentication.
  #   The plugin will reference these two values for the RoleID and SecretID:
  #     BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_SECRET_ENV (default: $VAULT_SECRET_ID)
  #     BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_ROLE_ID

  ##  AWS Authentication
  #   AWS auth method only requires you to pass the name of a valid Vault role in your login call, which is not
  #   sensitive information itself, so the role name to use can either be passed via BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_AWS_ROLE_NAME
  #   or will fall back to using the name of the IAM role that the instance is using.


  case "${BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_METHOD:-}" in

    # AppRole authentication
    approle)
        if [ -z "${BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_SECRET_ENV:-}" ]; then
          secret_var="${VAULT_SECRET_ID?No Secret ID found}"
        else
          secret_var="${!BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_SECRET_ENV}"
        fi

        if [[ -z "${secret_var:-}" ]]; then
          echo "+++  🚨 No vault secret id found"
          exit 1
        fi

        # export the vault token to be used for this job - this command writes to the auth/approle/login endpoint
        # on success, vault will return the token which we export as VAULT_TOKEN for this shell
        if ! VAULT_TOKEN=$(vault write -field=token -address="$server" auth/approle/login \
        role_id="$BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_ROLE_ID" \
        secret_id="${secret_var:-}"); then
          echo "+++🚨 Failed to get vault token"
          exit 1
        fi

        export VAULT_TOKEN

        echo "Successfully authenticated with RoleID ${BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_ROLE_ID} and updated vault token"

        return "${PIPESTATUS[0]}"
      ;;

    # AWS Authentication
    aws)
        # set the role name to use; either from the plugin configuration, or fall back to the EC2 instance role
        if [ -z "${BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_AWS_ROLE_NAME:-}" ]; then
          # get the name of the IAM role the EC2 instance is using, if any
          EC2_INSTANCE_IAM_ROLE=$(curl http://169.254.169.254/latest/meta-data/iam/security-credentials)
          aws_role_name="${EC2_INSTANCE_IAM_ROLE}"
        else
          aws_role_name="${BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_AWS_ROLE_NAME}"
        fi

        if [[ -z "${aws_role_name:-}" ]]; then
          echo "+++🚨 No EC2 instance IAM role defined; value is $aws_role_name"
          exit 1
        fi

        # export the vault token to be used for this job - this is a standard vault auth command
        # on success, vault will return the token which we export as VAULT_TOKEN for this shell
        if ! VAULT_TOKEN=$(vault login -field=token -address="$server" -method=aws role="$aws_role_name"); then
          echo "+++🚨 Failed to get vault token"
        fi

        export VAULT_TOKEN

        echo "Successfully authenticated with IAM Role ${aws_role_name} and updated vault token"

        return "${PIPESTATUS[0]}"
      ;;

    jwt)
        echo "--- performing JWT authentication"
        if [ -z "${BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_JWT_ENV:-}" ]; then
          jwt_var="${VAULT_JWT?No JWT found}"
        else
          jwt_var="${!BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_JWT_ENV}"
        fi

        if [[ -z "${jwt_var:-}" ]]; then
          echo "+++  🚨 No JWT found."
          exit 1
        fi

        if ! VAULT_TOKEN=$(vault write -field=token auth/jwt/login role="${BUILDKITE_PLUGIN_VAULT_SECRETS_AUTH_JWT_ROLE:-"buildkite"}" jwt="${jwt_var:-}"); then
          echo "+++🚨 Failed to get vault token"
          exit 1
        fi

        export VAULT_TOKEN

        echo "Successfully authenticated with JWT"

        return "${PIPESTATUS[0]}"
    ;;
  esac
}

list_secrets() {
  local server="$1"
  local key="$2"

  local _list

  if ! _list=$(vault kv list -address="$server" -format=yaml "$key" 2>&1 | sed 's/^- //g'); then
    echo "unable to list secrets at $key: $_list" >&2
    return 1
  fi
  local retVal=${PIPESTATUS[0]}

  for lineItem in ${_list}; do
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
  _list=$(vault kv list -address="$server" -format=yaml "$_key_base")

  echo "${_list}" | grep "^- ${_key_name}$" >&/dev/null
  # shellcheck disable=SC2181
  if [ "$?" -ne 0 ]; then
    return 1
  else
    return 0
  fi
}

process_json_to_shell_vars() {
  local json_input="$1"

  # Process JSON secret to replace non-alphanumeric characters in keys with underscores,
  # flatten nested structures by joining paths with underscores, and format as shell variables
  jq -c '
      walk(
          if type == "object" then
              with_entries(.key |= gsub("[^A-Za-z0-9_]"; "_"))
          else
              .
          end
      )
  ' <<< "$json_input" | jq -r '
      [paths(scalars) as $p |
          {key: $p | join("_"), value: getpath($p)}
      ] | .[] | "\(.key)=\(.value | @sh)"
  ' 2>&1
}

secret_download() {
  local server="$1"
  local key="$2"
  # should default to YAML, but allows the option for getting JSON output.
  local output="${BUILDKITE_PLUGIN_VAULT_SECRETS_OUTPUT:-"yaml"}"

  # Attempt to retrieve the secret from Vault with detailed error capture
  local vault_error

  if [[ "${output}" == "json" ]]; then
    # JSON output - no sed transformation needed
    if ! _secret=$(vault kv get -address="$server" -field=data -format=json "$key" 2>&1); then
      vault_error=$_secret
      echo "Failed to download secret from $key" >&2
      echo "Vault error: $vault_error" >&2

      if [[ "$vault_error" =~ "EOF" ]]; then
        echo "EOF error often indicates network connectivity issues or server problems" >&2
      elif [[ "$vault_error" =~ "permission denied" ]]; then
        echo "Permission denied - check if the token has access to this secret path" >&2
      elif [[ "$vault_error" =~ "path not found" ]]; then
        echo "Secret path not found - verify the path exists in Vault" >&2
      fi
      exit 1
    fi

    # Process the JSON secret to replace underscores and periods in keys
    if ! _secret=$(process_json_to_shell_vars "$_secret"); then
      echo "Failed to parse JSON secret from $key" >&2
      echo "JSON parse error: $_secret" >&2
      exit 1
    fi
  else
    # YAML output - apply sed transformation
    if ! _secret=$(vault kv get -address="$server" -field=data -format=yaml "$key" 2>&1 | \
      sed -r '
          s/: /=/;       # Replace ':' with '='
          s/\"/\\"/g;    # Escape double quotes
          s/\$/\\$/g;    # Escape dollar signs
          s/=(.*)$/="\1"/g; # Enclose values in double quotes
      '); then

      # Capture the vault command error for better debugging
      vault_error=$(vault kv get -address="$server" -field=data -format=yaml "$key" 2>&1)
      echo "Failed to download secret from $key" >&2
      echo "Vault error: $vault_error" >&2

      # Additional context for common errors
      if [[ "$vault_error" =~ "EOF" ]]; then
        echo "EOF error often indicates network connectivity issues or server problems" >&2
      elif [[ "$vault_error" =~ "permission denied" ]]; then
        echo "Permission denied - check if the token has access to this secret path" >&2
      elif [[ "$vault_error" =~ "path not found" ]]; then
        echo "Secret path not found - verify the path exists in Vault" >&2
      fi

      exit 1
    fi

    # Check if the first character of the _secret variable is a '{'
    if [[ "${_secret:0:1}" == "{" ]]; then
      # The YAML output contains JSON, handle accordingly

      # Retrieve the secret from Vault as JSON format instead
      _secret=$(vault kv get -address="$server" -field=data -format=json "$key")

      # Process the JSON secret to replace underscores and periods in keys
      if ! _secret=$(process_json_to_shell_vars "$_secret"); then
        echo "Failed to parse JSON secret from $key" >&2
        echo "JSON parse error: $_secret" >&2
        exit 1
      fi
    fi
  fi

  echo "$_secret"
}

ssh_key_download() {
  local server="$1"
  local key="$2"

  # SSH Keys must be stored as a single key inside a Vault secret named "ssh_key"
  if ! _secret="$(vault kv get -address="${server}" -field=ssh_key "${key}")"; then
    echo "Failed to download secrets"
    exit 1
  fi
  echo "$_secret"
}

add_ssh_private_key_to_agent() {
  local ssh_key="$1"

  if [[ -z "${SSH_AGENT_PID:-}" ]]; then
    echo "Starting an ephemeral ssh-agent" >&2
    eval "$(ssh-agent -s)"
    export EPHEMERAL_SSH_AGENT_PID="${SSH_AGENT_PID}"
  fi

  echo "Loading ssh-key into ssh-agent (pid ${SSH_AGENT_PID:-})" >&2

  echo "$ssh_key" | env SSH_ASKPASS="/bin/false" ssh-add -
}

grep_secrets() {
  grep -E 'private_ssh_key|id_rsa_github|env|environment|git-credentials$' "$@"
}
