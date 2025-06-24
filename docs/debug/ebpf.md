---
icon: material/bee-flower
title: eBPF
---

#### :arrow_right: for grabbing bpftool

When `sudo apt install bpftool` doesn't work 

```bash linenums="1"

# For latest build follow below link
# https://github.com/libbpf/bpftool/releases

wget https://github.com/libbpf/bpftool/releases/download/v7.5.0/bpftool-v7.5.0-amd64.tar.gz
tar xf bpftool*
chmod +x ./bpftool
./bpftool

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

# for k8s-debug pod
echo > /host/sys/kernel/debug/tracing/trace
cat /host/sys/kernel/debug/tracing/trace_pipe

```

- [Refer](https://unix.stackexchange.com/questions/747990/how-to-clear-the-sys-kernel-debug-tracing-trace-pipe-quickly)


#### :arrow_right: for checking ebpf-lsm & kprobe-override status

```bash linenums="1"

# for ebpf-lsm
cat /sys/kernel/security/lsm

# for override
cat /boot/config-`uname -r` | grep CONFIG_BPF_KPROBE_OVERRIDE

```


---
