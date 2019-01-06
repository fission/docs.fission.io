---
title: "Function Executors"
draft: false
weight: 23
---

A key aspect of performance latency in any high-throughput Serverless application is activation latency for incoming functions, since every single function effectively may require instantiation of a new container in a naive implementation.

That said, not all functions require low-latency: some functions may have a very long computationally intensive cold-start, which is amortized over an even longer running batch job time.

Thus, there is no single "optimal" way to optimize all functions for a broad spectrum of business problems which might be running in a serverless architecture, and so Fission provides you with a framework for defining not only _what_ is done (the *Function*), but also _how_  your functions are run.  This is known as the *Executor*.

This section walks through some of the finer implementation details of
this process, and introduces the concepts of *Executors*.

## Executors

All functions may not be created equally, and may have different
semantics when it comes to how they relate to their given execution *Environment*.

When you create a *Function*, you can specify its *Executor*.
An executor is the glue between a *Function* and its *Environment*.

An executor controls: 
- how a function pod is created.
- what capabilities are available for that executor type.

## Executor Types

There are different ways which you may want to provide an *Executor* to a function.  We will walk through the PoolMgr and Deployment based exeuctors, which offer a trade off between "low cost" and "low latency" which is described later.

### The PoolMgr: Reasonably low latency with extremely low idle cost.

If your cluster is larget (i.e. above 15 nodes or so), then downscaling it in off-peak times (for example, weekends) can easily can save thousands of dollars in cloud or infrastructure costs.  The *PoolMgr* is a *Function* executor which is ideally suited, with little tuning, to be able to leverage such functionality out of the box, without needing manual tuning or intervention.

### Environment Caching

Even in highly tuned clusters, it typically take 1 or more seconds for pods to spawn, and as bin packing becomes more efficient, this factor can rapidly increase to 10 or more seconds.  Thus scheduling without caching of Environments can be a huge performance disadvantage for any "pure" serverless implementation which has no persistent state at all.

## PoolMgr caches Environments (without immortalizing them)

Since continuously spwaning a new microservice for every function can become very costly from a latency perspective, Fission
creates pools of *warm* pods which can immediately execute any incoming function, and which can be scaled up and down based on load.

![poolmgr](../images/poolmgr.svg)

A pool based executor (Refered to as *Poolmgr*) creates `a pool of generic environment pods`, corresponding to an *Environment*, as soon as Environment is created.  These are "warm" pods, which can immediately
respond to run incoming *Functions* which are triggered by the fission router.

The "pool size" can be configured based on user needs. These warm containers contain a small dynamic loader for loading the function. Resource requirements are specified at environment level and are inherited by specialized function pods.

Once you create a function and invoke it, a pods from the corresponding pool is triaged and specialized as the *Executor* for that function. 

This pod is ephemeral: It is used for any subsequent requests, and if no new incoming requests occur given for a pre-defined duration, the pod is eliminated - hence, fulfilling the Serverless contract.

Any new incoming requests will simply result in respawning of a new *Exeuctor* pod for the given function.


### When should you use the PoolMgr Executor type ?

The Poolmgr executor type is great for functions where lower latency is a requirement. Poolmgr executor type has certain limitations: for example, you can not autoscale them based on demand.

## New-deployment Executor

At the heart of Kubernetes itself is the concept of a ReplicaSet, which provides a powerful way to gaurantee high availability of any Pod.  Although your Serverless framework implemented with a *PoolMgr* is a powerful abstraction, its worse case performance for a given request is the same as that of spawning a new microservice.  

![newdeploy](../images/newdeploy.svg)

New-Deployment executor (Refered to as Newdeploy) creates `a Kubernetes Deployment` along with `a Service and HorizontalPodAutoscaler(HPA)` for function execution. This enables autoscaling of function pods and load balancing the requests between pods. In future additional capabilities will be added for newdeploy executor type such as support for volume etc.  In the new-deploy executor, resource requirements can be specified at the function level. These requirements override those specified in the environment.

Newdeploy executor type can be used for requests with no particular low-latency requirements, such as those invoked asynchronously, minscale can be set to zero. In this case the Kubernetes deployment and other objects will be created on first invocation of the function. Subsequent requests can be served by the same deployment. If there are no requests for certain duration then the idle objects are cleaned up. This mechanism ensures resource consumption only on demand and is a good fit for asynchronous requests.

For requests where latency requirements are stringent, a minscale  greater than zero can be set. This essentially keeps a minscale number of pods ready when you create a function. When the function is invoked, there is no delay since the pod is already created. Also minscale ensures that the pods are not cleaned up even if the function is idle. This is great for functions where lower latency is more important than saving resource consumption when functions are idle.

### When should you use the New Deployment Executor type ?

The new deployment executor type is ideally suited for workloads that cannot tolerate any periodically high latency, even it if is infrequent.

Thus, for certain mission critical services you may want lower "worse case" latency, i.e. you may want your Serverless execution environment to perform as well a traditional, persistent microservice.

## The latency vs. idle-cost tradeoff

The executors allow you as a user to decide between latency and a small idle cost trade-off. Depending on the need you can choose one of the combinations which is optimal for your use case. In future, a more intelligent dispatch mechanism will enable more complex combinations of executors.

| Executor Type | Min Scale| Latency | Idle cost |
|:---------|:---------:|:---------:|:---------|
|Newdeploy|0|High|Very low - pods get cleaned up after idlle time|
|Newdeploy|>0|Low|Medium, Min Scale number of pods are always up|
|Poolmgr|0|Low|Low, pool of pods are always up|

## Autoscaling

The new deployment based executor provides autoscaling for functions based on CPU usage. In future custom metrics will be also supported for scaling the functions. You can set the initial and maximum CPU for a function and target CPU at which autoscaling will be triggered. Autoscaling is useful for workloads where you expect intermittant spikes in workloads. It also enables optimal the usage of resources to execute functions, by using a baseline capacity with minimum scale and ability to burst up to maximum scale based on spikes in demand.

{{% notice tip %}}
Learn more further usage/setup of **executor type** for functions, please see [here]({{%relref "usage/executor.en.md" %}})
{{% /notice %}}
