#!/usr/bin/env bash

set -x

IFACE=`route -n | awk '$1 == "192.168.2.0" {print $8}'`
CIDR=`ip addr show ${IFACE} | awk '$2 ~ "192.168.2" {print $2}'`
IP=${CIDR%%/24}

if [ "${TRAVIS}" == "true" ]; then
IP=${IP:-127.0.0.1}
fi

export VAULT_ADDR=http://${IP}:8200
export VAULT_SKIP_VERIFY=true
export VAULT_TOKEN=`cat /usr/local/bootstrap/.vault-token`

test_db_user () {
    DYNAMIC_USER=`cat /usr/local/bootstrap/.dynamicuserdetails.txt | awk '{ for (x=1;x<=NF;x++) if ($x~"username") print $(x+1) }'`
    DYNAMIC_PASSWORD=`cat /usr/local/bootstrap/.dynamicuserdetails.txt | awk '{ for (x=1;x<=NF;x++) if ($x~"password") print $(x+1) }'`
    mongo 192.168.2.12/vault_demo_db -u ${DYNAMIC_USER} -p ${DYNAMIC_PASSWORD} --eval "printjson(db.getUsers())"
    mongo 192.168.2.12/vault_demo_db -u ${DYNAMIC_USER} -p ${DYNAMIC_PASSWORD} --eval "printjson(db.getName())"
}

echo "Testing the DB Admin Role - This should fail to list all the users"
vault read database/creds/my-dbAdmin-role > /usr/local/bootstrap/.dynamicuserdetails.txt
test_db_user

echo "Testing the DB Owner Role - This should successfully list all the users"
vault read database/creds/my-dbOwner-role > /usr/local/bootstrap/.dynamicuserdetails.txt
test_db_user