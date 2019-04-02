---
title: "Enabling Istio on Fission"
draft: false
weight: 62
---

This tutorial sets up Fission with [Istio](https://istio.io/) - a service mesh for Kubernetes. The tutorial was tried on GKE but should work on any equivalent setup. We will assume that you already have a Kubernetes cluster setp and working.


### Set up Istio

For installing Istio, please follow the setup guides [here](https://istio.io/docs/setup/kubernetes/install/). You can use a setup that works for you, we used the Helm install for Istio for this tutorial as [detailed here](https://istio.io/docs/setup/kubernetes/install/helm/)


### Install fission

Set default namespace for helm installation, here we use `fission` as example namespace.

```bash
$ export FISSION_NAMESPACE=fission
```

Create namespace & add label for Istio sidecar injection, this will ensure that the the Istio sidecar is auto injected with Fission pods.

```bash
$ kubectl create namespace $FISSION_NAMESPACE
$ kubectl label namespace $FISSION_NAMESPACE istio-injection=enabled
$ kubectl config set-context $(kubectl config current-context) --namespace=$FISSION_NAMESPACE
```

Follow the [installation guide](../../installation/) to install fission with flag `enableIstio` true.

```bash
$ helm install --namespace $FISSION_NAMESPACE --set enableIstio=true --name istio-demo <chart-fission-all-url>
```

### Create & test a function

Let's first create the environment for nodejs function we want to create:

```bash
$ fission env create --name nodejs --image fission/node-env:latest
```

Let's create a simple function with Node.js environment and a simple hello world example below:

```js
# hello.js
module.exports = async function(context) {
    console.log(context.request.headers);
    return {
        status: 200,
        body: "Hello, World!\n"
    };
}
```

```bash
$ fission fn create --name h1 --env nodejs --code hello.js --method GET
```

Now let's create route for the function

```bash
$ fission route create --method GET --url /h1 --function h1
```

Access function

```bash
$ curl http://$FISSION_ROUTER/h1
Hello, World!
```

### Under the hood

Now that a Fission function did work with Istio, let's check under the hood see how Istio is interacting with system seamlessly. After installation, you will see that all components such as executor, router etc. now have an additional sidecar for istio-proxy and they also had a istio-init as a init container.

```
$ kubectl get pods -nfission
NAME                                                     READY     STATUS             RESTARTS   AGE
buildermgr-86858f4f6c-drhlv                              2/2       Running            0          7m
controller-78cbdfc4fb-vdjsj                              2/2       Running            0          7m
executor-97c7fc96d-9tclp                                 2/2       Running            1          7m

```

```
  containers:
    name: executor
...
...
    image: docker.io/istio/proxyv2:1.0.6
    imagePullPolicy: IfNotPresent
    name: istio-proxy
```

Also all function pods now have 3 containers - the function container, fetcher and now additionally the the istio-proxy container and we can see the istio-proxy logs for function containers.

```
$ kubectl get pods -nfission-function
NAME                                                READY     STATUS    RESTARTS   AGE
newdeploy-hello-default-mmrlkoog-557678fdcd-gw7tz   3/3       Running   2          9m
poolmgr-node-default-esibbicv-65488fbc4d-2hdzc      3/3       Running   0          9m

$ kubectl $ff logs -f newdeploy-hello-default-mmrlkoog-557678fdcd-gw7tz -c istio-proxy
2019-04-02T17:02:42.944608Z info    Version root@464fc845-2bf8-11e9-b805-0a580a2c0506-docker.io/istio-1.0.6-98598f88f6ee9c1e6b3f03b652d8e0e3cd114fa2-Clean
2019-04-02T17:02:42.944647Z info    Proxy role: model.Proxy{ClusterID:"", Type:"sidecar", IPAddress:"10.16.62.23", ID:"newdeploy-hello-default-mmrlkoog-557678fdcd-gw7tz.fission-function", Domain:"fission-function.svc.cluster.local", Metadata:map[string]string(nil)}
2019-04-02T17:02:42.944966Z info    Effective config: binaryPath: /usr/local/bin/envoy
configPath: /etc/istio/proxy
connectTimeout: 10s
discoveryAddress: istio-pilot.istio-system:15007
discoveryRefreshDelay: 1s

```


### Install Istio Add-ons

* Prometheus

If you used Helm, you can also add Prometheus as an add on by using the Prometheus options in the Helm values.yaml file as [detailed here](https://istio.io/docs/reference/config/installation-options/#prometheus-options). 

Web Link: [http://127.0.0.1:9090/graph](http://127.0.0.1:9090/graph)

* Grafana

Before using Grafana for looking at data, you need to have Prometheus installed.

![grafana min](https://user-images.githubusercontent.com/202578/33528556-639493e2-d89d-11e7-9768-976fb9208646.png)

```bash
$ kubectl apply -f istio-0.5.1/install/kubernetes/addons/grafana.yaml
$ kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=grafana -o jsonpath='{.items[0].metadata.name}') 3000:3000
```

Web Link: [http://127.0.0.1:3000/dashboard/db/istio-dashboard](http://127.0.0.1:3000/dashboard/db/istio-dashboard)

* Jaegar

![jaeger min](https://user-images.githubusercontent.com/202578/33528554-572c4f28-d89d-11e7-8a01-1543fc2aa064.png)

```bash
$ kubectl apply -n istio-system -f https://raw.githubusercontent.com/jaegertracing/jaeger-kubernetes/master/all-in-one/jaeger-all-in-one-template.yml
$ kubectl port-forward -n istio-system $(kubectl get pod -n istio-system -l app=jaeger -o jsonpath='{.items[0].metadata.name}') 16686:16686
```

Web Link: [http://localhost:16686](http://localhost:16686)
