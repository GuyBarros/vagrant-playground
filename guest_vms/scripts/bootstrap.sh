#!/bin/bash

# disable swapp
sudo swapoff -a

# install helpful packages
sudo apt-get update
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common \
    unzip \
    jq
