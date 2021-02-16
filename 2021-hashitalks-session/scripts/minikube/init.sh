source helper.sh


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

curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube_latest_amd64.deb
sudo dpkg -i minikube_latest_amd64.deb

#install helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

sudo -i -u vagrant minikube start --cpus=4 -p cluster-1 --vm=true --driver=docker
sudo -i -u vagrant minikube start --cpus=2 -p cluster-2 --vm=true --driver=docker


# license
# vault write /sys/license text=$(cat /Users/rgoliveira/Documents/vault_v2lic.hclic)