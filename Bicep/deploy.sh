#!/usr/bin/env bash

envFilePath=".env"
if [[ -f "$envFilePath" ]]; then
    while IFS= read -r line; do
        # Match lines of the form KEY=VALUE, ignoring commented (#) lines
        if [[ $line =~ ^\s*([^#][^=]+)=(.)\s$ ]]; then
            name="${BASH_REMATCH[1]}"
            value="${BASH_REMATCH[2]}"
            export "${name}=${value}"
            echo "env variable: $name=$value"
        fi
    done < "$envFilePath"
fi

tenantId="${TENANT_ID}"
subscriptionId="${SUBSCRIPTION_ID}"
resourceGroup="${RESOURCE_GROUP}"
location="${LOCATION}"
containerGroupName="${CONTAINER_GROUP_NAME}"
storageAccountName="${STORAGE_ACCOUNT_NAME}"

# Azure CLI commands
az config set core.login_experience_v2=off
az login --tenant "$tenantId"

az account set --subscription "$subscriptionId"
az group create --name "$resourceGroup" --location "$location"
az deployment group create --name caddy-hello-world --resource-group "$resourceGroup" --template-file main.bicep --parameters containerGroupName="$containerGroupName" storageAccountName="$storageAccountName"