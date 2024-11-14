#!/bin/sh

# Script to replace placeholders in 'configs/nomad-realm.json' with environment variables

set -e

echo
echo "${0} is starting..."

# Check if jq is installed
if ! command -v jq &> /dev/null
then
    echo
    echo "ERROR: The command 'jq' required by this script could not be found. 'jq' might"
    echo "       not be installed on your system. See https://jqlang.github.io/jq for details"
    echo "       regarding how to install 'jq'."
    exit 1
fi

# Read environment variables
orcid_clientId=${CLIENT_ID}
orcid_clientSecret=${CLIENT_SECRET}
adminpassword=${KEYCLOAK_PASSWORD}

# Check if environment variables are set
if [ -z "$orcid_clientId" ] || [ -z "$orcid_clientSecret" ] || [ -z "$adminpassword" ]; then
    echo
    echo "ERROR: One or more required environment variables are not set."
    echo "       Please ensure that ORCID CLIENT_ID, ORCID CLIENT_SECRET, and KEYCLOAK_PASSWORD are set."
    exit 1
fi

echo
echo "INFO: Proceeding to insert client ID and client secret into 'configs/nomad-realm.json' file."

# Replace placeholders with environment variables
jq ".identityProviders[0].config.clientId = \"$orcid_clientId\" | .identityProviders[0].config.clientSecret = \"$orcid_clientSecret\" " configs/nomad-realm.json > configs/nomad-realm.json.tmp && mv configs/nomad-realm.json.tmp configs/nomad-realm.json

echo
echo "INFO: Proceeding to change admin passwords in 'docker-compose.yaml' and 'configs/nomad.yaml'."

# Note that there are rigid assumptions about the format of the two yaml files here (e.g. whitespace between key and value)!
sed -i "s/password: 'password'/password: '$adminpassword'/" /app/configs/nomad.yaml
sed -i "s/KEYCLOAK_PASSWORD=password/KEYCLOAK_PASSWORD=$adminpassword/" /app/docker-compose.yaml

echo
echo "${0} has completed its job"

# Execute the original command
exec "$@"