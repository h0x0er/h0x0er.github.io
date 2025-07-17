---
date: 
 created: 2025-06-29
 updated: 2025-07-10
authors:
 - jatin
categories:
 - ebpf
---

# eBPF: Connecting with Container Runtimes


## Objective

- to understand how connection with `Container Runtime (CR)` is being made using `Container Runtime Interface (CRI)` in different open-source eBPF-based projects.
    - to query `pod or container info` for context enrichment.


<!-- more -->

???+ ":rocket: Featured in "
  	- Cilium's bi-weekly [eCHO News Episode #86](https://isovalent-9197153.hs-sites.com/echo-news-episode-86-ebpf-networking-at-bytedance.-installing-cilium-on-eks)
  	- Hacker News [thread#44524430](https://news.ycombinator.com/item?id=44524430)
  

---

##  Reasoning

??? Note
    Code snippets are take from open-source [tetragon](https://github.com/cilium/tetragon), [tracee](https://github.com/aquasecurity/tracee) and [crictl](https://github.com/kubernetes-sigs/cri-tools/blob/master/docs/crictl.md) projects.

Connection with CR is important for making the tool/product kubernetes-aware. As it provides rich information that could be of interest for different use-cases.

Connection with CR involves following steps

- locate `unix-socket` file
- make a grpc connection using [CRI API](https://github.com/kubernetes/cri-api/blob/v0.33.1/pkg/apis/runtime/v1/api.proto)
- query the info


### Locate `unix-socket` file

??? tip
    Make sure to mount host `/var` or `/run` in container.


Most of the times these are in a well-known location such as `/var/run` or `/run`. Checkout CR documentation for exact location.


In projects that I explored, well-known paths are hardcoded for flexibility. 

During runtime, code iterate over these paths, tries to make a connection and returns the corresponding service, if it was success.

#### Tetragon

Tetragon contains some hardcoded default sock-paths. **[[Source]](https://github.com/cilium/tetragon/blob/50a1d08e471d2fdbabff0416ba0c314769bb4c13/pkg/cri/cri.go#L22)**
```go linenums="1"
	defaultEndpoints = []string{
		"unix:///run/containerd/containerd.sock",
		"unix:///run/crio/crio.sock",
		"unix:///var/run/cri-dockerd.sock",
	}

```

#### Crictl

**[Browse full source-code](https://github.com/kubernetes-sigs/cri-tools/blob/0cf370b13928d79146916fd9accbbc69f64a92b5/cmd/crictl/main_unix.go#L31)**

```go linenums="1"

var defaultRuntimeEndpoints = []string{"unix:///run/containerd/containerd.sock", "unix:///run/crio/crio.sock", "unix:///var/run/cri-dockerd.sock"}

```



#### Tracee

**[Browse full source-code](https://github.com/aquasecurity/tracee/blob/a675202eeef1bcf2ce269cb7493f35d769dbe367/pkg/containers/runtime/sockets.go#L42C1-L63C2)**

```go linenums="1"

func Autodiscover(onRegisterFail func(err error, runtime RuntimeId, socket string)) Sockets {
	register := func(sockets *Sockets, runtime RuntimeId, socket string) {
		err := sockets.Register(runtime, socket)
		if err != nil {
			onRegisterFail(err, runtime, socket)
		}
	}
	sockets := Sockets{}
	const (
		defaultContainerd = "/var/run/containerd/containerd.sock"
		defaultDocker     = "/var/run/docker.sock"
		defaultCrio       = "/var/run/crio/crio.sock"
		defaultPodman     = "/var/run/podman/podman.sock"
	)

	register(&sockets, Containerd, defaultContainerd)
	register(&sockets, Docker, defaultDocker)
	register(&sockets, Crio, defaultCrio)
	register(&sockets, Podman, defaultPodman)

	return sockets
}

```

### Making connection


#### Tetragon

**[Browse full source-code](https://github.com/cilium/tetragon/blob/50a1d08e471d2fdbabff0416ba0c314769bb4c13/pkg/cri/cri.go#L1-L89)**
```go linenums="1"

// required modules
import (
  	"google.golang.org/grpc"
  	"google.golang.org/grpc/credentials/insecure"
	 criapi "k8s.io/cri-api/pkg/apis/runtime/v1"
)

func newClientTry(ctx context.Context, endpoint string) (criapi.RuntimeServiceClient, error) {

	u, err := url.Parse(endpoint)
	if err != nil {
		return nil, err
	}
	if u.Scheme != "unix" {
		return nil, errNotUnix
	}

	conn, err := grpc.NewClient(endpoint,
		grpc.WithTransportCredentials(insecure.NewCredentials()),
	)
	if err != nil {
		return nil, err
	}

	rtcli := criapi.NewRuntimeServiceClient(conn)
	if _, err := rtcli.Version(ctx, &criapi.VersionRequest{}); err != nil {
		return nil, fmt.Errorf("validate CRI v1 runtime API for endpoint %q: %w", endpoint, err)
	}

	return rtcli, nil
}

```

#### Crictl

**[Browse full source-code](https://github.com/kubernetes-sigs/cri-tools/blob/0cf370b13928d79146916fd9accbbc69f64a92b5/cmd/crictl/main.go#L73)**

```go linenums="1"


// required modules
import(
  ...
  internalapi "k8s.io/cri-api/pkg/apis"
  remote "k8s.io/cri-client/pkg"
  ...
)

...
for _, endPoint := range defaultRuntimeEndpoints {
	logrus.Debugf("Connect using endpoint %q with %q timeout", endPoint, t)

	res, err = remote.NewRemoteRuntimeService(endPoint, t, tp, &logger)
	if err != nil {
		logrus.Error(err)

		continue
	}

	logrus.Debugf("Connected successfully using endpoint: %s", endPoint)

	break
}
...

```


#### Tracee


**[Browse full source-code](https://github.com/aquasecurity/tracee/blob/a675202eeef1bcf2ce269cb7493f35d769dbe367/pkg/containers/runtime/containerd.go#L26C1-L51C2)**

```go linenums="1"

func ContainerdEnricher(socket string) (ContainerEnricher, error) {
	enricher := containerdEnricher{}

	// avoid duplicate unix:// prefix
	unixSocket := "unix://" + strings.TrimPrefix(socket, "unix://")

	client, err := containerd.New(socket)
	if err != nil {
		return nil, errfmt.WrapError(err)
	}

	conn, err := grpc.NewClient(unixSocket, grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		if errC := client.Close(); errC != nil {
			logger.Errorw("Closing containerd connection", "error", errC)
		}
		return nil, errfmt.WrapError(err)
	}

	enricher.images_cri = cri.NewImageServiceClient(conn)
	enricher.containers = client.ContainerService()
	enricher.namespaces = client.NamespaceService()
	enricher.images = client.ImageService()

	return &enricher, nil
}

```

### Query the info


#### Tetragon 

Querying cgroup-path of a container. **[[Source]](https://github.com/cilium/tetragon/blob/50a1d08e471d2fdbabff0416ba0c314769bb4c13/pkg/cri/container.go#L85-L114)**

```go linenums="1"

func CgroupPath(ctx context.Context, cli criapi.RuntimeServiceClient, containerID string) (string, error) {

  // creating a request 
	req := criapi.ContainerStatusRequest{
		ContainerId: containerID,
		Verbose:     true,
	}

  // making grpc call
	res, err := cli.ContainerStatus(ctx, &req)
	if err != nil {
		return "", err
	}

  // taking the info
	info := res.GetInfo()
	if info == nil {
		return "", errors.New("no container info")
	}

  // extracting the relevant info

	var path, json string
	if infoJson, ok := info["info"]; ok {
		json = infoJson
		path = "runtimeSpec.linux.cgroupsPath"
	} else {
		return "", errors.New("could not find info")
	}

	ret := gjson.Get(json, path).String()
	if ret == "" {
		return "", errors.New("failed to find cgroupsPath in json")
	}

	return ParseCgroupsPath(ret)
}

```

---

#### Tracee

**[Browse full source-code](https://github.com/aquasecurity/tracee/blob/a675202eeef1bcf2ce269cb7493f35d769dbe367/pkg/containers/runtime/containerd.go#L53-L107)**

```go linenums="1" title="tracee-snippet.go"

func (e *containerdEnricher) Get(ctx context.Context, containerId string) (EnrichResult, error) {
	res := EnrichResult{}
	nsList, err := e.namespaces.List(ctx)
	if err != nil {
		return res, errfmt.Errorf("failed to fetch namespaces %s", err.Error())
	}
	for _, namespace := range nsList {
		// always query with namespace applied
		nsCtx := namespaces.WithNamespace(ctx, namespace)

		// if containers is not in current namespace, search the next one
		container, err := e.containers.Get(nsCtx, containerId)
		if err != nil {
			continue
		}

	....

		// if in k8s we can extract pod info from labels
		if container.Labels != nil {
			labels := container.Labels
			res.PodName = labels[PodNameLabel]
			res.Namespace = labels[PodNamespaceLabel]
			res.UID = labels[PodUIDLabel]
			res.Sandbox = e.isSandbox(labels)

			// containerd containers normally have no names unless set from k8s
			res.ContName = labels[ContainerNameLabel]
		}
		res.Image = imageName
		res.ImageDigest = imageDigest

		return res, nil
	}

	return res, errfmt.Errorf("failed to find container %s in any namespace", containerId)
}

```

---

## Refer

- <https://github.com/cilium/tetragon/blob/main/pkg/cri/cri.go>
- <https://github.com/cilium/tetragon/tree/main/pkg/cri>
- <https://github.com/kubernetes-sigs/cri-tools/blob/0cf370b13928d79146916fd9accbbc69f64a92b5/cmd/crictl/main.go#L73>
- <https://github.com/aquasecurity/tracee/tree/main/pkg/containers/runtime>


