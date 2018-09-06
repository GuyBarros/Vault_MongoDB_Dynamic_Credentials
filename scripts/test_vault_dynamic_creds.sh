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
    mongo ${DB}/vault_demo_db -u ${DYNAMIC_USER} -p ${DYNAMIC_PASSWORD} --eval 'var document = {name  : "my_mongo_test",title : "vaultb test",};db.MyCollection.insert(document);'
}

sudo VAULT_TOKEN=${VAULT_TOKEN} VAULT_ADDR="http://${IP}:8200" vault status

echo "Testing the DB READ Role - This should fail to WRITE!"
sudo VAULT_TOKEN=${VAULT_TOKEN} VAULT_ADDR="http://${IP}:8200" vault read database/creds/my-read-role > /usr/local/bootstrap/.dynamicuserdetails.txt
test_db_user

echo "Testing the DB Owner Role - This should successfully WRITE to database"
sudo VAULT_TOKEN=${VAULT_TOKEN} VAULT_ADDR="http://${IP}:8200" vault read database/creds/my-readwrite-role > /usr/local/bootstrap/.dynamicuserdetails.txt
test_db_user

echo 'Finished Vault MongoDB Dynamic Credentials Testing'