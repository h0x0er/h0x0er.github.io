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
    - to learn their approach for handling massive amount of events


<!-- more -->

???+ ":rocket: Featured in "
  	- Cilium's bi-weekly [eCHO News Episode #87](https://isovalent-9197153.hs-sites.com/echo-news-episode-87-tcp-in-udp-with-ebpf.-cilium-for-bare-metal)

## Reasoning


??? Note
    Snippets are take from  [cilium/tetragon](https://github.com/cilium/tetragon) and [aquasecurity/tracee](https://github.com/aquasecurity/tracee) projects.

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



### Tracee

As `Tracee` uses [libbpfgo](https://github.com/aquasecurity/libbpfgo) for loading eBPF objects, so there is a little difference in approach for `preparation and reading` of raw-data from perf/ring buffer. (extensive usage of go-channels)



#### Preparation

**[[Source]](https://github.com/aquasecurity/tracee/blob/23fdaf10bb100b97e89e98af4fe33a761dd2451a/pkg/ebpf/tracee.go#L1314-L1329)**

PerfBuffer is initialized with `eventsChannel` a buffered-channel for receiving raw-event bytes.

```go linenums="1" title="snippet.go" hl_lines="4 5 9 10 11 12 13 14" 
...
	// Initialize perf buffers and needed channels

	t.eventsChannel = make(chan []byte, 1000)
	t.lostEvChannel = make(chan uint64)
	if t.config.PerfBufferSize < 1 {
		return errfmt.Errorf("invalid perf buffer size: %d", t.config.PerfBufferSize)
	}
	t.eventsPerfMap, err = t.bpfModule.InitPerfBuf(
		"events",
		t.eventsChannel,
		t.lostEvChannel,
		t.config.PerfBufferSize,
	)
	if err != nil {
		return errfmt.Errorf("error initializing events perf map: %v", err)
	}
...

```


#### Reading / Decoding

**[[Source]](https://github.com/aquasecurity/tracee/blob/23fdaf10bb100b97e89e98af4fe33a761dd2451a/pkg/ebpf/events_pipeline.go#L31-L43)**


Then `handleEvents()` is launched in a separate goroutine for handling all perf-events:

- it further sends `eventsChannel` to [decodeEvents()](https://github.com/aquasecurity/tracee/blob/23fdaf10bb100b97e89e98af4fe33a761dd2451a/pkg/ebpf/events_pipeline.go#L168) 
    - that reads raw-events & decodes them 
    -  returns `eventsChan` for receiving decoded-events

```go linenums="1" title="snippet2.go" hl_lines="5 13" 

...
// handleEvents is the main pipeline of tracee. It receives events from the perf buffer
// and passes them through a series of stages, each stage is a goroutine that performs a
// specific task on the event. The pipeline is started in a separate goroutine.
func (t *Tracee) handleEvents(ctx context.Context, initialized chan<- struct{}) {
	logger.Debugw("Starting handleEvents goroutine")
	defer logger.Debugw("Stopped handleEvents goroutine")

	var errcList []<-chan error

	// Decode stage: events are read from the perf buffer and decoded into trace.Event type.

	eventsChan, errc := t.decodeEvents(ctx, t.eventsChannel)
	t.stats.Channels["decode"] = eventsChan
	errcList = append(errcList, errc)

	// Cache stage: events go through a caching function.

...

```

#### Processing

Events from `eventsChan` goes through several logical stages such as:

- container enrichment
- detection engine

finally all events are handled by `sink stage` for printing/logging.

**[[Source]](https://github.com/aquasecurity/tracee/blob/23fdaf10bb100b97e89e98af4fe33a761dd2451a/pkg/ebpf/events_pipeline.go#L43-L100)**

```go linenums="1" title="snippet3.go" hl_lines="3 10 18 24 30 31" 

	
	// Process events stage: events go through a processing functions.

	eventsChan, errc = t.processEvents(ctx, eventsChan)
	t.stats.Channels["process"] = eventsChan
	errcList = append(errcList, errc)

	// Enrichment stage: container events are enriched with additional runtime data.

	if !t.config.NoContainersEnrich { // TODO: remove safe-guard soon.
		eventsChan, errc = t.enrichContainerEvents(ctx, eventsChan)
		t.stats.Channels["enrich"] = eventsChan
		errcList = append(errcList, errc)
	}


	// Derive events stage: events go through a derivation function.

	eventsChan, errc = t.deriveEvents(ctx, eventsChan)
	t.stats.Channels["derive"] = eventsChan
	errcList = append(errcList, errc)

	// Engine events stage: events go through the signatures engine for detection.

	if t.config.EngineConfig.Mode == engine.ModeSingleBinary {
		eventsChan, errc = t.engineEvents(ctx, eventsChan)
		t.stats.Channels["engine"] = eventsChan
		errcList = append(errcList, errc)
	}

	// Sink pipeline stage: events go through printers.
	errc = t.sinkEvents(ctx, eventsChan)
	t.stats.Channels["sink"] = eventsChan
	errcList = append(errcList, errc)


```

## References
- <https://github.com/cilium/tetragon>
- <https://github.com/aquasecurity/tracee>
- <https://nakryiko.com/posts/bpf-ringbuf/>
- <https://docs.ebpf.io/linux/map-type/BPF_MAP_TYPE_RINGBUF/>
- <https://docs.ebpf.io/linux/map-type/BPF_MAP_TYPE_PERF_EVENT_ARRAY/>
- <https://www.kernel.org/doc/html/next/bpf/ringbuf.html>