#!/usr/bin/env bash

set -x

source /usr/local/bootstrap/var.env

echo 'Start Vault MongoDB Dynamic Credentials Config'

IP=${LEADER_IP}
DB=${MONGO_IP}
if [ "${TRAVIS}" == "true" ]; then
    IP="127.0.0.1"
    DB=${IP}
fi

if [ -d /vagrant ]; then
  LOG="/vagrant/logs/vault_audit_${HOSTNAME}.log"
else
  LOG="vault_audit.log"
fi

# enable database secret engine
VAULT_TOKEN=`cat /usr/local/bootstrap/.vault-token`
VAULT_ADDR="http://${IP}:8200"

enable_dynamic_credentials_via_vault_client () {
    
    echo 'Start Vault MongoDB Dynamic Credentials Config using Vault Client'

    # enable vault secret database backend with vault client
    sudo VAULT_TOKEN=${VAULT_TOKEN} VAULT_ADDR="http://${IP}:8200" vault secrets enable database

    # configure vault mongodb plugin with 2 user roles
    sudo VAULT_TOKEN=${VAULT_TOKEN} VAULT_ADDR="http://${IP}:8200" vault write database/config/my-mongodb-database \
        plugin_name=mongodb-database-plugin \
        allowed_roles="my-read-role, my-readwrite-role" \
        connection_url="mongodb://{{username}}:{{password}}@${DB}:27017/vault_demo_db?ssl=false" \
        username="vault_admin" \
        password="r3ally5tr0ngPa55w0rd"

    # configure vault mnongodb user role my-write-role
    sudo VAULT_TOKEN=${VAULT_TOKEN} VAULT_ADDR="http://${IP}:8200" vault write database/roles/my-readwrite-role \
        db_name=my-mongodb-database \
        creation_statements='{ "db": "vault_demo_db", "roles": [{ "role": "readWrite" }] }' \
        default_ttl="1h" \
        max_ttl="24h"

    # configure vault mnongodb user role my-read-role    
    sudo VAULT_TOKEN=${VAULT_TOKEN} VAULT_ADDR="http://${IP}:8200" vault write database/roles/my-read-role \
        db_name=my-mongodb-database \
        creation_statements='{ "db": "vault_demo_db", "roles": [{ "role": "read" }] }' \
        default_ttl="1h" \
        max_ttl="24h"

    echo 'Finished Vault MongoDB Dynamic Credentials Config using Vault Client'

}

enable_dynamic_credentials_via_vault_api () {
    
    echo 'Start Vault MongoDB Dynamic Credentials Config using API calls'

    # enable vault secret database backend with vault client
    tee database-backend-file.json <<EOF
    {
    "type": "database",
    "config": {
        "force_no_cache": true
    }
    }
EOF

    curl \
    --header "X-Vault-Token: ${VAULT_TOKEN}" \
    --request POST \
    --data @database-backend-file.json \
    ${VAULT_ADDR}/v1/sys/mounts/database

    # configure vault mongodb plugin with 2 user roles
    tee database-config-file.json <<EOF
    {
    "plugin_name": "mongodb-database-plugin",
    "allowed_roles": "my-read-role, my-readwrite-role",
    "connection_url": "mongodb://{{username}}:{{password}}@${DB}:27017/vault_demo_db?ssl=false",
    "write_concern": "{ \"wmode\": \"majority\", \"wtimeout\": 5000 }",
    "username": "vault_admin",
    "password": "r3ally5tr0ngPa55w0rd"
    }
EOF

    curl \
    --header "X-Vault-Token: ${VAULT_TOKEN}" \
    --request POST \
    --data @database-config-file.json \
    ${VAULT_ADDR}/v1/database/config/my-mongodb-database

    # configure vault mongodb user role my-read-role
    tee database-role-a-file.json <<EOF
    {
        "db_name": "my-mongodb-database",
        "creation_statements": "{ \"db\": \"vault_demo_db\", \"roles\": [{ \"role\": \"read\" }] }",
        "default_ttl": "1h",
        "max_ttl": "24h"
    }
EOF

    curl \
    --header "X-Vault-Token: ${VAULT_TOKEN}" \
    --request POST \
    --data @database-role-a-file.json \
    ${VAULT_ADDR}/v1/database/roles/my-read-role

    # configure vault mnongodb user role my-readWrite-role    
    tee database-role-b-file.json <<EOF
    {
        "db_name": "my-mongodb-database",
        "creation_statements":  "{ \"db\": \"vault_demo_db\", \"roles\": [{ \"role\": \"readWrite\" }] }",
        "default_ttl": "1h",
        "max_ttl": "24h"
    }
EOF

    curl \
    --header "X-Vault-Token: ${VAULT_TOKEN}" \
    --request POST \
    --data @database-role-b-file.json \
    ${VAULT_ADDR}/v1/database/roles/my-readwrite-role

    echo 'Finished Vault MongoDB Dynamic Credentials Config using Vault API calls'

}

#enable_dynamic_credentials_via_vault_api
enable_dynamic_credentials_via_vault_client



