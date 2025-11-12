---
icon: fontawesome/brands/golang
title: Go
---

## Profiling

!!! note "Official Doc"
    https://pkg.go.dev/net/http/pprof

### to enable profile data-server

```go
import _ "net/http/pprof"
go func() {
	log.Println(http.ListenAndServe("localhost:6060", nil))
}()

```


### cpu-profile: 30s
```
go tool pprof "http://localhost:6060/debug/pprof/profile?seconds=30"
```

then to see topN methods, type
```
top5
```

for help, type
```
 help 
```

start web-server (make sure graphviz is installed)
```
go tool pprof -http=:8080 "http://localhost:6060/debug/pprof/profile?seconds=30"
```


### to access profiles: command-line

- https://pkg.go.dev/net/http/pprof#hdr-Usage_examples


### to access profiles: web-interface

Visit on browser
```
http://localhost:6060/debug/pprof/
```



### understand top command

- https://www.practical-go-lessons.com/chap-36-program-profiling#the-top-command

### refer


- about golang pprof: https://github.com/google/pprof/blob/main/doc/README.md
