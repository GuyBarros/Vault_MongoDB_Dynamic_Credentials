#!/usr/bin/env bash
set -x

IFACE=`route -n | awk '$1 == "192.168.2.0" {print $8}'`
CIDR=`ip addr show ${IFACE} | awk '$2 ~ "192.168.2" {print $2}'`
IP=${CIDR%%/24}

if [ -d /vagrant ]; then
  LOG="/vagrant/logs/vault_${HOSTNAME}.log"
  VAULT_AUDIT_LOG="/vagrant/logs/vault_audit_${HOSTNAME}.log"
else
  LOG="vault.log"
  VAULT_AUDIT_LOG="vault_audit.log"
fi

if [ "${TRAVIS}" == "true" ]; then
  IP="127.0.0.1"
fi

which /usr/local/bin/vault &>/dev/null || {
    pushd /usr/local/bin
    [ -f vault_0.11.0_linux_amd64.zip ] || {
        sudo wget https://releases.hashicorp.com/vault/0.11.0/vault_0.11.0_linux_amd64.zip
    }
    sudo unzip vault_0.11.0_linux_amd64.zip
    sudo chmod +x vault
    popd
}


if [[ "${HOSTNAME}" =~ "leader" ]] || [ "${TRAVIS}" == "true" ]; then
  #lets kill past instance
  sudo killall vault &>/dev/null

  #lets delete old consul storage
  sudo consul kv delete -recurse vault

  #delete old token if present
  [ -f /usr/local/bootstrap/.vault-token ] && sudo rm /usr/local/bootstrap/.vault-token

  #start vault
  sudo /usr/local/bin/vault server  -dev -dev-listen-address=${IP}:8200 -config=/usr/local/bootstrap/conf/vault.hcl &> ${LOG} &
  echo vault started
  sleep 3 
  
  #copy token to known location
  sudo find / -name '.vault-token' -exec cp {} /usr/local/bootstrap/.vault-token \; -quit
  sudo chmod ugo+r /usr/local/bootstrap/.vault-token

  export VAULT_TOKEN=`cat /usr/local/bootstrap/.vault-token`
  export VAULT_ADDR="http://${IP}:8200"

  # configure Audit Backend
  tee audit-backend-file.json <<EOF
  {
    "type": "file",
    "options": {
      "path": "${VAULT_AUDIT_LOG}"
    }
  }
EOF

  curl \
      --header "X-Vault-Token: ${VAULT_TOKEN}" \
      --request PUT \
      --data @audit-backend-file.json \
      ${VAULT_ADDR}/v1/sys/audit/file-audit

fi
