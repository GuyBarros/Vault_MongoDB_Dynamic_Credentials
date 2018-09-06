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
    cat $1
    DYNAMIC_USER=`cat $1 | awk '{ for (x=1;x<=NF;x++) if ($x~"username") print $(x+1) }'`
    DYNAMIC_PASSWORD=`cat $1 | awk '{ for (x=1;x<=NF;x++) if ($x~"password") print $(x+1) }'`
    mongo ${DB}/vault_demo_db -u ${DYNAMIC_USER} -p ${DYNAMIC_PASSWORD} --eval 'var document = {name  : "my_mongo_test",title : "vaulttest",};db.MyCollection.insert(document);'
    if [ $? -gt 0 ] && [ $2 == "EXPECTPASS" ]; then
        echo -e "SOMETHINGS GONE WRONG WITH THE TESTS\n"
        exit 1
    fi
}

sudo VAULT_TOKEN=${VAULT_TOKEN} VAULT_ADDR="http://${IP}:8200" vault status

echo "Testing the DB READ Role - This should fail to WRITE!"
sudo VAULT_TOKEN=${VAULT_TOKEN} VAULT_ADDR="http://${IP}:8200" vault read database/creds/my-read-role > /usr/local/bootstrap/.dynamicreaduserdetails.txt
test_db_user /usr/local/bootstrap/.dynamicreaduserdetails.txt EXPECTFAIL

echo "Testing the DB READWRITE Role - This should successfully WRITE!"
sudo VAULT_TOKEN=${VAULT_TOKEN} VAULT_ADDR="http://${IP}:8200" vault read database/creds/my-readwrite-role > /usr/local/bootstrap/.dynamicwriteuserdetails.txt
test_db_user /usr/local/bootstrap/.dynamicwriteuserdetails.txt EXPECTPASS

echo 'Finished Vault MongoDB Dynamic Credentials Testing'