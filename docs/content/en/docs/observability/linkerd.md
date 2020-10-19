---
title: "Observability with Linkerd"
weight: 20
---

# Oberservability with Linkerd
[Linkerd](linkerd.io) is a simple and flexible service mesh which can work out of the box with Fission. 
In this post, we'll take a look at how it can provide metrics for the functions deployed. 

# Setting up 
We need to install fission and linkerd in the cluster. 

## Prerequisites
- Install [linkerd](https://linkerd.io/2/getting-started/)
- Install [Fisson](https://docs.fission.io/docs/installation/)

## Deploy a function in Fission
- Create an environment:

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

- Create a route 

```
fission route create --function hello --url /hello --name=hello
```

- Setup the Fission router variable based on your cluster(minikube or cloud)

For cloud :
```
export FISSION_ROUTER=$(kubectl --namespace fission get svc router -o=jsonpath='{..ip}')
```

For minikube:
```
 export FISSION_ROUTER=$(minikube ip):$(kubectl -n fission get svc router -o jsonpath='{...nodePort}')

```

- Test the function

```
fission fn test --name hello
```

# Linkerd Dashboard
- Linkerd has an amazing dashboard which can be launched by:

```
linkerd dashboard &
```

![Linkerd dashboard](../assets/linkerd-dashboard.png)

- Under namespaces, select fission-function and check the exisiting deployments

![Linkerd before mesh](../assets/linkerd-before.png)



# Inject sidecar into deployment 

Linkerd injects a side car proxy to add the deployment to it's data plane

```
kubectl get -n  fission-function deploy -o yaml \
| linkerd inject - \
| kubectl apply -f -
```

We can check if the deployment is "meshed" i.e if the side car proxy is injected within the dashboard

![Linkerd after mesh](../assets/linkerd-after.png)

Notice the metrics like Request Per Second(RPS) and PX Latency


# Generate traffic and view the Grafana dashboard

Let's generate some traffic to the function by:

```
while true; do sleep 1; curl http://${FISSION_ROUTER}/hello; echo -e '\n\n\n\n'$(date);done 

```
We can now view the grafana dashboard near the deployments

![Linkerd Grafana](../assets/linkerd-grafana.png)

We can now visualize success rate, rate per requests and latency of functions at one place