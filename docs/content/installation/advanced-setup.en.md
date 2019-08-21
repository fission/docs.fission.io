---
title: Advanced Setup
draft: false
weight: 3
---

In this guide you will learn how to setup fission in order to serve heavy workloads on production systems.

## Define correct resource request/limits

By default, there is no resource requests/limits setting for fission component pods. But it's always wise set them up 
if you're trying to running any application on Kubernetes for production. We recommend that you run benchmarks to 
simulate real traffic and setup resource request/limits of components accordingly.

You can get component pods resource usage by using the following command.

```bash
$ kubectl -n fission top pod
```

And follow the [guide](https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/) to setup components' deployment.

## Create HPA for router

**NOTE**: You have to set up resource requests/limits for router before creating HPA.

The router is the entry point of all functions. It accepts, verifies and redirects requests to corresponding function pods.
As workload goes higher, router consumes more resources than idle state and users may experience higher latency. 
To prevent this, you have to `scale the replicas of router` based on your use case. However, in real world cases, 
the workload goes up and down in different time slot and it's not realistic to give a fixed number of replicas

`Horizontal Pod Autoscaler` a.k.a `HPA` is the way for Kubernetes to scale the replicas of a deployment based 
on the overall resource utilization across pods. Once HPA created, Kubernetes will then scale 
in/out the replicas of router automatically.
 
Visit [HPA documentation](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/) 
to know how to setup HPA for router deployment.

## Enable Keep-Alive setting in router

**NOTE**: Require 1.4.0+

Keep-Alive allows to use existing connections to send requests without creating a new one and lower the latency for subsequent
requests. However, it also limits the ability to distribute traffic to new pods since existing connections remain connected to old pods

![Keep-Alive](../assets/keep-alive-explain.png)

As shown in the figure above, the router tries to send requests to v1 function pod even after v2 is up. Only when the v1 function pod
is terminated, router will then re-establish connections to v2. (See [issue](https://github.com/fission/fission/issues/723#issuecomment-395483957) here)

You can enable Keep-Alive by setting environment variable as follows at router deployment.

```yaml
env:
- name: ROUTER_ROUND_TRIP_DISABLE_KEEP_ALIVE
  value: "false"
``` 

Couple things worth noticing:

1. This setting increases time for router(s) to switch to newer version for functions that use newdeploy as executor type. 
You can prevent this by setting short grace period (`--graceperiod`) when creating environment.
2. There is an increase in memory consumption of router to keep all active connections.

## Setup SSL/TLS for functions

Since fission router is not responsible to handle the encrypted traffic to functions, you should put 
fission routers behind any existing proxy solution like [NGINX](https://www.nginx.com/blog/nginx-ssl/), 
[Caddy](https://caddyserver.com/) or [Ambassador](https://github.com/datawire/ambassador) that helps to handle SSL/TLS 
connections.

```bash
Client --- SSL/TLS ---> Proxy ------> Router ------> Function  
```

Also, you can configure proxy upstream setting to avoid exposing the real URL route path of fission function to router to the public network.

```bash
Client --- /bar ---> Proxy --- /foo/bar ---> Router  
```
