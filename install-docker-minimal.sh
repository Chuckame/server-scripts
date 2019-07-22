#!/usr/bin/env bash
#
# Install docker minimal packages :
# - Docker (last version)
# - Local persistence volume driver, to persist data in wanted dir, and not into docker deep dirs

install_docker() {
    curl -fsSL https://get.docker.com | sudo bash
}

install_local_persistence() {
    curl -fsSL https://raw.githubusercontent.com/CWSpear/local-persist/master/scripts/install.sh | sudo bash
}

main() {
    install_docker
    install_local_persist
}

main
