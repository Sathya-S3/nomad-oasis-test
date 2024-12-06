#!/bin/sh

# Script to replace placeholders in 'configs/nomad-realm.json' with environment variables

set -e

echo
echo "${0} is starting..."

# Load environment variables from .env file
set -a
. ./secrets.env
set +a

# Check if jq is installed
# if ! command -v /usr/bin/jq &> /dev/null
# then
#     echo "ERROR: The command 'jq' required by this script could not be found. 'jq' might"
#     echo "       not be installed on your system. See https://jqlang.github.io/jq for details"
#     echo "       regarding how to install 'jq'."
#     exit 1
# fi

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
/usr/bin/jq ".identityProviders[0].config.clientId = \"$orcid_clientId\" | .identityProviders[0].config.clientSecret = \"$orcid_clientSecret\" " configs/nomad-realm.json > configs/nomad-realm.json.tmp && mv configs/nomad-realm.json.tmp configs/nomad-realm.json

# Verify that the secrets were correctly inserted
if jq -e ".identityProviders[0].config.clientId == \"$orcid_clientId\" and .identityProviders[0].config.clientSecret == \"$orcid_clientSecret\"" configs/nomad-realm.json > /dev/null; then
    echo "INFO: Secrets successfully inserted into 'configs/nomad-realm.json'."
else
    echo "ERROR: Failed to insert secrets into 'configs/nomad-realm.json'."
    exit 1
fi

echo
echo "INFO: Proceeding to change admin passwords in 'docker-compose.yaml' and 'configs/nomad.yaml'."

# Note that there are rigid assumptions about the format of the two yaml files here (e.g. whitespace between key and value)!
sed -i "s/password: \${KEYCLOAK_PASSWORD}/password: '$adminpassword'/" configs/nomad.yaml
sed -i "s/KEYCLOAK_PASSWORD=\${KEYCLOAK_PASSWORD}/KEYCLOAK_PASSWORD=$adminpassword/" docker-compose.yaml
sed -i "s/CLIENT_ID=\${CLIENT_ID}/CLIENT_ID=$orcid_clientId/" docker-compose.yaml
sed -i "s/CLIENT_SECRET=\${CLIENT_SECRET}/CLIENT_SECRET=$orcid_clientSecret/" docker-compose.yaml

# Replace CLIENT_ID and CLIENT_SECRET in the app service section
sed -i "s/CLIENT_ID: \${CLIENT_ID}/CLIENT_ID: $orcid_clientId/" docker-compose.yaml
sed -i "s/CLIENT_SECRET: \${CLIENT_SECRET}/CLIENT_SECRET: $orcid_clientSecret/" docker-compose.yaml

echo
echo "${0} has completed its job"

# Execute the original command
exec "$@"