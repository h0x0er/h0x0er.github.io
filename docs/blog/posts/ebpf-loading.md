---
date: 2025-06-21
draft: true
authors:
 - jatin
categories:
 - ebpf
---

# eBPF: Loading in different kernels


## Objective

- to test loading of compiled eBPF program in different kernels within `Github Actions`

!!! note "Why ?"
    



## Reasoning


### LVH

For loading eBPF object in different kernels, we will be using [little-vm-helper(LVH)](https://github.com/cilium/little-vm-helper), an open-source cilium project for creating light-weight virtual machines.


LVH has [Github Action](https://github.com/cilium/little-vm-helper/blob/main/action.yaml) that can be used to launch a `little-vm` with a `custom linux-kernel image` inside Github Action Runner VM. 

### LVH Images

Kernel images used by LVH are built using another open-source cilium project namely [little-vm-helper-images](https://github.com/cilium/little-vm-helper-images). 
These kernel-images are stored [here](https://quay.io/repository/lvh-images/kind?tab=tags).

As of now [3 variants](https://github.com/cilium/little-vm-helper-images/blob/main/_data/images.json) of images are available:

 - base
 - kind
 - complexity-test

These differ by:

  - [userspace setup](https://github.com/cilium/little-vm-helper-images/blob/a9fad6b573f8ccb8f40eacb45268ef1b19073ba6/_data/images.json#L18-L33).

  - [packages](https://github.com/cilium/little-vm-helper-images/blob/a9fad6b573f8ccb8f40eacb45268ef1b19073ba6/_data/images.json#L3-L18): the kind of packages available inside them, e.g in some `dig` is not available.

<!-- more -->


## Code


!!! Note
    Checkout: [https://github.com/h0x0er/ebpf-playground/blob/main/.github/workflows/load-lvh.yml](https://github.com/h0x0er/ebpf-playground/blob/main/.github/workflows/load-lvh.yml)

```yaml title="load.yml" linenums="1"
name: LVH Load

on:
  workflow_dispatch:

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
 
  load-vm:
    runs-on: ubuntu-latest
    name: eBPF Load
    strategy:
      fail-fast: false
      matrix:
        # for kernel tags: https://quay.io/repository/lvh-images/kind?tab=tags
        kernel: 
          - "6.6-20250616.013250-amd64"
          - "5.15-20250616.013250-amd64"
          - "5.10-20250610.043823-amd64"
          
    timeout-minutes: 10
    steps:

      - run: | 
          # download the compiled obj 
          wget --quiet https://github.com/cilium/ebpf/raw/refs/heads/main/examples/cgroup_skb/bpf_bpfel.o  
          ls -lah
      
      - name: Provision LVH VMs
        uses: cilium/little-vm-helper@v0.0.23
        with:
          test-name: load-test
          image: "kind"
          image-version: ${{ matrix.kernel }}
          host-mount: .
          install-dependencies: "true"
          cmd: |
            # print kernel version
            echo "Kernel Version: "
            uname -a
            
            # goto where host is mounted
            echo ""
            cd /host
            ls -lah

            # (1)
            echo ""
            sudo bpftool prog load ./bpf_bpfel.o /sys/fs/bpf/test && echo "Load Success"

```

1. load program using bpftool



## Refer

- https://github.com/cilium/little-vm-helper
- https://github.com/cilium/little-vm-helper-images/blob/main/_data/images.json
- :arrow_right: https://quay.io/repository/lvh-images/kind?tab=tags

- https://github.com/h0x0er/ebpf-playground