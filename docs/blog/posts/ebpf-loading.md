---
date: 2025-06-21
authors:
 - jatin
categories:
 - ebpf
---

# eBPF: Loading in different kernels


## Objective

- to load compiled eBPF program in different kernels within `Github Actions`
    - for testing its compatibility with kernel and observe if it loads correctly
 
<!-- more -->


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


## Code


!!! Note
    Try forking the [ebpf-playground](https://github.com/h0x0er/ebpf-playground) and triggering the workflows.

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
        kernel: # (1)!
          - "6.6-20250616.013250-amd64" # (2)!
          - "5.15-20250616.013250-amd64"
          - "5.10-20250610.043823-amd64"
          
    timeout-minutes: 10
    steps:

        # (3)!
      - run: | 
          wget --quiet https://github.com/cilium/ebpf/raw/refs/heads/main/examples/cgroup_skb/bpf_bpfel.o  
          ls -lah
      # (4)!
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

            echo ""
            sudo bpftool prog load ./bpf_bpfel.o /sys/fs/bpf/test && echo "Load Success"

```

1. Visit [here](https://quay.io/repository/lvh-images/kind?tab=tags) for getting kernel tags
2. List of kernel images to test against.
3. Downloading the eBPF object to load
4. !!! note
    1. Using LVH to provision virtual-machine with given kernel
    2. Mounting the `$PWD` inside VM at `/host`
    3. Loading the program




## Refer

- [https://github.com/cilium/little-vm-helper](https://github.com/cilium/little-vm-helper)
- [https://github.com/cilium/little-vm-helper-images/blob/main/_data/images.json](https://github.com/cilium/little-vm-helper-images/blob/main/_data/images.json)
- :arrow_right: [https://quay.io/repository/lvh-images/kind?tab=tags](https://quay.io/repository/lvh-images/kind?tab=tags)
- [https://github.com/h0x0er/ebpf-playground](https://github.com/h0x0er/ebpf-playground)
- [https://github.com/cilium/ebpf](https://github.com/cilium/ebpf)