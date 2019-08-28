---
title: "Trouble Shooting"
draft: false
weight: 20
alwaysopen: false
chapter: false
---

In this guide, you will learn how to debug your functions and collect information for help.

## Kubernetes

In this section, we will cover how to troubleshoot the problems related to Kubernetes cluster setup.

### Check in-cluster DNS service

Since Fission utilizes in-cluster DNS to communicate with other components, it's important to make sure that the in-cluster DNS
service is available.

First, check that we have running DNS pod(s).

```bash
$ kubectl -n kube-system get pod|grep dns
coredns-fb8b8dccf-bjxmj                  1/1     Running   1          65m
```

Create a pod and use `nslookup` to check availability of DNS service. 

```
$ kubectl -n fission get svc
NAME                                       TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE
executor                                   ClusterIP      10.103.121.81    <none>        80/TCP         2d

$ kubectl -n fission run busybox --image=busybox --restart=Never --tty -it
/ # nslookup executor
Server:		10.96.0.10
Address:	10.96.0.10:53

Name:	executor.fission.svc.cluster.local
Address: 10.103.121.81
```

The DNS service will return an address which matches the address shown in the previous command. 
For more debugging DNS resolution, see [here](https://kubernetes.io/docs/tasks/administer-cluster/dns-debugging-resolution/). 

### Kubeconfig for connecting to Kubernetes Cluster

Make sure that `~/.kube/config` exists or assign the correct value to `KUBECONFIG`. 

```bash
# https://github.com/fission/fission/issues/1133
Fatal error: Error getting controller pod for port-forwarding
```

See [here](../installation/#cloud-hosted-clusters-gke-aws-azure-etc) to learn how to setup config correctly on different platforms.

### Dynamic volume provisioning

Package storage and Prometheus services need persistent volume to store data. 
See [here](https://kubernetes.io/docs/concepts/storage/dynamic-provisioning/) to learn how to set up dynamic volume provisioning.
And you should be able to list `pvc` and `pv` as follows after setting up.

```bash
$ kubectl -n fission get pvc
NAME                                 STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
bald-otter-prometheus-alertmanager   Bound    pvc-733972f7-c2f2-11e9-9a83-025000000001   2Gi        RWO            hostpath       75m
bald-otter-prometheus-server         Bound    pvc-733cad91-c2f2-11e9-9a83-025000000001   8Gi        RWO            hostpath       75m
fission-storage-pvc                  Bound    pvc-733ec058-c2f2-11e9-9a83-025000000001   8Gi        RWO            hostpath       75m

$ kubectl -n fission get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                                        STORAGECLASS   REASON   AGE
pvc-733972f7-c2f2-11e9-9a83-025000000001   2Gi        RWO            Delete           Bound    fission/bald-otter-prometheus-alertmanager   hostpath                75m
pvc-733cad91-c2f2-11e9-9a83-025000000001   8Gi        RWO            Delete           Bound    fission/bald-otter-prometheus-server         hostpath                75m
pvc-733ec058-c2f2-11e9-9a83-025000000001   8Gi        RWO            Delete           Bound    fission/fission-storage-pvc                  hostpath                75m
```

If the underlying platform the cluster running on doesn't support persistent volume, you can set `helm` variable as follows.

```bash
helm install --namespace fission --set persistence.enabled=false .....
```

### Function doesn't scales when workloads increase

Fission relies on Kubernetes autoscaling mechanism to scale replicas of function when workloads increase. To enable it,
you have to enable/install the metric server in your cluster. 

```bash
# minikube
$ minikube addons enable metrics-server
```

If you're not running on other platforms, see [metric-server](https://github.com/kubernetes-incubator/metrics-server).

### HPA shows unknown status

You may see `<unknown>` status as follows. It's because it takes some time for metric-server to collect enough 
information to calculate the right number of replicas after installing metric server. 

```bash
$ kubectl get hpa
NAME         REFERENCE               TARGETS         MINPODS   MAXPODS   REPLICAS   AGE
php-apache   Deployment/php-apache   <unknown>/50%   1         10        1          3m3s
```

You can follow this [guide](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/) to verify the metric-server installation.

## Fission

In this section, we will cover how to troubleshoot your functions and collect information to troubleshoot problems related to Fission.

## Check pods status and logs

If the Fission installation doesn't work for you, you can follow guides below to troubleshoot. 

### Core components

All core component should stay in `RUNNING` state. If the pod is not in RUNNING state or the `RESTARTS` counts keep increasing,
you can get some useful information with commands.

In most cases, `Events` shows common errors like wrong image name, and can help you to locate common problems.

```bash
$ kubectl -n fission describe pod -f <pod>
```

If Events doesn't provide any information, you then need to dump component logs

```bash
$ kubectl -n fission logs -f <pod>
```

For example, here is log from executor which shows that in-Cluster DNS problem (port 53).

```bash
error posting to getting service for function: Post http://executor.fission/v2/getServiceForFunction: 
dial tcp: lookup executor.fission on 127.0.0.53:53: read udp 127.0.0.1:59676->127.0.0.53:53: read: connection refused
```

### Function pods 

A function pod consists with two containers: `Fetcher` and `Runtime`. Fetcher fetches user function into function pod 
during specialization stage. Runtime is a container contains necessary language environment to run user function. 

You can filter out function pods you're interesting in and dump logs as follows.

```bash
$ kubectl -n fission-function get pod -l functionName=<fn-name>
```

You can also add additional labels to filter out pods. Here are some labels you can use.

| Label | Possible Value | Example |
|-------|----------------|---------|
| environmentName | environment name | environmentName=go |
| functionName | function name | functionName=hello |
| executorType | poolmgr/newdeploy  | executorType=newdeploy |

If you also want to filter out function pod in specific state like `RUNNING`, try

```bash
$ kubectl -n fission-function get pod -l functionName=<fn-name> \
    --field-selector status.phase=Running
```

Dump logs from containers

```bash
$ kubectl -n fission-function describe pod -f <pod>
$ kubectl -n fission-function logs -f <pod> -c <container>
```

### Builder pods

The builder pods is similar to function pod but for building user function source code into a deployable package.

```bash
$ fission pkg create --env go --src go.zip
Package 'go-zip-5obh' created

$ fission pkg list
NAME          BUILD_STATUS ENV
go-zip-5obh   running      go
```

Your function won't work until the package function used turns into `succeeded` state. If a package shows state other than
succeeded you can retrieve build logs with commands as follows. 

```
$ fission pkg list
NAME          BUILD_STATUS ENV
go-zip-a7ns   failed       go

$ fission pkg info --name go-zip-a7ns
Name:        go-zip-a7ns
Environment: go
Status:      failed
Build Logs:
Error building deployment package: Internal error - {"artifactFilename":"go-zip-a7ns-tu8wfl-bkkmcd",
"buildLogs":"Building in directory /usr/src/go-zip-a7ns-tu8wfl\n++ basename /packages/go-zip-a7ns-tu8wfl\n+ 
srcDir=/usr/src/go-zip-a7ns-tu8wfl\n+ trap 'rm -rf /usr/src/go-zip-a7ns-tu8wfl' EXIT\n+ '[' -d /packages/go-zip-a7ns-tu8wfl ']'
\n+ echo 'Building in directory /usr/src/go-zip-a7ns-tu8wfl'\n+ ln -sf /packages/go-zip-a7ns-tu8wfl 
/usr/src/go-zip-a7ns-tu8wfl\n+ cd /usr/src/go-zip-a7ns-tu8wfl\n+ '[' -f go.mod ']'\n+ '[' '!' -z 1.12.7 ']'\n+ 
version_ge 1.12.7 1.12\n++ head -n 1\n++ sort -rV\n++ tr ' ' '\\n'\n++ echo 1.12.7 1.12\n+ test 1.12.7 == 1.12.7\n+ 
go mod download\n+ go build -buildmode=plugin -i -o /packages/go-zip-a7ns-tu8wfl-bkkmcd .\n# 
github.com/fission/fission/examples/go/go-module-example\n./main.go:4:2: imported and not used: 
\"fmt\"\n+ rm -rf /usr/src/go-zip-a7ns-tu8wfl\nerror building source package: error waiting for cmd \"build\": exit status 2\n"}
```

To dump builder logs, you can do 

```bash
$ kubectl -n fission-builder get pod -l envName=<env-name>
$ kubectl -n fission-builder describe pod -f <pod>
$ kubectl -n fission-builder logs -f <pod> -c <container>
```

## Dump logs for further help

If steps above cannot help you to solve the problem, you can run `support` command to dump logs. 

```bash
$ fission support dump
```

Then, you can open issue on [GitHub](https://github.com/fission/fission/issues) and upload the dump file for others to help.
