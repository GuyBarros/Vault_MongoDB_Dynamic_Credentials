#!/usr/bin/env bash

source /usr/local/bootstrap/var.env

echo 'Start Vault MongoDB Dynamic Credentials Testing'

IP=${LEADER_IP}
DB=${MONGO_IP}
if [ "${TRAVIS}" == "true" ]; then
    IP="127.0.0.1"
    DB=${IP}
fi

VAULT_ADDR=http://${IP}:8200
VAULT_SKIP_VERIFY=true
VAULT_TOKEN=`cat /usr/local/bootstrap/.vault-token`

test_db_user () {
    DYNAMIC_USER=`cat /usr/local/bootstrap/.dynamicuserdetails.txt | awk '{ for (x=1;x<=NF;x++) if ($x~"username") print $(x+1) }'`
    DYNAMIC_PASSWORD=`cat /usr/local/bootstrap/.dynamicuserdetails.txt | awk '{ for (x=1;x<=NF;x++) if ($x~"password") print $(x+1) }'`
    mongo ${DB}/vault_demo_db -u ${DYNAMIC_USER} -p ${DYNAMIC_PASSWORD} --eval "printjson(db.getUsers())"
    mongo ${DB}/vault_demo_db -u ${DYNAMIC_USER} -p ${DYNAMIC_PASSWORD} --eval "printjson(db.getName())"
}

sudo VAULT_TOKEN=${VAULT_TOKEN} VAULT_ADDR="http://${IP}:8200" vault status

echo "Testing the DB Admin Role - This should fail to list all the users"
sudo VAULT_TOKEN=${VAULT_TOKEN} VAULT_ADDR="http://${IP}:8200" vault read database/creds/my-dbAdmin-role > /usr/local/bootstrap/.dynamicuserdetails.txt
test_db_user

echo "Testing the DB Owner Role - This should successfully list all the users"
sudo VAULT_TOKEN=${VAULT_TOKEN} VAULT_ADDR="http://${IP}:8200" vault read database/creds/my-dbOwner-role > /usr/local/bootstrap/.dynamicuserdetails.txt
test_db_user

echo 'Finished Vault MongoDB Dynamic Credentials Testing'