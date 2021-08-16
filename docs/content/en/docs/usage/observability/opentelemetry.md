---
title: "Tracing with OpenTelemetry"
weight: 11
---

## Tracing in Fission

Currently, Fission supports outputting traces to an OpenTracing Jaeger-formatted trace collection endpoint. This is great as it provides lots of insight into what Fission is doing and helps operators understand and maintain.

## OpenTelemetry

OpenTelemetry is a set of APIs, SDKs, tooling and integrations that are designed for the creation and management of telemetry data such as traces, metrics, and logs. The project provides a vendor-agnostic implementation that can be configured to send telemetry data to the backend(s) of your choice. It supports a variety of popular open-source projects including Jaeger and Prometheus.

## Setting up

### Prerequisite

- Docker
- Kubernetes cluster (the document uses a `kind` cluster)
- [Helm](https://helm.sh/) (This post assumes helm 3 in use)
- kubectl and kubeconfig configured

### Setup OTEL Collector and Jaeger

We will be using the definition files available in the [OpenTelemetry-Go](https://github.com/open-telemetry/opentelemetry-go.git) repository for an easy setup.
Follow the steps below:

```sh
# clone the repository
git clone https://github.com/open-telemetry/opentelemetry-go.git

# change directory to opentelemetry-go/example/otel-collector
cd opentelemetry-go/example/otel-collector

# create the namespace
make namespace-k8s

# deploy Jaeger operator
make jaeger-operator-k8s

# after the operator is deployed, create the Jaeger instance
make jaeger-k8s

# finally, deploy the OpenTelemetry Collector
make otel-collector-k8s
```

Find out where the Jaeger console is living. For us, we get the output:

```sh
kubectl get ingress --all-namespaces

NAMESPACE       NAME           CLASS    HOSTS   ADDRESS   PORTS   AGE
observability   jaeger-query   <none>   *                 80      54s
```

Check if the `otel-collector` service has been created:

```sh
kubectl get svc --all-namespaces

NAMESPACE       NAME                        TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                                  AGE
default         kubernetes                  ClusterIP   10.96.0.1       <none>        443/TCP                                  2m39s
kube-system     kube-dns                    ClusterIP   10.96.0.10      <none>        53/UDP,53/TCP,9153/TCP                   2m38s
observability   jaeger-agent                ClusterIP   None            <none>        5775/UDP,5778/TCP,6831/UDP,6832/UDP      38s
observability   jaeger-collector            ClusterIP   10.96.238.36    <none>        9411/TCP,14250/TCP,14267/TCP,14268/TCP   38s
observability   jaeger-collector-headless   ClusterIP   None            <none>        9411/TCP,14250/TCP,14267/TCP,14268/TCP   38s
observability   jaeger-operator-metrics     ClusterIP   10.96.18.77     <none>        8383/TCP,8686/TCP                        38s
observability   jaeger-query                ClusterIP   10.96.94.227    <none>        16686/TCP,16685/TCP                      38s
observability   otel-collector              NodePort    10.96.141.105   <none>        4317:30080/TCP,8889:31521/TCP            50s
```

Now, setup a port forward to the `otel-collector` service:

```sh
kubectl port-forward service/jaeger-query -n observability 8080:16686 &
```

You should now be able to access Jaeger at [http://localhost:8080/](http://localhost:8080/).

### Installing Fission

At the time of writing this document, the Fission installation does not have OpenTelemetry enabled by default.
In order to enable OpenTelemetry, we need to explicitly set the value of `otelCollectorEndpoint`:

```sh
export FISSION_NAMESPACE=fission
helm install --version 1.14.1 --namespace $FISSION_NAMESPACE \
  fission fission-charts/fission-all \
  --set openTracing.enabled=false \
  --set otelCollectorEndpoint="otel-collector.observability.svc:4317"
```

Note: You may have to change the `otelCollectorEndpoint` value as per your setup.

Currently, Fission supports both - OpenTracing (added a while ago) and OpenTelemetry (new addition).
In a future release, support for OpenTracing will be removed and OpenTelemetry will be used by default.

## Testing

In order to verify that our setup is working and we are able to receive traces, we will deploy and test a fission function.

### NextJS App

For this test we will be using the [NextJS App on Fission](https://github.com/fission/examples/tree/master/samples/nextjs-prefixpath) example.

```sh
git clone https://github.com/fission/examples.git && cd examples/samples/nextjs-prefixpath
```

The example provides all the fission spec files to deploy the function.
You can build and deploy the app as a function by executing the command:

```sh
$ ./deploy/build.sh
```

Note:

- `build.sh` assumes you are using kind cluster. Please make necessary changes according to Kubernetes cluster type.
- This example uses modified NodeJS environment and builder. These would be available in Fission default NodeJS environment soon.

In order to cleanup, you can execute the following command:

```sh
$ ./deploy/destroy.sh
```

Before proceeding please ensure that the package build for deployed function has `succeeded`.
If it is in `running` state, please wait till it succeeds.

Setup a port forward to the router, just so our testing becomes easy:

```sh
kubectl port-forward svc/router 8888:80 -n fission &
```

Now, test the function using the following request:

```sh
fission function test --name nextjs-func --subpath '/api/hello'
{"name":"John Doe"}
```

If you see the response, then function is working as expected.
Let's look for traces next.

### Traces with Jaeger

If you have been following along, you should be able to access Jaeger at [http://localhost:8080/](http://localhost:8080/).
Refresh the page and you should see multiple services listed in the `Service` dropdown.
Select the `Fission-Router` and click the `Find Traces` button.
You should see the spans created for the function request we just tested.

Select the trace and on the next page expand the spans.
You should be able to see the request flow similar to the one below:

![Fission OpenTelemetry](../assets/fission-otel.png)
