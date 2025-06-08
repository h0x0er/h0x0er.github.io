---
title: Kubernetes
icon: material/kubernetes
---

!!! note "Official Doc"
    https://kubernetes.io/docs/tasks/debug/debug-cluster/

#### :arrow_right: for debugging node with privileged pod

```bash linenums="1"
kubectl debug node/mynode -it --image=ubuntu --profile=sysadmin
```

- [Refer](https://kubernetes.io/docs/tasks/debug/debug-cluster/kubectl-node-debug/)

#### :arrow_right: for debugging node with crictl

- [Refer](https://kubernetes.io/docs/tasks/debug/debug-cluster/crictl/)