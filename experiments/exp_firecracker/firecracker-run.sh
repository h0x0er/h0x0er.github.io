#!/bin/bash

set -x

download-kernel() {
	ARCH="$(uname -m)"
	release_url="https://github.com/firecracker-microvm/firecracker/releases"
	latest_version=$(basename $(curl -fsSLI -o /dev/null -w %{url_effective} ${release_url}/latest))
	CI_VERSION=${latest_version%.*}
	latest_kernel_key=$(curl "http://spec.ccfc.min.s3.amazonaws.com/?prefix=firecracker-ci/$CI_VERSION/$ARCH/vmlinux-&list-type=2" |
		grep -oP "(?<=<Key>)(firecracker-ci/$CI_VERSION/$ARCH/vmlinux-[0-9]+\.[0-9]+\.[0-9]{1,3})(?=</Key>)" |
		sort -V | tail -1)

	# Download a linux kernel binary
	wget "https://s3.amazonaws.com/spec.ccfc.min/${latest_kernel_key}"

	latest_ubuntu_key=$(curl "http://spec.ccfc.min.s3.amazonaws.com/?prefix=firecracker-ci/$CI_VERSION/$ARCH/ubuntu-&list-type=2" |
		grep -oP "(?<=<Key>)(firecracker-ci/$CI_VERSION/$ARCH/ubuntu-[0-9]+\.[0-9]+\.squashfs)(?=</Key>)" |
		sort -V | tail -1)
	ubuntu_version=$(basename $latest_ubuntu_key .squashfs | grep -oE '[0-9]+\.[0-9]+')

	# Download a rootfs from Firecracker CI
	wget -O ubuntu-$ubuntu_version.squashfs.upstream "https://s3.amazonaws.com/spec.ccfc.min/$latest_ubuntu_key"
}

spin-vm() {
	sudo release-v1.13.1-x86_64/firecracker-v1.13.1-x86_64 --api-sock /tmp/firecracker.socket --config-file vm_template.json
}

setup-overlay() {

	local lower="./squashfs-root"
	local upper="./overlay-upper"
	local mount_point="./exp-overlay"

	sudo mount overlay -t overlay -olowerdir=$lower,upperdir=$upper,workdir=./work $mount_point

}

# run cmd
$1
