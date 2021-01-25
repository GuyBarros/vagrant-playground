#!/usr/bin/env bash
sudo su
which go || {
  # make sure apt database is up-to date
  apt-get update

  # install golang
  apt-get install -y snapd
  snap install go --classic

  # set base
  # if we are in sudo use the calling user
  # we use eval as ~ won't be expanded
  if [ "${SUDO_USER}" ]; then
    BASE="`eval echo ~${SUDO_USER}`"
  else
    BASE="`eval echo ~`"
  fi

  PROFILE=${BASE}/.bash_profile
  touch ${PROFILE}

  grep 'GOROOT' ${PROFILE} &>/dev/null || {
    mkdir -p ${BASE}/go
    [ -f ${PROFILE} ] && cp ${PROFILE} ${PROFILE}.ori
    grep -v 'GOPATH|GOROOT' ${PROFILE}.ori | sudo tee -a ${PROFILE}
    echo 'export GOROOT=/snap/go/current' | sudo tee -a ${PROFILE}
    echo 'export PATH=$PATH:/snap/bin:$GOROOT/bin' | sudo tee -a ${PROFILE}
    echo 'export GOPATH=~/go' | sudo tee -a ${PROFILE}
  }

  if [ "${SUDO_USER}" ]; then
    [ -f ${PROFILE}.ori ] && chown ${SUDO_USER} ${PROFILE}.ori
    chown ${SUDO_USER} ${PROFILE}
  fi
exit