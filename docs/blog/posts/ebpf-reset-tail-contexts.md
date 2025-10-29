---
date: 2025-10-29
authors:
 - jatin
categories:
 - ebpf
---


# eBPF: Resetting tail-contexts


## Objective

to understand ways of resetting/zeroing the [perCPU contexts](./ebpf-tail-calls-2.md) used in tail-calls


<!-- more -->

---
## Reasoning

The `tail-context` must be zeroed before reusing it, to make sure values from previous executions are cleared. 

Following techniques can be used


1. Using `__builtin_memset()`
      - this fails to reset if size exceeds `1000-bytes`


2. By writing `null_bytes` in `tail-context`
      - requires additional `read-only` map containing null-bytes. 

3. Using `for-loop`
      - using this can sometimes lead to `instructions limit exceeded error`

## Snippets

### memset

```c linenums="1" title="memset.c"
--8<-- "./experiments/exp_ebpf/reset-tail-context.c:31:35"
```

### null_bytes

```c linenums="1" title="null_bytes.c"
--8<-- "./experiments/exp_ebpf/reset-tail-context.c:36:"
```


```c linenums="1" title="maps.c"
--8<-- "./experiments/exp_ebpf/reset-tail-context.c:1:29"
```

## TODO Experiment

- Use `bpf_loop` for zeroing the struct

