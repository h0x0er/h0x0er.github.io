#!/bin/bash

start-vm() {
	qemu-system-x86_64 \
		-M microvm,x-option-roms=off,pit=off,pic=off,isa-serial=off,rtc=off \
		-enable-kvm -cpu host -m 512m -smp 2 \
		-kernel <path_to_vmlinux> -append "console=hvc0 root=/dev/vda" \
		-nodefaults -no-user-config -nographic \
		-chardev stdio,id=virtiocon0 \
		-device virtio-serial-device \
		-device virtconsole,chardev=virtiocon0 \
		-drive id=test,file=ubuntu-24.04.ext4,format=raw,if=none \
		-device virtio-blk-device,drive=test \
		-netdev tap,id=tap0,script=no,downscript=no \
		-device virtio-net-device,netdev=tap0
}
