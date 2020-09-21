---
title: "Metrics with Prometheus"
weight: 10
---


# Metrics in Fission

Fission exposes metrics in the Prometheus standard, which can be readily scraped and used using a Prometheus server and visualized using Grafana. The metrics help monitor the state of the Functions as well as the Fission components.


### Prometheus

Prometheus is a monitoring and alerting tool. It uses a multi-dimensional data model with time series data identified by metric name and key/value pairs. 

Fission exposes metrics which are pulled and operated by Prometheus at regular intervals.

### Grafana

Grafana is a visualizing tool which can query, visualize, alert on and understand metrics. It supports Prometheus as it's data source.


# Setting up

There are different ways to install Prometheus. It can be installed and run in and outside containers. Since Fission itself runs in Kubernetes, we'll use the [Prometheus Operator](https://github.com/prometheus-operator/prometheus-operator) which is a way of installing Prometheus as Kubernetes Custom Resource.

## Prerequisite

- Kubernetes cluster
- Fission [installed in the cluster](https://docs.fission.io/docs/installation/)
- [Helm](https://helm.sh/) (This post assumes helm 3 in use)
- kubectl and kubeconfig configured


## Install Prometheus and Grafana

We'll install Prometheus and Grafana in a namespace named `monitoring`.

To create the namespace, run the following command in a terminal:

```
$ expose METRICS_NAMESPACE=monitoring
$ kubectl create namespace $METRICS_NAMESPACE
```

Install Prometheus and Grafana with the release name `fission-metrics`.

```
$ helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
$ helm repo add stable https://kubernetes-charts.storage.googleapis.com/
$ helm repo update
$ helm install fission-metrics --namespace $METRICS_NAMESPACE prometheus-community/kube-prometheus-stack --set kubelet.serviceMonitor.https=true --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false --set prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues=false --set prometheus.prometheusSpec.ruleSelectorNilUsesHelmValues=false
```

This will install Prometheus and Grafana in the `monitoring` namespace. Along with the Prometheus server, it'll also install other components viz. `node-exporter`, `kube-state-metrics` and `pushgateway`


## Adding ServiceMonitor for Fission

By default, this installation will not discover the metrics exposed by Fission. To be able to scrape those metrics, we can install ServiceMonitor, which is a Kubernetes  custom resource used to by the Prometheus Operator to add new targets.

Create the manifest:

```
$ cat <<EOF > servicemonitors.yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: executor-service-app
spec:
  selector:
    matchLabels:
      svc: executor
  endpoints:
  - targetPort: 8080
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: router-service-app
spec:
  selector:
    matchLabels:
      svc: router
  endpoints:
  - targetPort: 8080
EOF
```

Install the ServiceMonitors.

```
$ kubectl apply -f servicemonitors.yaml --namespace fission
```

This will install the ServiceMonitors in the `fission` namespace, the same where Fission is installed.

## Accessing Grafana UI

The installation creates a Service named `fission-metrics-grafana`. To access this, you can use Kubernetes port forwarding

```
$ kubectl --namespace monitoring port-forward svc/fission-metrics-grafana 3000:80
```

The Grafana can be now accessed on http://localhost:3000
  
This installation also adds Prometheus as a data source for Grafana automatically.
You can verify and update this in the `Data Sources` section of the UI.

# Metrics Queries

Once Prometheus is configured, we can now run queries in Grafana over Fission metrics. Individual queries can be run under `Explore` section.

Fission exposes a set of metrics. For example to query the total number of function calls, run

```
fission_function_calls_total
```

Calls for a specific function can be queried using
```
fission_function_calls_total{name="foo"}
```

To track the duration of a specific function
```
fission_function_duration_seconds{name="hello"}
```

There are other more Fission metrics, which can be found under `Metrics` in the Explore screen.

# Fission Dashboard

With Grafana, visuals dashboards can be created to monitor multiple metrics in an organized way.

One such dashboard can be found [here](https://github.com/fission/examples/blob/master/dashboards/prometheus-fission-functions.json). This dashboard shows log metrics from all the major components of Fission.

Once imported, the dashboard will look similar to below image.

{{< img "../assets/prometheus-grafana.png" "Prometheus Fission Functions dashboard" "30em" "1" >}}


There will be more dashboards added to the same [location](https://github.com/fission/examples/blob/master/dashboards) over time.
