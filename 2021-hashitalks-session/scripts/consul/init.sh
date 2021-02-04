
echo "--> Writing configuration"
sudo mkdir -p /mnt/consul
sudo mkdir -p /etc/consul.d
sudo tee /etc/consul.d/config.json > /dev/null <<EOF
{
  "datacenter": "dc1",
  "primary_datacenter":  "dc1",
  "bootstrap_expect": 1,
  "client_addr": "0.0.0.0",
  "bind_addr": "$2",
  "data_dir": "/mnt/consul",
  "leave_on_terminate": true,
  "server": true,
  "ports": {
    "http": 8500,
    "https": 8501,
    "grpc": 8502
  },
  "connect":{
    "enabled": true
  },
  "ui": true,
  "enable_central_service_config":true,
"autopilot": {
    "cleanup_dead_servers": true,
    "last_contact_threshold": "200ms",
    "max_trailing_logs": 250,
    "server_stabilization_time": "10s",
    "disable_upgrade_migration": false
  },
  "telemetry": {
    "disable_hostname": true,
    "prometheus_retention_time": "30s"
  },
  "recursors": ["169.254.169.253","1.1.1.1","1.0.0.1","8.8.8.8"]
}
EOF

echo "--> Writing profile"
sudo tee /etc/profile.d/consul.sh > /dev/null <<"EOF"
alias conslu="consul"
alias ocnsul="consul"
EOF
source /etc/profile.d/consul.sh

echo "--> Generating systemd configuration"
sudo tee /etc/systemd/system/consul.service > /dev/null <<"EOF"
[Unit]
Description=Consul
Documentation=https://www.consul.io/docs/
Requires=network-online.target
After=network-online.target
[Service]
Restart=on-failure
ExecStart=consul agent -config-dir="/etc/consul.d"
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGINT
[Install]
WantedBy=multi-user.target
EOF
sudo systemctl enable consul
sudo systemctl restart consul

echo "--> setting up resolv.conf"
ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf

mkdir /etc/systemd/resolved.conf.d
touch /etc/systemd/resolved.conf.d/forward-consul-domains.conf

printf "[Resolve]\nDNS=127.0.0.1\nDomains=~consul\n" > /etc/systemd/resolved.conf.d/forward-consul-domains.conf

sudo iptables -t nat -A OUTPUT -d localhost -p udp -m udp --dport 53 -j REDIRECT --to-ports 8600
sudo iptables -t nat -A OUTPUT -d localhost -p tcp -m tcp --dport 53 -j REDIRECT --to-ports 8600


systemctl daemon-reload
systemctl restart systemd-resolved
echo "==> Consul is done!"