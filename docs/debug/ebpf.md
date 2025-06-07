---
icon: material/bee-flower
title: eBPF
---

#### :arrow_right: for grabbing bpftool

```bash linenums="1"

docker pull calico/bpftool

find /var/lib/docker/overlay2 -type f -iname "bpftool"

cp <path_from_previous_step> /usr/bin

chmod +x /usr/bin/bpftool

```


#### :arrow_right: for loading program

```bash linenums="1"

sudo mount -t bpf bpffs /sys/fs/bpf
sudo bpftool prog load ./sample.o /sys/fs/bpf/sample

```


---
