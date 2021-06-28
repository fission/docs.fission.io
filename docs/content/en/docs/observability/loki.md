---
title: "Logs with Loki"
weight: 20
---

## Logs in Fission

Fission has a few core services running and these core services handle user functions. The logs from both are useful in debugging the functions.

A good log monitoring solution can be useful to make full use of these logs.

## Grafana Loki

Loki is a horizontally-scalable, highly-available, multi-tenant log aggregation system inspired by Prometheus.
The main components are a client to fetch the logs, an aggregator, and a visualizing tool (Grafana).

The stack supports multiple clients, for the case here we will use Promtail which is the recommended client when using the stack in Kubernetes.
Here is a quick overview of components that make up the Loki platform:

- **Loki** - Loki is a horizontally scalable, highly available, multi-tenant log aggregation system inspired by Prometheus.
- **Promtail** - Promtail is the client which fetches and forwards the logs to Loki.
  It is a good fit for Kubernetes as it automatically fetches metadata such as pod labels.
- **Grafana** - A visualization tool that supports Loki as a data source.

The stack is depicted briefly in the below image

![Loki-Grafana stack](../assets/stack.png)

## Setting up

There are different ways and configurations to [install the complete stack](https://grafana.com/docs/loki/latest/installation/).
For this case, we'll use Helm.

### Prerequisite

- Kubernetes cluster
- Fission [installed in the cluster](https://docs.fission.io/docs/installation/)
- [Helm](https://helm.sh/) (This post assumes helm 3 in use)
- kubectl and kubeconfig configured


#### Install Grafana and Loki

From a terminal, run the following commands to add the Loki repo and then install Loki

```bash
$ helm repo add grafana https://grafana.github.io/helm-charts
$ helm repo update
$ helm upgrade -n monitoring --create-namespace --install loki-grafana grafana/loki-stack \
--set grafana.enabled="true" \
--set promtail.enabled="false"
```

This will install Loki & Grafana in the monitoring namespace.
Check if there're pods running for Loki and Grafana.


#### Install Promtail

You'll notice that the Promtail installation is disabled above. This is because custom configuraiton
is required to effectively tail logs. The default Promtail configuration follow the [kubernetes recommended labels](https://kubernetes.io/docs/concepts/overview/working-with-objects/common-labels/) and filter out everything that doesn't conform to those rules.

Create a values.yaml file. This configuration will allow Promtail to tail and forward all labels. This is a necessity since fission adds additional labels when a pod is specialized. 
```bash
cat > promtail-config.yaml <<EOF
config:
  lokiAddress: http://loki:3100/loki/api/v1/push
  snippets:
    common:
      - action: replace
        source_labels:
          - __meta_kubernetes_pod_node_name
        target_label: node_name
      - action: replace
        source_labels:
          - __meta_kubernetes_namespace
        target_label: namespace
      - action: replace
        replacement: $1
        separator: /
        source_labels:
          - namespace
          - app
        target_label: job
      - action: replace
        source_labels:
          - __meta_kubernetes_pod_name
        target_label: pod
      - action: replace
        source_labels:
          - __meta_kubernetes_pod_container_name
        target_label: container
      - action: replace
        replacement: /var/log/pods/*$1/*.log
        separator: /
        source_labels:
          - __meta_kubernetes_pod_uid
          - __meta_kubernetes_pod_container_name
        target_label: __path__
      - action: replace
        replacement: /var/log/pods/*$1/*.log
        regex: true/(.*)
        separator: /
        source_labels:
          - __meta_kubernetes_pod_annotationpresent_kubernetes_io_config_hash
          - __meta_kubernetes_pod_annotation_kubernetes_io_config_hash
          - __meta_kubernetes_pod_container_name
        target_label: __path__
      - action: labelmap
        regex: __meta_kubernetes_pod_label_(.+)
EOF
```

```bash
$ helm upgrade -n monitoring --install promtail grafana/promtail -f promtail-config.yaml
```

This will install Prom in the `monitoring` namespace!
Check if there're is a promtail pod running.

We can access the Promtail UI at `localhost:3101` to see all of the pods logs being tailed along with the labels assigned to them.
```bash
$ kubectl --namespace monitoring port-forward $(kubectl  --namespace monitoring get pod -l app.kubernetes.io/instance=promtail -o name) 3101:3101
```

#### Accessing Grafana UI

If you've followed the above steps, `loki-stack` creates a grafana Service in the `monitoring` namespace.
To access this, you can use Kubernetes port forwarding.

```bash
$ kubectl --namespace monitoring port-forward svc/fission-logs-grafana 3000:80
```

You'll need to obtain a username and password to access the UI. 
The username is `admin` and the password can be obtained from inside the kubernetes cluster.
```bash
$ kubectl --namespace monitoring get secrets loki-grafana -o go-template --template='{{index .data "admin-password"}}' | base64 -d
```

#### Adding Loki as a data source in Grafana

Clicking on the Settings icon in the left pane will bring up a menu, click on `Data Sources`.
Clicking on `Add Data Source` and select Loki.
Under HTTP, in the URL field put `http://loki:3100`

Click on `Save and Test` and there should be a notification of the data source added successfully.

### Running Log Queries

From the options in left pane, navigate to `Explore`.
Here you can run log queries using [LogQL](https://grafana.com/docs/loki/latest/logql/).
Since Loki auto scrapes labels, there will be example log queries presented.
There also will be list of log labels that you can select from.

You can run queries for Fission components such as:

- All logs from Fission Router
    `{svc="router"}`
- All logs from Fission Router that have "error" in the statement.
    `{svc="router"} |= "error"`

Loki is great for performing metrics over the logs, for example:

- Count of all logs in Fission Router with "error" over span of 5 mins `count_over_time({svc="router"} |= "error" [5m])`.

## Fission Logs Dashboard

Grafana provides a great way to build visual dashboards by aggregating queries.
These dashboards are a set of individual panels each showing visuals of some queries.
Metrics over this logs can be seen in real time.
The dashboards are also easily shareable.

Multiple panel with queries over Fission can be put together to get overall view of Fission components as well the Functions running within.
An exported JSON of one such dashboard can be found [here](https://github.com/fission/examples/tree/master/dashboards/loki-grafana-summary.json).
This dashboard shows log metrics from all the major components of Fission.

Once imported, the dashboard will look similar to below image.

![Loki-Grafana dashboard](../assets/loki-grafana-dashboard.png)

Watch the same [location](https://github.com/fission/examples/tree/master/dashboards/) for more dashboards which will be added over time.
