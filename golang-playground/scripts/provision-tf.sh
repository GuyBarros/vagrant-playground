#!/usr/bin/env bash


# install terraform
export TFVER=0.12.25

which terraform &>/dev/null || {

  # deps to download TF
  which wget unzip &>/dev/null || {
    apt-get install -y wget unzip
  }

  pushd /usr/local/bin
  wget https://releases.hashicorp.com/terraform/${TFVER}/terraform_${TFVER}_linux_amd64.zip
  unzip terraform_${TFVER}_linux_amd64.zip
  rm terraform_${TFVER}_linux_amd64.zip
  popd
}

