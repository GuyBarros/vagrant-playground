#!/usr/bin/env bash
echo "==> Vault (server)"


echo "--> Writing configuration"
sudo mkdir -p /etc/vault.d/logs
sudo mkdir -p /etc/vault.d/raft
sudo mkdir -p /etc/vault.d/plugins

sudo tee /etc/vault.d/config.hcl > /dev/null <<EOF
cluster_name = "demostack"
cluster_addr = "http://$2:8201"

storage "raft" {
  path = "/etc/vault.d/raft"
  node_id = "raft_node_$1"
}

service_registration "consul" {
  address      = "127.0.0.1:8500"
  scheme       = "http"
}

listener "tcp" {
  address       = "0.0.0.0:8200"
   tls_disable = true
   tls-skip-verify = true
}

telemetry {
  prometheus_retention_time = "30s",
  disable_hostname = true
}
replication {
      resolver_discover_servers = false
}
plugin_directory = "/etc/vault.d/plugins"
api_addr = "http://$2:8200"
disable_mlock = true
ui = true
EOF

echo "--> Writing profile"
sudo tee /etc/profile.d/vault.sh > /dev/null <<"EOF"
alias vualt="vault"
export VAULT_ADDR="http://$2:8200"
EOF
source /etc/profile.d/vault.sh

echo "--> Generating systemd configuration"
sudo tee /etc/systemd/system/vault.service > /dev/null <<"EOF"
[Unit]
Description=Vault
Documentation=http://www.vaultproject.io/docs/
Requires=network-online.target
After=network-online.target
[Service]
Restart=on-failure
ExecStart=vault server -config="/etc/vault.d/config.hcl"
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGINT
[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable vault
sudo systemctl start vault
sleep 8

while ! curl $VAULT_ADDR/sys/health -s --show-error; do
  echo "Waiting for Vault to be ready"
  sleep 2
done

vault operator init -status > /dev/null
if [ $? -eq 2 ]; then
vault operator init > keys.txt
fi

##########################################################################################################
######### ALL OF THE BELLOW IS A VERY VERY BAD IDEA, NEVER DO IT IN PRODUCTION!!!!!!!!!!!!!!!!!!!#########
##########################################################################################################
#   The exit code reflects the seal status:
#       - 0 - unsealed
#       - 1 - error
#       - 2 - sealed
vault status
if [ $? -eq 2 ]; then
vault operator unseal $(grep -h 'Unseal Key 1' keys.txt | awk '{print $NF}')
vault operator unseal $(grep -h 'Unseal Key 2' keys.txt | awk '{print $NF}')
vault operator unseal $(grep -h 'Unseal Key 3' keys.txt | awk '{print $NF}')
 sleep 10
fi

vault operator init -status > /dev/null
if [ $? -eq 0 ]; then
# login
vault login $(grep -h 'Initial Root Token' keys.txt | awk '{print $NF}') > /dev/null
vault token create -id root -display-name root
vault audit enable file file_path=/etc/vault.d/logs/$(date "+%Y%m%d%H%M.%S").log.json
echo "==> Vault is done!"
fi

echo "==> This is a test $2"