![https://travis-ci.org/allthingsclowd/Vault_MongoDB_Dynamic_Credentials.svg?branch=master](https://travis-ci.org/allthingsclowd/Vault_MongoDB_Dynamic_Credentials.svg?branch=master)
https://travis-ci.org/allthingsclowd/Vault_MongoDB_Dynamic_Credentials

# Vault Dynamic Credentials using MongoDB

For the fundamentals of why we should all be moving to a dynamic secrets model see https://www.hashicorp.com/blog/why-we-need-dynamic-secrets

This repo provides an all-in-one example via either Travis-CI if you wish to play in the cloud or a Vagrantfile if you'd like to deploy locally and have a play.

## Prerequisites

For [Travis-CI](https://travis-ci.org/allthingsclowd/Vault_MongoDB_Dynamic_Credentials) you can simply review the build log outputs to save you having to actually deploy anything or fork this repo and modify your .Travis.yml appropriately.
This is a great option for folks with limited hardware resources, like a chromebook.

If running a [Vagrant Environment](https://www.vagrantup.com/docs/installation/) all that's required is to clone the repo and do a vagrant up as follows:

``` bash
git clone git@github.com:allthingsclowd/Vault_MongoDB_Dynamic_Credentials.git
cd Vault_MongoDB_Dynamic_Credentials
vagrant up
```

This will build a vault server running in dev mode (not for production use) and a mongodb server.

Security is enabled on Mongodb to ensure it honours Role-Based-Access-Control - /etc/mongo.conf
```
# Enable MongoDB Authentication
echo -e "security:\n    authorization:  enabled\n" | sudo tee -a /etc/mongod.conf
```

## Configuration

I've included both the Vault Client calls required and also the Vault API calls. To switch between these and see the outputs modify the function called in `vault_enable_mongodb.sh`

``` bash
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

enable_dynamic_credentials_via_vault_api
#enable_dynamic_credentials_via_vault_client
```

The test output, if successful, should look something like this:
``` bash
Key             Value
---             -----
Seal Type       shamir
Sealed          false
Total Shares    1
Threshold       1
Version         0.11.0
Cluster Name    vault-cluster-4186389e
Cluster ID      b6d9d1a0-20fe-4584-fd14-b2a11f3f65af
HA Enabled      true
HA Cluster      https://127.0.0.1:8201
HA Mode         active
+source /usr/local/bootstrap/var.env
++export LEADER_NAME=leader01.vagrant.local
++LEADER_NAME=leader01.vagrant.local
++export LEADER_IP=192.168.2.11
++LEADER_IP=192.168.2.11
++export MONGO_IP=192.168.2.12
++MONGO_IP=192.168.2.12
+echo 'Start Vault MongoDB Dynamic Credentials Config'
Start Vault MongoDB Dynamic Credentials Config
+IP=192.168.2.11
+DB=192.168.2.12
+'[' true == true ']'
+IP=127.0.0.1
+DB=127.0.0.1
+'[' -d /vagrant ']'
+LOG=vault_audit.log
++cat /usr/local/bootstrap/.vault-token
+VAULT_TOKEN=96afad6d-ad37-fcf4-10ab-4d98d51eda1f
+VAULT_ADDR=http://127.0.0.1:8200
+enable_dynamic_credentials_via_vault_api
+echo 'Start Vault MongoDB Dynamic Credentials Config using API calls'
Start Vault MongoDB Dynamic Credentials Config using API calls
+tee database-backend-file.json
    {
    "type": "database",
    "config": {
        "force_no_cache": true
    }
    }
+curl --header 'X-Vault-Token: 96afad6d-ad37-fcf4-10ab-4d98d51eda1f' --request POST --data @database-backend-file.json http://127.0.0.1:8200/v1/sys/mounts/database
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed

  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
100    83    0     0  100    83      0   4969 --:--:-- --:--:-- --:--:--  5187
+tee database-config-file.json
    {
    "plugin_name": "mongodb-database-plugin",
    "allowed_roles": "my-read-role, my-readwrite-role",
    "connection_url": "mongodb://{{username}}:{{password}}@127.0.0.1:27017/vault_demo_db?ssl=false",
    "write_concern": "{ \"wmode\": \"majority\", \"wtimeout\": 5000 }",
    "username": "vault_admin",
    "password": "r3ally5tr0ngPa55w0rd"
    }
+curl --header 'X-Vault-Token: 96afad6d-ad37-fcf4-10ab-4d98d51eda1f' --request POST --data @database-config-file.json http://127.0.0.1:8200/v1/database/config/my-mongodb-database
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed

  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
100   511  100   162  100   349    157    338  0:00:01  0:00:01 --:--:--   339
100   511  100   162  100   349    157    338  0:00:01  0:00:01 --:--:--   339
{"request_id":"4b09eee2-646d-55b5-e657-142ec8b6d1da","lease_id":"","renewable":false,"lease_duration":0,"data":null,"wrap_info":null,"warnings":null,"auth":null}
+tee database-role-a-file.json
    {
        "db_name": "my-mongodb-database",
        "creation_statements": "{ \"db\": \"vault_demo_db\", \"roles\": [{ \"role\": \"read\" }] }",
        "default_ttl": "1h",
        "max_ttl": "24h"
    }
+curl --header 'X-Vault-Token: 96afad6d-ad37-fcf4-10ab-4d98d51eda1f' --request POST --data @database-role-a-file.json http://127.0.0.1:8200/v1/database/roles/my-read-role
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed

  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
100   203    0     0  100   203      0  36882 --:--:-- --:--:-- --:--:-- 40600
+tee database-role-b-file.json
    {
        "db_name": "my-mongodb-database",
        "creation_statements":  "{ \"db\": \"vault_demo_db\", \"roles\": [{ \"role\": \"readWrite\" }] }",
        "default_ttl": "1h",
        "max_ttl": "24h"
    }
+curl --header 'X-Vault-Token: 96afad6d-ad37-fcf4-10ab-4d98d51eda1f' --request POST --data @database-role-b-file.json http://127.0.0.1:8200/v1/database/roles/my-readwrite-role
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed

  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
100   209    0     0  100   209      0  40053 --:--:-- --:--:-- --:--:-- 41800
+echo 'Finished Vault MongoDB Dynamic Credentials Config using Vault API calls'
Finished Vault MongoDB Dynamic Credentials Config using Vault API calls
Start Vault MongoDB Dynamic Credentials Testing
Key             Value
---             -----
Seal Type       shamir
Sealed          false
Total Shares    1
Threshold       1
Version         0.11.0
Cluster Name    vault-cluster-4186389e
Cluster ID      b6d9d1a0-20fe-4584-fd14-b2a11f3f65af
HA Enabled      true
HA Cluster      https://127.0.0.1:8201
HA Mode         active
Testing the DB READWRITE Role - This should successfully WRITE!
Key                Value
---                -----
lease_id           database/creds/my-readwrite-role/e16c1c33-03f7-b6b6-27cb-1089a05be53b
lease_duration     1h
lease_renewable    true
password           A1a-4J0XnPRzpLNaOrqo
username           v-root-my-readwrite-ro-3GIyGKWs3waz5Nc1bkHE-1536329141
MongoDB shell version v3.4.17 connecting to: mongodb://127.0.0.1:27017/vault_demo_db MongoDB server version: 3.4.17 { "nInserted" : 1 }
SUCCESS: The database write test has succeeded for this ROLE - my-readwrite-role - as expected!

Testing the DB READ Role - This should fail to WRITE!
Key                Value
---                -----
lease_id           database/creds/my-read-role/935fef49-4e2d-0236-7929-d907761d6de9
lease_duration     1h
lease_renewable    true
password           A1a-4AtMgbwn8CBI72a7
username           v-root-my-read-role-4hJXSONn7xNZNCIQygJl-1536329141
MongoDB shell version v3.4.17 connecting to: mongodb://127.0.0.1:27017/vault_demo_db MongoDB server version: 3.4.17 { "writeError" : { "code" : 13, "errmsg" : "not authorized on vault_demo_db to execute command { insert: \"MyCollection\", documents: [ { _id: ObjectId('5b9285b577e1fbdd7c8afbe4'), name: \"my_mongo_test\", title: \"vaulttest\" } ], ordered: true }" } }
SUCCESS: The database write test has failed for this ROLE - my-read-role - as expected!

Finished Vault MongoDB Dynamic Credentials Testing

```
NOTE: For the purpose of this demo I have deliberately displayed the ephemeral dynamic credentials and yes I've hardcoded the test db password :)
For a production environment please ensure that SSL is used for all data in transit, also I have not configured SSL on theb MongoDB.

This is only a very small use case for the fantastic secrets management tool that is [HashiCorp's VAULT](https://www.vaultproject.io/)

## TODO
- travis-ci script failures not reporting correctly - l8tr

## Done

- tidy/reset cloned repo, purge unwanted crap
- setup travis CI/CD pipeilne
- build MongoServer - see if I can get away without using SSL for demo
- build quick mongodb test
- configure vault roles
- enable vault mongodb backend and configure credentials
- build simple tests to verify creds
- add API version, currently CLI
- updated ReadMe

