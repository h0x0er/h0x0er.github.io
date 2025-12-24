---
hide:
    - footer
    - toc
---

# **Experiences**

## **Software Engineer (Full-time) | [StepSecurity Inc.](https://www.stepsecurity.io/company)**


> :timer: **July-2023 to Present**

    
- Designed and owned eBPF‑based runtime agents that monitor process execution, DNS/IP‑level network activity, and file operations in
CI/CD environments, and enforce runtime policies at DNS and IP levels to mitigate real‑world supply‑chain attacks.

- Implemented HTTPS traffic inspection subsystem using eBPF and Go in Kubernetes‑DaemonSet for intercepting plaintext traffic from
OpenSSL, GnuTLS, Node.js and Go binaries without modifying the target application.

-  Developed `eBPF-based armour` to detect/protect security-agents from tampering attacks.
 
- Developed a Kubernetes DaemonSet to deploy production eBPF‑based runtime security on [ARC-based](https://github.com/actions/actions-runner-controller) self‑hosted GitHub Actions runners, monitoring process, file, and network activity and enforcing DNS and network‑level policies using Cilium and Tetragon.
  
- Maintaining [Harden-Runner](https://github.com/step-security/harden-runner).
  
---

## **Software Developer (Part-Time) | [StepSecurity Inc.](https://www.stepsecurity.io/company)**

> :timer: **April-2022 to June-2023**


- Developed pattern‑based detection signatures on HTTPS telemetry to trigger real‑time alerts for anomalous CI/CD runner activity via
email and Slack.

- Implemented `eBPF-based` HTTPS traffic interception capability in agent.

- Automated supply‑chain security best practices across GitHub Actions workflows, including dependency pinning (SHA256), least‑
privilege GITHUB_TOKEN permissions, and CodeQL scanning, significantly reducing CI/CD attack surface.

- Implemented end‑to‑end integration tests to early catch regressions/errors in runtime‑security agent resulting in increased velocity of
feature development and cutting new‑releases.

- Started contributing to [Harden-Runner](https://github.com/step-security/harden-runner).

<!-- - Continued maintenance work on [runtime security agent](https://github.com/step-security/agent/pulls?q=is%3Apr+is%3Aclosed+author%3Ah0x0er) for CI/CD runners. -->
---

## **Software Developer (Intern) | [StepSecurity Inc.](https://www.stepsecurity.io/company)**


> :timer: **January-2022 to March-2022**

- Developed a [static analysis tool](https://github.com/step-security/secure-repo/tree/main/kbanalysis) using TypeScript, Node.js, and GitHub Actions to determine GITHUB_TOKEN permissions required by
third‑party actions, reducing manual analysis time by up to 80%.

- Performed source‑code analysis of 50+ open‑source GitHub Actions to assess and document token permission requirements.


- Contributed [15+ pull requests](https://github.com/actions/starter-workflows/pulls?q=is%3Apr+is%3Aclosed+author%3Ah0x0er) to [GitHub Actions starter workflows](https://github.com/actions/starter-workflows), enforcing least‑privilege token permissions and improving security
of downstream CI/CD usage.

