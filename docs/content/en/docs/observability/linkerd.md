---
title: "Observability with Linkerd"
weight: 20
---

## Oberservability with Linkerd

[Linkerd](linkerd.io) is a simple and flexible service mesh which can work out of the box with Fission. 
In this post, we'll take a look at how it can provide metrics for the functions deployed and for Fission.

### Prerequisites

You need to install Fission and Linkerd in the cluster. 

- Install [Linkerd](https://linkerd.io/2/getting-started/)
- Install [Fisson](https://docs.fission.io/docs/installation/)

### Deploy a function in Fission

- Create a Fission environment:

```
fission env create --name node --image fission/node-env
```

- Create a file with function code:

```
module.exports = async function(context) {
    return {
        status: 200,
        body: "Hello, world!\n"
    };
}

```

- Deploy the function 

```
fission fn create --name hello --code hello.js --env node
```

- Test the function

```
fission fn test --name hello
```

## Linkerd Dashboard
- Linkerd has an amazing dashboard which can be launched by:

```
linkerd dashboard &
```

![Linkerd dashboard](../assets/linkerd-dashboard.png)

- Under namespaces, select fission-function and check the exisiting deployments

![Linkerd before mesh](../assets/linkerd-before.png)


## Inject sidecar into deployments

Linkerd injects a side car proxy to add the deployment to it's data plane. We can do this at namespace level so that all deployments in a namespace are meshed.

```
kubectl get -n  fission-function deploy -o yaml \
| linkerd inject - \
| kubectl apply -f -
```

We can check if the deployment is "meshed" i.e if the side car proxy is injected within the dashboard

![Linkerd after mesh](../assets/linkerd-after.png)

Notice the metrics like Request Per Second(RPS) and PX Latency

## Generate traffic and view metrics

Let's generate some traffic to the function by:

```
while true; do sleep 1; curl http://${FISSION_ROUTER}/hello; echo -e '\n\n\n\n'$(date);done 

```
We can now view the grafana dashboard near the deployments

![Linkerd Grafana](../assets/linkerd-grafana.png)

We can now visualize success rate, rate per requests and latency of functions at one place


## Observing Fission components

Similar to functions, we can also mesh the Fission namespace so that we can observe the Fission components. We can similarly use the Grafana dashboard to get details of other metrics.

```
kubectl get -n  fission deploy -o yaml \
| linkerd inject - \
| kubectl apply -f -
```

![Fission Components](../assets/fission-linkerd.png)