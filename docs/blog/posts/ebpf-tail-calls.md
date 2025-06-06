---
date: 2025-05-31
authors:
 - jatin
categories:
 - ebpf
---

# eBPF: Tail Calls

### Objective

- to understand performing tail-calls in eBPF


### Code

```c title="programs.h" linenums="1"


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

```

```c title="maps.h" linenums="1"

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
```


### Reasoning

In order to perform tail calls, we need to

- declare `prototype` of funcs to call
- declare map: `prog_array map` with key=u32, values=signature_of_funcs 
- fill map:
    - can be done in userspace as well in kernelspace
- use `bpf_tail_call` to redirect flow to func of interest



### Observations

- same-context: caller and callee must have same ctx i.e program of same type
- no-new-stack: callee uses caller's stack
- no-return: callee doesn't returns to caller


### Refer

- https://docs.ebpf.io/linux/helper-function/bpf_tail_call/

- real_world_example: https://github.com/cilium/tetragon/blob/c51dd078bfb568075ba1fb287f2447f29f709073/bpf/process/bpf_generic_rawtp.c#L27-L45