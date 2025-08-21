---
title: Kubernetes
icon: material/kubernetes
---

!!! note "Official Doc"
    <https://kubernetes.io/docs/tasks/debug/debug-cluster/>

#### for debugging node with privileged pod

```bash linenums="1"
nodeName=$(kubectl get node -o name)
kubectl debug $nodeName -it --image=ubuntu --profile=sysadmin
```

- <https://kubernetes.io/docs/tasks/debug/debug-cluster/kubectl-node-debug/>

#### for debugging node with crictl

- <https://kubernetes.io/docs/tasks/debug/debug-cluster/crictl/>



#### for exploring specs

- <https://kubespec.dev/>
