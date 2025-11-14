---
icon: material/bee-flower
---

# **eBPF**

#### for grabbing bpftool

When `sudo apt install bpftool` doesn't work 

```sh linenums="1"

# For latest build follow below link
# https://github.com/libbpf/bpftool/releases

wget https://github.com/libbpf/bpftool/releases/download/v7.5.0/bpftool-v7.5.0-amd64.tar.gz
tar xf bpftool*
chmod +x ./bpftool
./bpftool

```


#### for loading program

```sh linenums="1"

sudo mount -t bpf bpffs /sys/fs/bpf
sudo bpftool prog load ./sample.o /sys/fs/bpf/sample

```


#### for reading logs

```sh linenums="1"

# with bpftool
sudo bpftool prog tracelog

# for k8s-debug pod
echo > /host/sys/kernel/debug/tracing/trace
cat /host/sys/kernel/debug/tracing/trace_pipe

```

- <https://unix.stackexchange.com/questions/747990/how-to-clear-the-sys-kernel-debug-tracing-trace-pipe-quickly>


#### for ebpf-lsm & kprobe-override status

```sh linenums="1"

# for ebpf-lsm
cat /sys/kernel/security/lsm

# for override
cat /boot/config-`uname -r` | grep CONFIG_BPF_KPROBE_OVERRIDE

```


#### for observing performance of hooks/programs

- <https://github.com/Netflix/bpftop>


#### for CO-RE guide

- <https://nakryiko.com/tags/bpf/>


#### for checking available features

```bash linenums="1"

sudo bpftool feature

```

---
