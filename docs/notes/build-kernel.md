# Build Kernel

On following build steps, a vmlinux binary of about 30MB will get built. It can be used with firecracker-vm by specifying in [`kernel_image_path`](./firecracker.md#vm-template).

## Build Steps


- Checkout latest code in current directory or download from https://www.kernel.org/

```sh
git clone --depth 1 -b master \
  https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git .
```

- Create `.config` file, use [firecracker minimal config](https://github.com/firecracker-microvm/firecracker/blob/main/resources/guest_configs/microvm-kernel-ci-x86_64-6.1.config)

```sh

wget -O .config \
    https://raw.githubusercontent.com/firecracker-microvm/firecracker/refs/heads/main/resources/guest_configs/microvm-kernel-ci-x86_64-6.1.config

```

- Add `pcie` and `virtio` related flags in `.config`, without these kernel won't boot (required for attaching block-devices)
  
```sh

## PCIE flags

CONFIG_BLK_MQ_PCI=y
CONFIG_PCI=y
CONFIG_PCI_MMCONFIG=y
CONFIG_PCI_MSI=y
CONFIG_PCIEPORTBUS=y
CONFIG_VIRTIO_PCI=y
CONFIG_PCI_HOST_COMMON=y
CONFIG_PCI_HOST_GENERIC=y


# VIRTIO flags
CONFIG_VIRTIO_MEM=y
CONFIG_STRICT_DEVMEM=y

```


- Do oldconfig

```sh
make oldconfig

```

- Perform build

```sh
make -j $(nproc --all)
```


## Refer

- https://docs.kernel.org/admin-guide/quickly-build-trimmed-linux.html