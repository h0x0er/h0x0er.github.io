## [gojue/ecapture](https://github.com/gojue/ecapture)

- [ISSUE-443:](https://github.com/gojue/ecapture/issues/433) Investigated memory-leak occurring in creating perCPUBuffer for eBPF sensors

- [PR-438:](https://github.com/gojue/ecapture/pull/438) Reduced memory consumption in OPENSSL version detection logic by refactoring the existing logic to use fixed-buffer.

- [PR-426:](https://github.com/gojue/ecapture/pull/426) Implemented support for capturing HTTPS traffic from stripped Go binaries resulting in improved inspection of traffic.
  
- [PR-418:](https://github.com/gojue/ecapture/pull/418) Implemented support for decoding kernel-time received from eBPF event to user-time resulting in accurate event-timestamp.




---

## [ossf/scorecard](https://github.com/ossf/scorecard})

- [PR-2278:](https://github.com/ossf/scorecard/pull/2278) Investigated and fixed a bug causing miscalculation of scores for private GitHub repositories.

--- 

## [ossf/package-analysis](https://github.com/ossf/package-analysis)

- [PR-978:](https://github.com/ossf/package-analysis/pull/978) Refactored static-analysis result struct to include SHA256 checksum of the target archive