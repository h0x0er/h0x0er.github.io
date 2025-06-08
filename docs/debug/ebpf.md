---
icon: material/bee-flower
title: eBPF
---

#### :arrow_right: for grabbing bpftool

When `sudo apt install bpftool` doesn't work 

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


#### :arrow_right: for `bpf_printk()` logs

```bash linenums="1"
# to clear previous logs
sudo echo > /sys/kernel/debug/tracing/trace

# print logs
sudo cat /sys/kernel/debug/tracing/trace_pipe
```

- [Refer](https://unix.stackexchange.com/questions/747990/how-to-clear-the-sys-kernel-debug-tracing-trace-pipe-quickly)


---
