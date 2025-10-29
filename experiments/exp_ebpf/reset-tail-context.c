// -------> sample tail-context
struct tail_context {
    bool f1;
    bool f2;
    u8 payload[512];
}

struct {
     __uint(type, BPF_MAP_TYPE_PERCPU_ARRAY);
     __type(key, u32);
     __type(value, struct tail_context);
     __uint(max_entries, 1);
} tail_ctx_map SEC(".maps");
// --------


// data from below map is read only for resetting maps
struct null_bytes {
  u8 data[8192]; // maximum null_bytes
};

struct {
  __uint(type, BPF_MAP_TYPE_ARRAY);
  __type(key, u32);
  __type(value, struct null_bytes);
  __uint(max_entries, 1);
  __uint(map_flags,
         BPF_F_RDONLY_PROG | BPF_F_RDONLY); // makes the map read-only
} null_bytes_map SEC(".maps");


// using __builtin_memset
void reset_context1(struct tail_context* c){
    __builtin_memset(c, 0, 2); // reset only 2 bytes
}

u32 zero = 0;
void reset_context2(struct tail_context* c){
    
    __builtin_memset(c, 0, 2); // reset only 2 bytes

    struct null_bytes* nb = (struct null_bytes*)bpf_lookup_elem(&null_bytes_map, &zero);
    if(!nb){
        return;
    }
    // write null_bytes into payload
    bpf_probe_read_kernel(c->payload, 512, nb->data);
}