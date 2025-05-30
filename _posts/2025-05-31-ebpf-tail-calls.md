---
layout: post
title: "eBPF: Tail Calls"
description: "Doing tail calls in eBPF"
tags: ebpf
minute: 1
---

### Snippet

```c

// === program.h

SEC("cgroup_skb/egress")
long egress2(struct __sk_buff* ctx){
    bpf_printk("[egress2] Someone called me");
    return SK_PASS;
}

SEC("cgroup_skb/egress")
long egress1(struct __sk_buff* ctx){
    bpf_printk("[egress1] Calling egress2");
    bpf_printk(ctx, &tail_programs, TAIL_CALL_EGRESS_2)
    return SK_PASS;
}

// ==end


// ==== maps.h

// declare the index in array to use for tail-called function
#define TAIL_CALL_EGRESS_2 0 

// declare the prototype of function to be stored
long egress2(struct __sk_buff* ctx);

// create map & initialize values
struct {
	__uint(type, BPF_MAP_TYPE_PROG_ARRAY);
	__uint(max_entries, 1);
	__type(key, __u32);
	__array(values, long(struct __sk_buff* ctx)); // signature of function
} tail_programs SEC(".maps") = {
	.values = {
		[TAIL_CALL_EGRESS_2] = (void *)&egress2, // filling values
	},
};

// === end


```


### Refer
- https://docs.ebpf.io/linux/helper-function/bpf_tail_call/

- real_world_example: https://github.com/cilium/tetragon/blob/c51dd078bfb568075ba1fb287f2447f29f709073/bpf/process/bpf_generic_rawtp.c#L27-L45
