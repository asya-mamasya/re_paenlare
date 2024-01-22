#!/bin/env bash

apt_dir=etc/apt
sources_dir="$apt_dir"/sources.list.d
keyrings_dir="$apt_dir"/keyrings
sudo mkdir -p $sources_dir $keyrings_dir
keys=$(command ls "/$keyrings_dir")

function update_keys() {
	for k in $keys; do
		sudo gpg --no-default-keyring \
			--keyring "/$keyrings_dir/$k" \
			--keyserver hkps://keyserver.ubuntu.com
		# --recv-keys <fingerprint>
	done
}
# gpg --list-keys --with-colons | awk -F: '/^fpr:/ { print $10 }'
# gpg --list-keys --with-colons | awk -F: '/^pub:/ { print $5 }'
# gpg --no-default-keyring --keyring /etc/apt/keyrings/*.gpg --fingerprint
# gpg --no-default-keyring --keyring /etc/apt/keyrings/brave-browser-release.gpg --with-colons --fingerprint
# gpg --no-default-keyring --keyring /etc/apt/keyrings/brave-browser-release.gpg --with-colons --fingerprint | awk -F: '/^fpr:/ { print $10 }'
# gpg --no-default-keyring --keyring /etc/apt/keyrings/brave-browser-release.gpg --fingerprint | sed -n '/^\s/s/\s*//p'

function to_ascii_apt_keys() {
	for k in $keys; do
		gpg --export --armor --no-default-keyring --keyring $keyrings_dir/$k -o destination_dir/$k
	done
}
