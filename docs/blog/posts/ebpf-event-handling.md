---
date: 
 created: 2025-07-26
authors:
 - jatin
categories:
 - ebpf
---

# eBPF: Handling events in Userspace


## Objective

- to understand how eBPF-events are being handled in userspace in various open-source projects
    - to learn their patterns for handling massive amount of events

??? Note
    Currently only [tetragon](https://github.com/cilium/tetragon) project is covered.

<!-- more -->

## Reasoning


Once eBPF-events are written by the kernel-space hook in `ringBuffer or perfBuffer`, they become available for consumption from user-space.

Following steps are usually performed in user-space code;

1. **Preparation** of ringBuffer / perfBuffer reader
2. **Reading** of records from buffer
3. **Processing** of raw-samples


### Tetragon

#### Preparation

PerfEvent reader is prepared from pinned perf-map. **[[Source]](https://github.com/cilium/tetragon/blob/d121dc153b1227cd3670a0e915ecc903d2f4913c/pkg/observer/observer_linux.go#L61)**

```go linenums="1" title="snippet.go"  hl_lines="3 10"
...
	pinOpts := ebpf.LoadPinOptions{}
	perfMap, err := ebpf.LoadPinnedMap(k.PerfConfig.MapName, &pinOpts)
	if err != nil {
		return fmt.Errorf("opening pinned map '%s' failed: %w", k.PerfConfig.MapName, err)
	}
	defer perfMap.Close()

	rbSize := k.getRBSize(int(perfMap.MaxEntries()))
	perfReader, err := perf.NewReader(perfMap, rbSize)

...
```

#### Reading

A goroutine is launched;

- to read records from perfReader that adds them to `eventsQueue` (a buffered-channel). 
 
**[[Source]](https://github.com/cilium/tetragon/blob/d121dc153b1227cd3670a0e915ecc903d2f4913c/pkg/observer/observer_linux.go#L82-L119)**

```go linenums="1" title="snippet2.go"  hl_lines="5 20 31"

...

	// We spawn go routine to read and process perf events,
	// connected with main app through eventsQueue channel.
    eventsQueue := make(chan *perf.Record, k.getRBQueueSize())


    // Listeners are ready and about to start reading from perf reader, tell
    // user everything is ready.
    k.log.Info("Listening for events...")


    // Start reading records from the perf array. Reads until the reader is closed.
    var wg sync.WaitGroup
    wg.Add(1)
    defer wg.Wait()
    go func() {
            defer wg.Done()
            for stopCtx.Err() == nil {
                    record, err := perfReader.Read()
                    if err != nil {
                            // NOTE(JM and Djalal): count and log errors while excluding the stopping context
                            if stopCtx.Err() == nil {
                                    RingbufErrors.Inc()
                                    errorCnt := getCounterValue(RingbufErrors)
                                    k.log.Warn("Reading bpf events failed", "errors", errorCnt, logfields.Error, err)
                            }
                    } else {
                            if len(record.RawSample) > 0 {
                                    select {
                                    case eventsQueue <- &record:
                                    default:
                                            // eventsQueue channel is full, drop the event
                                            queueLost.Inc()
                                    }
                                    RingbufReceived.Inc()
                            }


                            if record.LostSamples > 0 {
                                    RingbufLost.Add(float64(record.LostSamples))
                            }
                    }
            }
    }()

...

```


Another goroutine is launched;

- for reading records from eventsQueue, where they are passed to `receiveEvent()` for processing
 
**[[Source]](https://github.com/cilium/tetragon/blob/d121dc153b1227cd3670a0e915ecc903d2f4913c/pkg/observer/observer_linux.go#L121-L137)**

```go linenums="1" title="snippet3.go" hl_lines="9 10 11"

...

  // Start processing records from perf.
  wg.Add(1)
  go func() {
          defer wg.Done()
          for {
                  select {
                  case event := <-eventsQueue:
                          k.receiveEvent(event.RawSample)
                          queueReceived.Inc()
                  case <-stopCtx.Done():
                          k.log.Info("Listening for events completed.", logfields.Error, stopCtx.Err())
                          k.log.Debug(fmt.Sprintf("Unprocessed events in RB queue: %d", len(eventsQueue)))
                          return
                  }
          }
  }()


...


```

#### Processing

On calling `receiveEvent()`

- it converts raw-bytes to `events` by passing data to `HandlePerfData()`
- send events to various listeners

**[[Source]](https://github.com/cilium/tetragon/blob/500231c48fdbe567cf384acc2d2ece7763394632/pkg/observer/observer.go#L111-L134)**

```go linenums="1" title="snippet4.go" hl_lines="8 19 20 21"

func (k *Observer) receiveEvent(data []byte) {
        var timer time.Time
        if option.Config.EnableMsgHandlingLatency {
                timer = time.Now()
        }


        op, events, err := HandlePerfData(data)
        opcodemetrics.OpTotalInc(ops.OpCode(op))
        if err != nil {
                errormetrics.HandlerErrorsInc(ops.OpCode(op), err.kind)
                switch err.kind {
                case errormetrics.HandlePerfUnknownOp:
                        k.log.Debug("unknown opcode ignored", "opcode", err.opcode)
                default:
                        k.log.Debug("error occurred in event handler", "opcode", err.opcode, logfields.Error, err)
                }
        }
        for _, event := range events {
                k.observerListeners(event)
        }
        if option.Config.EnableMsgHandlingLatency {
                opcodemetrics.LatencyStats.WithLabelValues(strconv.FormatUint(uint64(op), 10)).Observe(float64(time.Since(timer).Microseconds()))
        }
}

```


On calling `HandlePerfData()`;

- it tries to find event-specific handler using `first-byte`
- calls the handler for parsing raw-bytes
  
**[[Source]](https://github.com/cilium/tetragon/blob/500231c48fdbe567cf384acc2d2ece7763394632/pkg/observer/observer.go#L87)**

```go linenums="1" title="snippet5.go" hl_lines="2 5 15" 

func HandlePerfData(data []byte) (byte, []Event, *HandlePerfError) {
        op := data[0]
        r := bytes.NewReader(data)
        // These ops handlers are registered by RegisterEventHandlerAtInit().
        handler, ok := eventHandler[op]
        if !ok {
                return op, nil, &HandlePerfError{
                        kind:   errormetrics.HandlePerfUnknownOp,
                        err:    fmt.Errorf("unknown op: %d", op),
                        opcode: op,
                }
        }


        events, err := handler(r)
        if err != nil {
                return op, events, &HandlePerfError{
                        kind:   errormetrics.HandlePerfHandlerError,
                        err:    fmt.Errorf("handler for op %d failed: %w", op, err),
                        opcode: op,
                }
        }
        return op, events, nil
}


```

## References
- <https://github.com/cilium/tetragon>
- <https://nakryiko.com/posts/bpf-ringbuf/>
- <https://docs.ebpf.io/linux/map-type/BPF_MAP_TYPE_RINGBUF/>
- <https://docs.ebpf.io/linux/map-type/BPF_MAP_TYPE_PERF_EVENT_ARRAY/>
- <https://www.kernel.org/doc/html/next/bpf/ringbuf.html>