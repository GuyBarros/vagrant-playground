#!/bin/bash

# disable swapp
sudo swapoff -a

# Letting iptables see bridged traffic
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system

# install helpful packages
sudo apt-get update
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common \
    jq

# (Install Docker CE)
## Set up the repository:
### Install packages to allow apt to use a repository over HTTPS
sudo apt-get update && sudo apt-get install -y \
  apt-transport-https ca-certificates curl software-properties-common gnupg2

# Add Docker's official GPG key:
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# Add the Docker apt repository:
sudo add-apt-repository \
  "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) \
  stable"

# Install Docker CE
sudo apt-get update && sudo apt-get install -y \
  containerd.io=1.2.13-2 \
  docker-ce=5:19.03.11~3-0~ubuntu-$(lsb_release -cs) \
  docker-ce-cli=5:19.03.11~3-0~ubuntu-$(lsb_release -cs)

# Set up the Docker daemon
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

sudo mkdir -p /etc/systemd/system/docker.service.d

# Restart Docker
sudo systemctl daemon-reload
sudo systemctl restart docker

sudo systemctl enable docker

#Installing kubeadm, kubelet and kubectl
sudo apt-get update && sudo apt-get install -y apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
sudo apt-get update && sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

#pull kubeadm images
kubeadm config images pull

#install vault
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
 sudo apt-get update && sudo apt-get install vault


#set Vault address and Vault token enviroment variables
export VAULT_ADDR=http://desktop-khfd9va.lan:8200
export VAULT_TOKEN=s.wrlHqUffYHZNY9IGJXUf3cbT

#CA Mount
vault secrets enable -path=kubernetes_root pki

vault secrets tune -max-lease-ttl=87600h kubernetes_root

# Kubernetes CA Cert
vault write -format=json kubernetes_root/root/generate/exported common_name="kubernetes-ca" ttl=315360000s > ca.json

vault write kubernetes_root/config/urls issuing_certificates="http://desktop-khfd9va.lan:8200/v1/pki/ca" crl_distribution_points="http://desktop-khfd9va.lan:8200/v1/pki/crl"


# Kubernetes Intermediate CA
vault secrets enable -path=kubernetes_int pki

vault secrets tune -max-lease-ttl=43800h kubernetes_int

 vault write -format=json kubernetes_int/intermediate/generate/internal \
        common_name="kubernetes-ca" \
        | jq -r '.data.csr' > pki_intermediate.csr

 vault write -format=json kubernetes_root/root/sign-intermediate csr=@pki_intermediate.csr \
        format=pem_bundle ttl="43800h" \
        | jq -r '.data.certificate' > intermediate.cert.pem

vault write kubernetes_int/intermediate/set-signed certificate=@intermediate.cert.pem

#Roles kubernetes-ca
vault write kubernetes_int/roles/kubernetes-ca \
        allow_bare_domains=true \
        allow_subdomains=true \
        allow_glob_domains=true \
        allow_any_name=true \
        allow_ip_sans=true \
        server_flag=true \
        client_flag=true \
        max_ttl="730h" \
        ttl="720h" \
        key_usage='["DigitalSignature", "KeyAgreement", "KeyEncipherment","KeyUsageCertSign"]' \



#Roles kube-apiserver-kubelet-client
vault write kubernetes_int/roles/kube-apiserver-kubelet-client \
        allow_bare_domains=true \
        allow_subdomains=true \
        allow_glob_domains=true \
        allow_any_name=true \
        allow_ip_sans=true \
        server_flag=true \
        client_flag=true \
        max_ttl="730h" \
        ttl="720h" \
        key_usage='["DigitalSignature", "KeyAgreement", "KeyEncipherment","KeyUsageCertSign"]' \
        organization='["system:masters"]'
