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
    MONGOSVR: Start Vault MongoDB Dynamic Credentials Testing
    MONGOSVR: K
    MONGOSVR: e
    MONGOSVR: y
    MONGOSVR:
    MONGOSVR:
    MONGOSVR:
    MONGOSVR:
    MONGOSVR:
    MONGOSVR:
    MONGOSVR:
    MONGOSVR:
    MONGOSVR:
    MONGOSVR:
    MONGOSVR:
    MONGOSVR:
    MONGOSVR:
    MONGOSVR: V
    MONGOSVR: a
    MONGOSVR: lue
    MONGOSVR: ---             -----
    MONGOSVR: Seal Type       shamir
    MONGOSVR: Sealed          false
    MONGOSVR: Total Shares    1
    MONGOSVR: Threshold       1
    MONGOSVR: Version         0.11.0
    MONGOSVR: Cluster Name    vault-cluster-6dbcdb23
    MONGOSVR: Cluster ID      8ada2c9c-6de3-950d-9ed2-e1742132e1cd
    MONGOSVR: HA Enabled      true
    MONGOSVR: HA Cluster      https://192.168.2.11:8201
    MONGOSVR: HA Mode         active
    MONGOSVR: Testing the DB READ Role - This should fail to WRITE!
    MONGOSVR: Key                Value
    MONGOSVR: ---                -----
    MONGOSVR: lease_id           database/creds/my-read-role/9c64393b-4dce-4ea5-b06e-dceabb9e30a3
    MONGOSVR: lease_duration     1h
    MONGOSVR: lease_renewable    true
    MONGOSVR: password           A1a-15IpQHouasfLn7EJ
    MONGOSVR: username           v-root-my-read-role-2EdcNCQ5lT2nzJ0zFj9d-1536319430
    MONGOSVR: MongoDB shell version v3.4.17 connecting to: mongodb://192.168.2.12:27017/vault_demo_db MongoDB server version: 3.4.17 { "writeError" : { "code" : 13, "errmsg" : "not authorized on vault_demo_db to execute command { insert: \"MyCollection\", documents: [ { _id: ObjectId('5b925fc6da14f22564d6eec0'), name: \"my_mongo_test\", title: \"vaulttest\" } ], ordered: true }" } }
    MONGOSVR: SUCCESS: The database write test has failed for this ROLE - my-read-role - as expected!
    MONGOSVR: Testing the DB READWRITE Role - This should successfully WRITE!
    MONGOSVR: Key                Value
    MONGOSVR: ---                -----
    MONGOSVR: lease_id           database/creds/my-readwrite-role/657c8168-7626-2009-2235-e138c05b3c09
    MONGOSVR: lease_duration     1h
    MONGOSVR: lease_renewable    true
    MONGOSVR: password           A1a-SUkBhlOjFdmuagey
    MONGOSVR: username           v-root-my-readwrite-ro-BMIYX62LfMKpgaqXa9S1-1536319430
    MONGOSVR: MongoDB shell version v3.4.17 connecting to: mongodb://192.168.2.12:27017/vault_demo_db MongoDB server version: 3.4.17 { "nInserted" : 1 }
    MONGOSVR: SUCCESS: The database write test has succeeded for this ROLE - my-readwrite-role - as expected!
    MONGOSVR: Finished Vault MongoDB Dynamic Credentials Testing
```
NOTE: For the purpose of this demo I have deliberately displayed the ephemeral dynamic credentials and yes I've hardcoded the test db password :)
For a production environment please ensure that SSL is used for all data in transit, also I have not configured SSL on theb MongoDB.

This is only a very small use case for the fantastic secrets management tool that is [HashiCorp's VAULT](https://www.vaultproject.io/)

## TODO


### New Features


### Refactor


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
