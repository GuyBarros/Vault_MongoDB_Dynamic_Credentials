#!/usr/bin/env bash

test_db_user () {
    DYNAMIC_USER=`cat /usr/local/bootstrap/.dynamicuserdetails.txt | awk '{ for (x=1;x<=NF;x++) if ($x~"username") print $(x+1) }'`
    DYNAMIC_PASSWORD=`cat /usr/local/bootstrap/.dynamicuserdetails.txt | awk '{ for (x=1;x<=NF;x++) if ($x~"password") print $(x+1) }'`
    mongo 192.168.2.12/vault_demo_db -u ${DYNAMIC_USER} -p ${DYNAMIC_PASSWORD} --eval "printjson(db.getUsers())"
    mongo 192.168.2.12/vault_demo_db -u ${DYNAMIC_USER} -p ${DYNAMIC_PASSWORD} --eval "printjson(db.getName())"
}

set -x
vault secrets enable database

vault write database/config/my-mongodb-database \
    plugin_name=mongodb-database-plugin \
    allowed_roles="my-dbOwner-role, my-dbAdmin-role" \
    connection_url="mongodb://{{username}}:{{password}}@192.168.2.12:27017/vault_demo_db?ssl=false" \
    username="vault_admin" \
    password="r3ally5tr0ngPa55w0rd"

vault write database/roles/my-dbOwner-role \
    db_name=my-mongodb-database \
    creation_statements='{ "db": "vault_demo_db", "roles": [{ "role": "dbOwner" }] }' \
    default_ttl="1h" \
    max_ttl="24h"
vault write database/roles/my-dbAdmin-role \
    db_name=my-mongodb-database \
    creation_statements='{ "db": "vault_demo_db", "roles": [{ "role": "dbAdmin" }] }' \
    default_ttl="1h" \
    max_ttl="24h"


vault read database/creds/my-dbAdmin-role > /usr/local/bootstrap/.dynamicuserdetails.txt
test_db_user
vault read database/creds/my-dbOwner-role > /usr/local/bootstrap/.dynamicuserdetails.txt
test_db_user