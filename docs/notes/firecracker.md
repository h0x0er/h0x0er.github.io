# Firecracker VMM

Experiments with https://github.com/firecracker-microvm/firecracker


Follow most of the steps from `get-started` to spin-up a minimal VM

## to get-started with firecracker

- https://github.com/firecracker-microvm/firecracker/blob/main/docs/getting-started.md


## to undersand tuntap

- https://www.packetcoders.io/virtual-networking-devices-tun-tap-and-veth-pairs-explained/

##  to understand `ip route`

this is used for configuring networking inside VM

- <https://linuxvox.com/blog/linux-ip-route/>
- <https://man7.org/linux/man-pages/man8/ip-route.8.html>


## about `drives`

- for all drives, `a device-file under /dev` is created in inside VM
    - only `rootfs drive` is mounted automatically at `/`, 
    - rest of the drives are to be mounted manually
        - do `lsblk` to list all devices

- `path_on_host` can be either
    - `file-system image` created using `mkfs`,
    - `loop-device`, or any device. [[checkout]](./loop-device.md)



## run script

```sh linenums="1" title="run.sh"
--8<-- "./experiments/exp_firecracker/firecracker-run.sh"
```

## vm template

below template is used with `spin-vm` command in `run-script`


```json linenums="1" title="vm_template.json"
--8<-- "./experiments/exp_firecracker/vm_template.json"
```