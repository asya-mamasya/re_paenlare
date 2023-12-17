#!/bin/bash

docker_remove() {
	for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
		sudo apt-get remove $pkg
	done
}
docker_remove

# Add Docker's official GPG key:
docker_gpg_key() {
	sudo apt-get update
	sudo apt-get install ca-certificates curl gnupg
	sudo install -m 0755 -d /etc/apt/keyrings
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
	sudo chmod a+r /etc/apt/keyrings/docker.gpg
}
docker_gpg_key
# Add the repository to Apt sources:
docker_repo() {
	echo \
		"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |
		sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
	sudo apt-get update
}
docker_repo

# Install Docker Engine
docker_engine_install() {
	sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

# Remove docker-engine
docker_engine_remove() {
	sudo apt-get purge docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras
	sudo rm -rf /var/lib/docker
	sudo rm -rf /var/lib/containerd
}
