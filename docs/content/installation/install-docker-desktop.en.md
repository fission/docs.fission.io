---
title: "Fission on Docker for Desktop"
draft: false
weight: 4
chapter : false
alwaysopen: false
---

## Cluster preliminaries

### Kubernetes CLI

Ensure you have the Kubernetes CLI.

You can get the Kubernetes CLI for OSX like this:
```bash
$ curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/darwin/amd64/kubectl && chmod +x kubectl && sudo mv kubectl /usr/local/bin
```

Or, for Linux:
```bash
$ curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl && chmod +x kubectl && sudo mv kubectl /usr/local/bin
```

### Docker desktop with Kubernetes

[Docker desktop](https://www.docker.com/products/docker-desktop) allows you to run and manage Docker and Kubernetes on workstations for local development. This tutorial will walk through setting up and using Fission on Docker for desktop and known issues and workarounds.


You will need to enable Kubernetes by going to Kubernetes tab in preferences. If you are doing this first time then the downloading of Kubernetes binaries will take a few minutes. Once Kubernetes is fully running - you should see green icon and the text "Kubernetes is running" as shown in screenshot below.

![](../../images/docker-desktop.png)

It should also configure Kubectl installed on your machine. For more details check documentation specific to [Docker for Windows](https://docs.docker.com/docker-for-windows/) or [Docker for Mac](https://docs.docker.com/docker-for-mac/)

```bash
$ kubectl version
```

We will need at least Kubernetes 1.9.

## Installing Fission

See [Fission installation](../../installation/) to learn more how to install fission.

## Docker for Dekstop specific differences

### Accessing Routes

If you look at router service - it is exposed as NodePort on host machine at port 30657 (The port will vary on your setup).

```bash
$ kubectl get svc -nfission
NAME                                    TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE
redis                                   ClusterIP      10.107.204.96    <none>        6379/TCP       23h
router                                  LoadBalancer   10.107.150.176   localhost     80:30657/TCP   23h
storagesvc                              ClusterIP      10.108.227.253   <none>        80/TCP         23h
```

So if we create a route to function, we should be able to access it as shown below:

```bash
$ fission route create --name helloscale --function helloscale --url helloscale
trigger 'helloscale' created

$ curl http://localhost:30657/helloscale
curl: (7) Failed to connect to localhost port 30657: Connection refused
```

But that fails because the [Docker Desktop has an issue](https://github.com/docker/for-mac/issues/2445) on Mac which does not setup routes properly. To work around this - you will have to port-forward the router and then use HTTP URL to access the function like this:

```bash
$ kubectl port-forward svc/router 9090:80
Forwarding from 127.0.0.1:9090 -> 8888
Forwarding from [::1]:9090 -> 8888

$ curl http://localhost:9090/helloscale
hello, world!
```

### Autoscaling

Docker for desktop by default does not ship with metric server. So if you create a function of newdeployment executor type, you will see that autoscaling does not work as expected. This is because the HPA does not get actual consumption of pods and the value remains <unknown>. This can be fixed by installing the metric server.

```bash
$ kubectl get hpa -nfission-function
NAME                                    REFERENCE                                          TARGETS         MINPODS   MAXPODS   REPLICAS   AGE
newdeploy-helloscale-default-ql0uqiwp   Deployment/newdeploy-helloscale-default-ql0uqiwp   <unknown>/50%   1         6         1          20h
```

To install the metric server, clone the repo https://github.com/kubernetes-incubator/metrics-server and change the metric-server's command to use insecure certificates in YAMLs in deploy directory.

``` yaml
      containers:
      - name: metrics-server
        image: k8s.gcr.io/metrics-server-amd64:v0.3.3
        command:
          - /metrics-server
          - --kubelet-insecure-tls
```
Once you have changed the command create the metric server by applying the manifests:


```bash
$ kubectl apply -f 1.8+
clusterrole.rbac.authorization.k8s.io/system:aggregated-metrics-reader created
clusterrolebinding.rbac.authorization.k8s.io/metrics-server:system:auth-delegator created
rolebinding.rbac.authorization.k8s.io/metrics-server-auth-reader created
apiservice.apiregistration.k8s.io/v1beta1.metrics.k8s.io created
serviceaccount/metrics-server created
deployment.extensions/metrics-server created
service/metrics-server created
clusterrole.rbac.authorization.k8s.io/system:metrics-server created
clusterrolebinding.rbac.authorization.k8s.io/system:metrics-server created
```

After a few minutes you can validate that metric server is working by running command:

```bash
$ kubectl top node
NAME                 CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
docker-for-desktop   662m         16%    1510Mi          79%
```

You will also notice that HPA has picked up the values from pod and now you can do autoscaling!

```bash
$ kubectl get hpa -nfission-function
NAME                                    REFERENCE                                          TARGETS         MINPODS   MAXPODS   REPLICAS   AGE
newdeploy-helloscale-default-gkxdkl8y   Deployment/newdeploy-helloscale-default-gkxdkl8y   20%/50%   1         6         1          48s
```

Even after installing metric server if the HPA does not show the current usage of pod - please check if you have given limit as well as request limit for CPU while creating function:

```bash
$ fission fn create --name helloscale --env nodescale  --code hello.js --executortype newdeploy --minmemory 64 --maxmemory 128 --mincpu 100 --maxcpu 500 --minscale 1 --maxscale 6  --targetcpu 50
```
For more details on autoscaling please [check this section of documentation](https://docs.fission.io/usage/executor/#autoscaling)
