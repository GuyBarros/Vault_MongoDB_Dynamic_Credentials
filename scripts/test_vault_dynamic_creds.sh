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
    RESULT=`mongo ${DB}/vault_demo_db -u ${DYNAMIC_USER} -p ${DYNAMIC_PASSWORD} /usr/local/bootstrap/conf/performTestWrite.js`
    echo ${RESULT}
 
    if [ ${RESULT} == *"Error"* ] && [ $2 == "EXPECTPASS" ]; then
        echo -e "FAIL: The database read write test have not worked as expected!\n"
        return 1
    fi

    if [ ${RESULT} == *"Error"* ] && [ $2 == "EXPECTFAIL" ]; then
        echo -e "SUCCESS: The database write test has failed for this ROLE - $3 - as expected!\n"
        return 0
    fi

    if [ ${RESULT} != *"Error"* ] && [ $2 == "EXPECTPASS" ]; then
        echo -e "SUCCESS: The database write test has succeeded for this ROLE - $3 - as expected!\n"
        return 0
    fi

}

sudo VAULT_TOKEN=${VAULT_TOKEN} VAULT_ADDR="http://${IP}:8200" vault status

echo "Testing the DB READ Role - This should fail to WRITE!"
sudo VAULT_TOKEN=${VAULT_TOKEN} VAULT_ADDR="http://${IP}:8200" vault read database/creds/my-read-role > /usr/local/bootstrap/.dynamicuserdetails.txt
EXITCODE1=$(test_db_user /usr/local/bootstrap/.dynamicuserdetails.txt EXPECTFAIL my-read-role)

echo "Testing the DB READWRITE Role - This should successfully WRITE!"
sudo VAULT_TOKEN=${VAULT_TOKEN} VAULT_ADDR="http://${IP}:8200" vault read database/creds/my-readwrite-role > /usr/local/bootstrap/.dynamicuserdetails.txt
EXITCODE2=$(test_db_user /usr/local/bootstrap/.dynamicuserdetails.txt EXPECTPASS my-readwrite-role)

echo 'Finished Vault MongoDB Dynamic Credentials Testing'

if [[ ${EXITCODE1} != "0" ]] || [[ ${EXITCODE2} != "0" ]]; then
    echo -e "TEST FAIL\n"
    exit 1
else
    echo -e "TEST PASS\n"
    exit 0
fi