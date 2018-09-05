#!/usr/bin/env bash

setup_environment () {

    set -x
    source /usr/local/bootstrap/var.env

    IP=${LEADER_IP}
    if [ "${TRAVIS}" == "true" ]; then
        IP="127.0.0.1"
    fi

    export VAULT_ADDR=http://${IP}:8200
    export VAULT_SKIP_VERIFY=true

    if [ -d /vagrant ]; then
    LOG="/vagrant/logs/MongoDB_${HOSTNAME}.log"
    else
    LOG="MongoDB.log"
    fi




}

install_mongodb () {

    # Install MongoDB
    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 0C49F3730359A14518585931BC711F9BA15703C6
    sudo echo "deb [ arch=amd64 ] http://repo.mongodb.org/apt/ubuntu "$(lsb_release -sc)"/mongodb-org/3.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-3.4.list
    sudo apt-get update
    sudo apt-get install -y mongodb-org
    sudo service mongod status
    sleep 60
    # Add new database user accounts 
    sudo mongo conf/configureMongoDBusers.js
    # Enable MongoDB Authentication
    sudo echo "security:\n  authorization:\tenabled" >> /etc/mongod.conf
    # Bind to all interfaces - not just localhost
    sudo sed -i '/bindIp:/s/^/#/' /etc/mongod.conf
    sudo service mongod restart


}

echo 'Start of Application Installation and Test'
setup_environment
install_mongodb
echo 'End of Application Installation and Test'

