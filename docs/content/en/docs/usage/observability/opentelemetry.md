---
title: "Tracing with OpenTelemetry"
weight: 11
---

## Tracing in Fission

Up to `1.14.1` release, Fission supports collecting traces to an OpenTracing Jaeger-formatted trace collection endpoint.
Tracing provides insight into what Fission is doing, and how it is doing it.
OpenTelemetry provides a new tracing system that is more flexible and powerful.
As we add support OpenTelemetry, OpenTracing will be marked deprecated and removed. OpenTelemtry is backward compatible with OpenTracing.

If you are starting fresh with Fission, we recommend using OpenTelemetry.
This is primarily because OpenTelemetry makes robust, portable telemetry a built-in feature of cloud-native software. OpenTelemetry provides a single set of APIs, libraries, agents, and collector services to capture distributed traces and metrics from your application.

## OpenTelemetry

OpenTelemetry is a set of APIs, SDKs, tooling and integrations that are designed for the creation and management of telemetry data such as traces, metrics, and logs.
The project provides a vendor-agnostic implementation that can be configured to send telemetry data to the backend(s) of your choice.
It supports a variety of popular open-source projects including Jaeger and Prometheus.

## Fission Opentelemetry Integration

If you are have OpenTelemetry installed, you can use it to collect traces and metrics from Fission.

`openTelemetry` section in helm chart will be used to configure OpenTelemetry sdk used by different Fission components.
Fission chart will pass different environment variables to pod to configure OpenTelemetry based on the configuration.

| Option | Description |
| ------ | ----------- |
| `openTelemetry.otlpCollectorEndpoint` | Collector endpoint for OpenTelemetry |
| `openTelemetry.otlpInsecure` | Secure endpoint for the collector with true/false |
| `openTelemetry.otlpHeaders` | Key-value pairs to be used as headers associated with gRPC or HTTP requests |
| `openTelemetry.tracesSampler` | Sampler for traces |
| `openTelemetry.tracesSamplingRate` | Argument for sampler|
| `openTelemetry.propagators` | Propagator to generate trace id header |

If you have not configured collector endpoint, you won't be able to visualize traces.
Based on sampler configuration, you can observed `trace_id` in Fission component logs.
You can search with `trace_id` across Fission services logs in case of debugging or troubleshooting.

Many of the observability platforms such as DataDog, Dynatrace, Honeycomb, Lightstep, New Relic, Signoz, Splunk etc. support OpenTelemetry out-of-box, `otlpHeaders` can be used to configure the headers required by the observability platform.
You don't need to setup up Opentelemtry Collector from scratch in that case.

If you feel any of the above options are not adequate, feel free to raise an issue or open a pull request.

### Types of samplers

- `always_on` - Sampler that always samples spans, regardless of the parent span's sampling decision.
- `always_off` - Sampler that never samples spans, regardless of the parent span's sampling decision.
- `traceidratio` - Sampler that samples probabalistically based on rate.
- `parentbased_always_on` - (default if empty) Sampler that respects its parent span's sampling decision, but otherwise always samples.
- `parentbased_always_off` - Sampler that respects its parent span's sampling decision, but otherwise never samples.
- `parentbased_traceidratio` - (default in chart) Sampler that respects its parent span's sampling decision, but otherwise samples probabalistically based on rate.

#### Sampler Arguments

Each Sampler type defines its own expected input, if any.
Currently we get trace ratio for the case of following samplers,

- `traceidratio`
- `parentbased_traceidratio`

Sampling probability, a number in the [0..1] range, e.g. "0.1". Default is 0.1.

### Types of propagators

Based on the propagator type, OpenTelemetry will generate a trace id header.

- `tracecontext` - W3C Trace Context
- `baggage` - W3C Baggage
- `b3` - B3 Single
- `b3multi` - B3 Multi
- `jaeger` - Jaeger uber-trace-id header
- `xray` - AWS X-Ray (third party)
- `ottrace` - OpenTracing Trace (third party)

Propogator config is uselful, if you want to use different header from W3C Trace Context.
E.g. If you are using OpenTracing/Jaeger, you can set propagator to `jaeger`.

## Sample OTEL Collector

We will be using the [OpenTelemetry Operator for Kubernetes](https://github.com/open-telemetry/opentelemetry-operator) to setup OTEL collector.
To install the operator in an existing cluster, `cert-manager` is required.

Use the following commands to install `cert-manager` and the operator:

```sh
# cert-manager
kubectl apply -f https://github.com/jetstack/cert-manager/releases/latest/download/cert-manager.yaml

# open telemetry operator
kubectl apply -f https://github.com/open-telemetry/opentelemetry-operator/releases/latest/download/opentelemetry-operator.yaml
```

Once the `opentelemetry-operator` deployment is ready, we need to create an OpenTelemetry Collector instance.

The following configuration provides a good starting point, however, you may change as per your requirement:

```sh
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: otel-collector-conf
  namespace: opentelemetry-operator-system
  labels:
    app: opentelemetry
    component: otel-collector-conf
data:
  otel-collector-config: |
    receivers:
      # Make sure to add the otlp receiver.
      # This will open up the receiver on port 4317
      otlp:
        protocols:
          grpc:
            endpoint: "0.0.0.0:4317"
    processors:
    extensions:
      health_check: {}
    exporters:
      jaeger:
        endpoint: "jaeger-collector.observability.svc.cluster.local:14250"
        insecure: true
      prometheus:
        endpoint: 0.0.0.0:8889
        namespace: "testapp"
      logging:

    service:
      extensions: [health_check]
      pipelines:
        traces:
          receivers: [otlp]
          processors: []
          exporters: [jaeger]

        metrics:
          receivers: [otlp]
          processors: []
          exporters: [prometheus, logging]
---
apiVersion: v1
kind: Service
metadata:
  name: otel-collector
  namespace: opentelemetry-operator-system
  labels:
    app: opentelemetry
    component: otel-collector
spec:
  ports:
    - name: otlp # Default endpoint for otlp receiver.
      port: 4317
      protocol: TCP
      targetPort: 4317
      nodePort: 30080
    - name: metrics # Default endpoint for metrics.
      port: 8889
      protocol: TCP
      targetPort: 8889
  selector:
    component: otel-collector
  type: NodePort
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: otel-collector
  namespace: opentelemetry-operator-system
  labels:
    app: opentelemetry
    component: otel-collector
spec:
  selector:
    matchLabels:
      app: opentelemetry
      component: otel-collector
  minReadySeconds: 5
  progressDeadlineSeconds: 120
  replicas: 1 #TODO - adjust this to your own requirements
  template:
    metadata:
      annotations:
        prometheus.io/path: "/metrics"
        prometheus.io/port: "8889"
        prometheus.io/scrape: "true"
      labels:
        app: opentelemetry
        component: otel-collector
    spec:
      containers:
        - command:
            - "/otelcol"
            - "--config=/conf/otel-collector-config.yaml"
            # Memory Ballast size should be max 1/3 to 1/2 of memory.
            - "--mem-ballast-size-mib=683"
          env:
            - name: GOGC
              value: "80"
          image: otel/opentelemetry-collector:0.6.0
          name: otel-collector
          resources:
            limits:
              cpu: 1
              memory: 2Gi
            requests:
              cpu: 200m
              memory: 400Mi
          ports:
            - containerPort: 4317 # Default endpoint for otlp receiver.
            - containerPort: 8889 # Default endpoint for querying metrics.
          volumeMounts:
            - name: otel-collector-config-vol
              mountPath: /conf
          # - name: otel-collector-secrets
          #   mountPath: /secrets
          livenessProbe:
            httpGet:
              path: /
              port: 13133 # Health Check extension default port.
          readinessProbe:
            httpGet:
              path: /
              port: 13133 # Health Check extension default port.
      volumes:
        - configMap:
            name: otel-collector-conf
            items:
              - key: otel-collector-config
                path: otel-collector-config.yaml
          name: otel-collector-config-vol
EOF
```

Note: The above configuration is borrowed from the [OpenTelemetry Collector traces example](https://github.com/open-telemetry/opentelemetry-go/tree/main/example/otel-collector), with some minor changes.

### Jaeger

We will using the [Jaeger Operator for Kubernetes](https://github.com/jaegertracing/jaeger-operator) to deploy Jaeger.
To install the operator, run:

```sh
kubectl create namespace observability
kubectl create -n observability -f https://raw.githubusercontent.com/jaegertracing/jaeger-operator/master/deploy/crds/jaegertracing.io_jaegers_crd.yaml
kubectl create -n observability -f https://raw.githubusercontent.com/jaegertracing/jaeger-operator/master/deploy/service_account.yaml
kubectl create -n observability -f https://raw.githubusercontent.com/jaegertracing/jaeger-operator/master/deploy/role.yaml
kubectl create -n observability -f https://raw.githubusercontent.com/jaegertracing/jaeger-operator/master/deploy/role_binding.yaml
kubectl create -n observability -f https://raw.githubusercontent.com/jaegertracing/jaeger-operator/master/deploy/operator.yaml
```

The operator will activate extra features if given cluster-wide permissions. To enable that, run:

```sh
kubectl create -f https://raw.githubusercontent.com/jaegertracing/jaeger-operator/master/deploy/cluster_role.yaml
kubectl create -f https://raw.githubusercontent.com/jaegertracing/jaeger-operator/master/deploy/cluster_role_binding.yaml
```

Note that you'll need to download and customize the cluster_role_binding.yaml if you are using a namespace other than observability.

Once the jaeger-operator deployment in the namespace observability is ready, create a Jaeger instance, like:

```sh
kubectl apply -n observability -f - <<EOF
apiVersion: jaegertracing.io/v1
kind: Jaeger
metadata:
  name: jaeger
EOF
```

Check if the `otel-collector` and `jaeger-query` service has been created:

```sh
kubectl get svc --all-namespaces

NAMESPACE                       NAME                                                        TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                                  AGE
cert-manager                    cert-manager                                                ClusterIP   10.96.228.4     <none>        9402/TCP                                 7m50s
cert-manager                    cert-manager-webhook                                        ClusterIP   10.96.214.220   <none>        443/TCP                                  7m50s
default                         kubernetes                                                  ClusterIP   10.96.0.1       <none>        443/TCP                                  9m35s
kube-system                     kube-dns                                                    ClusterIP   10.96.0.10      <none>        53/UDP,53/TCP,9153/TCP                   9m33s
observability                   jaeger-agent                                                ClusterIP   None            <none>        5775/UDP,5778/TCP,6831/UDP,6832/UDP      3s
observability                   jaeger-collector                                            ClusterIP   10.96.48.27     <none>        9411/TCP,14250/TCP,14267/TCP,14268/TCP   3s
observability                   jaeger-collector-headless                                   ClusterIP   None            <none>        9411/TCP,14250/TCP,14267/TCP,14268/TCP   3s
observability                   jaeger-operator-metrics                                     ClusterIP   10.96.164.206   <none>        8383/TCP,8686/TCP                        61s
observability                   jaeger-query                                                ClusterIP   10.96.186.29    <none>        16686/TCP,16685/TCP                      3s
opentelemetry-operator-system   opentelemetry-operator-controller-manager-metrics-service   ClusterIP   10.96.29.83     <none>        8443/TCP                                 6m11s
opentelemetry-operator-system   opentelemetry-operator-webhook-service                      ClusterIP   10.96.74.0      <none>        443/TCP                                  6m11s
opentelemetry-operator-system   otel-collector                                              NodePort    10.96.107.99    <none>        4317:30080/TCP,8889:30898/TCP            2m22s
```

Now, setup a port forward to the `jaeger-query` service:

```sh
kubectl port-forward service/jaeger-query -n observability 8080:16686 &
```

You should now be able to access Jaeger at [http://localhost:8080/](http://localhost:8080/).

### Installing Fission

At the time of writing this document, the Fission installation does not have OpenTelemetry enabled by default.
In order to enable OpenTelemetry collector, we need to explicitly set the value of `openTelemetry.otlpCollectorEndpoint`:

```sh
export FISSION_NAMESPACE=fission
helm install --namespace $FISSION_NAMESPACE \
  fission fission-charts/fission-all \
  --set openTelemetry.otlpCollectorEndpoint="otel-collector.opentelemetry-operator-system.svc:4317" \
  --set openTelemetry.otlpInsecure=true \
  --set openTelemetry.tracesSampler="parentbased_traceidratio" \
  --set openTelemetry.tracesSamplingRate="1"
```

Note: You may have to change the `openTelemetry.otlpCollectorEndpoint` value as per your setup.

## Testing

In order to verify that our setup is working and we are able to receive traces, we will deploy and test a fission function.
For this test we will be using a simple NodeJS based function.

```sh
# create an environment
fission env create --name nodejs --image fission/node-env

# get hello world function
curl https://raw.githubusercontent.com/fission/examples/master/nodejs/hello.js > hello.js

# register the function with Fission
fission function create --name hello --env nodejs --code hello.js

# run the function
fission function test --name hello
hello, world!
```

### Traces with Jaeger

If you have been following along, you should be able to access Jaeger at [http://localhost:8080/](http://localhost:8080/).
Refresh the page and you should see multiple services listed in the `Service` dropdown.
Select the `Fission-Router` and click the `Find Traces` button.
You should see the spans created for the function request we just tested.

Select the trace and on the next page expand the spans.

You should be able to see the request flow similar to the one below:

![Fission OpenTelemetry](../assets/fission-otel.png)

If you enable OpenTelemetry tracing within your function, you can capture spans and events for the function request.

Following are few samples of spans and events captured by invoking a Go base function:

![Fission Spans](../assets/fission-go-func-trace.png)

![Fission Executor Span Events](../assets/fission-executor-span-event.png)
