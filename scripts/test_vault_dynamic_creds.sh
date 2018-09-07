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
TEST_STATUS="GOOD"

test_db_user () {
    cat $1
    DYNAMIC_USER=`cat $1 | awk '{ for (x=1;x<=NF;x++) if ($x~"username") print $(x+1) }'`
    DYNAMIC_PASSWORD=`cat $1 | awk '{ for (x=1;x<=NF;x++) if ($x~"password") print $(x+1) }'`
    RESULT=`mongo ${DB}/vault_demo_db -u ${DYNAMIC_USER} -p ${DYNAMIC_PASSWORD} /usr/local/bootstrap/conf/performTestWrite.js`
    echo ${RESULT}
 
    if [[ ${RESULT} = *"Error"* ]] && [[ $2 = "EXPECTPASS" ]]; then
        echo -e "FAIL: The database read write test has not worked as expected!\n"
        echo -e "Finished Vault MongoDB Dynamic Credentials Testing\n"
        exit 1
    fi

    if [[ ${RESULT} = *"Error"* ]] && [[ $2 = "EXPECTFAIL" ]]; then
        echo -e "SUCCESS: The database write test has failed for this ROLE - $3 - as expected!\n"
    fi

    if [[ ${RESULT} != *"Error"* ]] && [[ $2 = "EXPECTPASS" ]]; then
        echo -e "SUCCESS: The database write test has succeeded for this ROLE - $3 - as expected!\n"
    fi

}

sudo VAULT_TOKEN=${VAULT_TOKEN} VAULT_ADDR="http://${IP}:8200" vault status

echo "Testing the DB READWRITE Role - This should successfully WRITE!"
sudo VAULT_TOKEN=${VAULT_TOKEN} VAULT_ADDR="http://${IP}:8200" vault read database/creds/my-readwrite-role > /usr/local/bootstrap/.dynamicuserdetails.txt
test_db_user /usr/local/bootstrap/.dynamicuserdetails.txt EXPECTPASS my-readwrite-role

echo "Testing the DB READ Role - This should fail to WRITE!"
sudo VAULT_TOKEN=${VAULT_TOKEN} VAULT_ADDR="http://${IP}:8200" vault read database/creds/my-read-role > /usr/local/bootstrap/.dynamicuserdetails.txt
test_db_user /usr/local/bootstrap/.dynamicuserdetails.txt EXPECTFAIL my-read-role

echo 'Finished Vault MongoDB Dynamic Credentials Testing'
exit 0
