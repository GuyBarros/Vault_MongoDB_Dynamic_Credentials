#!/usr/bin/env bash

set -x
echo 'Start Vault MongoDB Dynamic Credentials Config'

IFACE=`route -n | awk '$1 == "192.168.2.0" {print $8}'`
CIDR=`ip addr show ${IFACE} | awk '$2 ~ "192.168.2" {print $2}'`
IP=${CIDR%%/24}

if [ "${TRAVIS}" == "true" ]; then
IP=${IP:-127.0.0.1}
fi

if [ -d /vagrant ]; then
  LOG="/vagrant/logs/vault_audit_${HOSTNAME}.log"
else
  LOG="vault_audit.log"
fi

# enable database secret engine
VAULT_TOKEN=`cat /usr/local/bootstrap/.vault-token`
sudo VAULT_TOKEN=${VAULT_TOKEN} VAULT_ADDR="http://${IP}:8200" vault secrets enable database

# configure Audit Backend

VAULT_AUDIT_LOG="${LOG}"

tee audit-backend-file.json <<EOF
{
  "type": "file",
  "options": {
    "path": "${VAULT_AUDIT_LOG}"
  }
}
EOF

curl \
    --header "X-Vault-Token: ${VAULT_TOKEN}" \
    --request PUT \
    --data @audit-backend-file.json \
    ${VAULT_ADDR}/v1/sys/audit/file-audit


sudo VAULT_TOKEN=${VAULT_TOKEN} VAULT_ADDR="http://${IP}:8200" vault write database/config/my-mongodb-database \
    plugin_name=mongodb-database-plugin \
    allowed_roles="my-dbOwner-role, my-dbAdmin-role" \
    connection_url="mongodb://{{username}}:{{password}}@192.168.2.12:27017/vault_demo_db?ssl=false" \
    username="vault_admin" \
    password="r3ally5tr0ngPa55w0rd"

sudo VAULT_TOKEN=${VAULT_TOKEN} VAULT_ADDR="http://${IP}:8200" vault write database/roles/my-dbOwner-role \
    db_name=my-mongodb-database \
    creation_statements='{ "db": "vault_demo_db", "roles": [{ "role": "dbOwner" }] }' \
    default_ttl="1h" \
    max_ttl="24h"
sudo VAULT_TOKEN=${VAULT_TOKEN} VAULT_ADDR="http://${IP}:8200" vault write database/roles/my-dbAdmin-role \
    db_name=my-mongodb-database \
    creation_statements='{ "db": "vault_demo_db", "roles": [{ "role": "dbAdmin" }] }' \
    default_ttl="1h" \
    max_ttl="24h"

echo 'Finished Vault MongoDB Dynamic Credentials Config'