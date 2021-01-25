#set Vault address and Vault token enviroment variables
export VAULT_ADDR=http://desktop-khfd9va.lan:8200
export VAULT_TOKEN=s.wrlHqUffYHZNY9IGJXUf3cbT
################################## CHANGE THIS LATER TO USE VAULT AGENT #######################################################################
# CA
#####################
#
sudo mkdir /etc/kubernetes/pki
sudo mkdir /etc/kubernetes/pki/etcd
################################## CHANGE THIS LATER TO USE VAULT AGENT #######################################################################
#
#       sa.key
#       sa.pub
##### KUBERNETES
##  openssl x509 -in peer.crt -text -noout
## openssl verify -verbose -CAfile cacert.pem  server.crt
# CA
sudo cp kubernetes-ca-all.pem /etc/kubernetes/pki/ca.pem
# APISERVER
vault write -format=json kubernetes_int/issue/apiserver common_name="kube-apiserver" ip_sans="127.0.0.1,172.16.16.111,10.96.0.1,192.168.225.193" alt_names="localhost,kjump1,kubernetes,kubernetes.default,kubernetes.default.svc,kubernetes.default.svc.cluster.local" ttl="24h" > apiserver.json
cat apiserver.json | jq -r .data.certificate > apiserver.crt
cat apiserver.json | jq -r .data.private_key > apiserver.key
rm apiserver.json
sudo cp apiserver.crt /etc/kubernetes/pki/apiserver.crt
sudo cp apiserver.key /etc/kubernetes/pki/apiserver.key
# APISERVER-KUBELET-CLIENT
vault write -format=json kubernetes_int/issue/kube-apiserver-kubelet-client common_name="kube-apiserver-kubelet-client" ip_sans="127.0.0.1,172.16.16.111,10.96.0.1,192.168.225.193" alt_names="localhost,kjump1,kubernetes,kubernetes.default,kubernetes.default.svc,kubernetes.default.svc.cluster.local" ttl="24h" > apiserver-kubelet-client.json
cat apiserver-kubelet-client.json | jq -r .data.certificate > apiserver-kubelet-client.crt
cat apiserver-kubelet-client.json | jq -r .data.private_key > apiserver-kubelet-client.key
rm apiserver-kubelet-client.json
sudo cp apiserver-kubelet-client.crt /etc/kubernetes/pki/apiserver-kubelet-client.crt
sudo cp apiserver-kubelet-client.key /etc/kubernetes/pki/apiserver-kubelet-client.key
# APISERVER-ETCD-CLIENT
vault write -format=json etcd_int/issue/kube-apiserver-etcd-client common_name="kube-apiserver-kubelet-client"  ttl="24h" > kube-apiserver-etcd-client.json
cat kube-apiserver-etcd-client.json | jq -r .data.certificate > kube-apiserver-etcd-client.crt
cat kube-apiserver-etcd-client.json | jq -r .data.private_key > kube-apiserver-etcd-client.key
rm kube-apiserver-etcd-client.json
sudo cp kube-apiserver-etcd-client.crt /etc/kubernetes/pki/kube-apiserver-etcd-client.crt
sudo cp kube-apiserver-etcd-client.key /etc/kubernetes/pki/kube-apiserver-etcd-client.key
##### ETCD
#ca.crt  ca.key  healthcheck-client.crt  healthcheck-client.key  peer.crt  peer.key  server.crt  server.key
# CA
sudo cp etcd-ca-all.pem /etc/kubernetes/pki/etcd/ca.pem
# healthcheck-client
vault write -format=json etcd_int/issue/kube-etcd-healthcheck-client common_name="kube-etcd-healthcheck-client"  ttl="24h" > healthcheck-client.json
cat healthcheck-client.json | jq -r .data.certificate > healthcheck-client.crt
cat healthcheck-client.json | jq -r .data.private_key > healthcheck-client.key
rm healthcheck-client.json
sudo cp healthcheck-client.crt /etc/kubernetes/pki/etcd/healthcheck-client.crt
sudo cp healthcheck-client.key /etc/kubernetes/pki/etcd/healthcheck-client.key
# peer
vault write -format=json etcd_int/issue/kube-etcd-peer common_name="kjump1" ip_sans="127.0.0.1,192.168.225.193" alt_names="localhost,kjump1"  ttl="24h" > kube-etcd-peer.json
cat kube-etcd-peer.json | jq -r .data.certificate > peer.crt
cat kube-etcd-peer.json | jq -r .data.private_key > peer.key
rm kube-etcd-peer.json
sudo cp peer.crt /etc/kubernetes/pki/etcd/peer.crt
sudo cp peer.key /etc/kubernetes/pki/etcd/peer.key
# server
vault write -format=json etcd_int/issue/etcd-ca common_name="kjump1" ip_sans="127.0.0.1,192.168.225.193" alt_names="localhost,kjump1"  ttl="24h" > server.json
cat server.json | jq -r .data.certificate > server.crt
cat server.json | jq -r .data.private_key > server.key
rm server.json
sudo cp server.crt /etc/kubernetes/pki/etcd/server.crt
sudo cp server.key /etc/kubernetes/pki/etcd/server.key
##### PROXY
# front-proxy-ca
vault write -format=json proxy_int/issue/front-proxy-ca common_name="front-proxy-ca"  ttl="24h" > front-proxy-ca.json
cat front-proxy-ca.json | jq -r .data.certificate > front-proxy-ca.crt
cat front-proxy-ca.json | jq -r .data.private_key > front-proxy-ca.key
rm front-proxy-ca.json
sudo cp front-proxy-ca.crt /etc/kubernetes/pki/front-proxy-ca.crt
sudo cp front-proxy-ca.key /etc/kubernetes/pki/front-proxy-ca.key
# front-proxy-client
vault write -format=json proxy_int/issue/front-proxy-ca common_name="front-proxy-client"  ttl="24h" > front-proxy-client.json
cat front-proxy-client.json | jq -r .data.certificate > front-proxy-client.crt
cat front-proxy-client.json | jq -r .data.private_key > front-proxy-client.key
rm front-proxy-client.json
sudo cp front-proxy-client.crt /etc/kubernetes/pki/front-proxy-client.crt
sudo cp front-proxy-client.key /etc/kubernetes/pki/front-proxy-client.key