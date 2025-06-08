---
date: 2025-06-08
more: "To understand ebpf tails calls"
authors:
 - jatin
categories:
 - ebpf
---

# eBPF: Tail calls (Part-2)


### Objective

- to understand/learn passing data between tail-called functions

<!-- more -->
!!! note "Why ?"
    There are use-cases where tail-called function must know processing performed in previous function.



### Reasoning

To share data among tail-called functions, we take advantage of the fact that, they are executed by same-cpu.

Refer [previous post](./ebpf-tail-calls.md) to understand performing tail-calls.

The additional things needed are:

- A `PERCPU_ARRAY` map
- A `tail_context` struct

When initial function is triggered, 

- Query the `PERCPU_ARRAY` map value at index 0 for `tail_context`
- Reset the `tail_context` using `__builtin_memset`
- Populate new values in `tail_context`

When subsequent tail-functions are triggered

- Query the `PERCPU_ARRAY` map value at index 0 for `tail_context`
- Use/Populate values from `tail_context`

### Code


```c title="programs.h" linenums="1"

#include "maps.h"

u8 ZERO = 0;


SEC("cgroup_skb/egress")
long egress3(struct __sk_buff* ctx){
    bpf_printk("[egress3] Someone called me");

    // Query tail_context
    struct tail_context* ctx2 = (struct tail_context*)bpf_map_lookup_elem(&tail_context_map, &ZERO);
    if(!ctx){
        return SK_PASS;
    }

    // Use tail_context values
    bpf_printk("[egress3] first=%d second=%d", ctx2->value_from_1, ctx2->value_from_1);

    return SK_PASS;
}

SEC("cgroup_skb/egress")
long egress2(struct __sk_buff* ctx){


    // Query tail context
    struct tail_context* ctx2 = (struct tail_context*)bpf_map_lookup_elem(&tail_context_map, &ZERO);
    if(!ctx){
        return SK_PASS;
    }

    // Populate tail_context
    ctx2->value_from_2 = 22;

    bpf_printk("[egress2] Calling egress3");
    bpf_tail_call(ctx, &tail_programs, TAIL_CALL_EGRESS_3)
    return SK_PASS;
}


// Initial function
SEC("cgroup_skb/egress")
long egress1(struct __sk_buff* ctx){


    // Query tail context
    struct tail_context* ctx2 = (struct tail_context*)bpf_map_lookup_elem(&tail_context_map, &ZERO);
    if(!ctx){
        return SK_PASS;
    }
    
    // Reset tail context
    __builtin_memset(ctx2, 0, sizeof(struct tail_context));

    ctx2->value_from_1 = 11;

    bpf_printk("[egress1] Calling egress2");
    bpf_tail_call(ctx, &tail_programs, TAIL_CALL_EGRESS_2)
    return SK_PASS;
}

```


```c title="maps.h" linenums="1"

// declare the index in array to use for tail-called function
#define TAIL_CALL_EGRESS_2 0 
#define TAIL_CALL_EGRESS_3 1 


// declare the prototype of function to be stored
long egress2(struct __sk_buff* ctx);
long egress3(struct __sk_buff* ctx);


// create map & initialize values
struct {
	__uint(type, BPF_MAP_TYPE_PROG_ARRAY);
	__uint(max_entries, 1);
	__type(key, __u32);
	__array(values, long(struct __sk_buff* ctx));
} tail_programs SEC(".maps") = {
	.values = {
		[TAIL_CALL_EGRESS_2] = (void *)&egress2, 
		[TAIL_CALL_EGRESS_3] = (void *)&egress3,

        
	},
};  

// Custom tail_contxt
struct tail_context{
    u8 value_from_1;
    u8 value_from_2;
}

// Every CPU has its own private copy of this map
struct {
	__uint(type, BPF_MAP_TYPE_PERCPU_ARRAY);
	__uint(max_entries, 1);
	__type(key, __u32);
	__type(value, struct tail_context);
} tail_context_map SEC(".maps") 


```

### Observations

- `PERCPU_ARRAY` map has only 1 entry
- Reset on `tail_context` is performed only initially


### Refer

- https://docs.ebpf.io/linux/map-type/BPF_MAP_TYPE_PERCPU_ARRAY/
- https://docs.ebpf.io/linux/program-type/BPF_PROG_TYPE_CGROUP_SKB/
- https://docs.ebpf.io/linux/concepts/tail-calls/