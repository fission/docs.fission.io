---
title: Environment Variables
draft: false
weight: 2
---

## Namespace

Set `FISSION_NAMESPACE` to the namespace where the Fission is
installed.  You don't have to set this unless there are multiple
Fission installations in different namespaces within the same
Kubernetes cluster.

``` bash
$ export FISSION_NAMESPACE <namespace>
```

## Fission Router Address

It's convenient to set the `FISSION_ROUTER` environment variable to the
externally-visible address of the Fission router.

### Minikube

If you're using minikube, use these commands:

``` bash
$ export FISSION_ROUTER=$(minikube ip):$(kubectl -n fission get svc router -o jsonpath='{...nodePort}')
```
Above line translates to IP (from minikube):PORT (from the fission router) e.g., 192.168.99.110:30722. This address is stored in FISSION_ROUTER environment variable. 

#### Cloud Provider

If you want to expose the router to the internet, the service type of
router service must be set to `LoadBalancer`.  This is the default in
the helm chart.

```bash
$ kubectl --namespace fission get svc

NAME             TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
router           LoadBalancer   10.107.80.21     <pending>     80:31314/TCP     11d
```

If the field `EXTERNAL-IP` shows `<pending>`, it means that kubernetes
is waiting for cloud provider to allocate the public IP address. It
often takes a few minutes to get an IP address. Then:

``` bash
# AWS
$ export FISSION_ROUTER=$(kubectl --namespace fission get svc router -o=jsonpath='{..hostname}')

# GCP
$ export FISSION_ROUTER=$(kubectl --namespace fission get svc router -o=jsonpath='{..ip}')
```

### Using FISSION_ROUTER env var

```bash
$ curl http://${FISSION_ROUTER}/<url-path>
```

### Troubleshooting

If your cluster is running in an environment that does not support external load balancer (e.g., minikube), the EXTERNAL-IP of fission router will stay in pending state.

```bash
$ kubectl --namespace fission get svc router
NAME      TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
router    LoadBalancer   10.39.253.73   <pending>   80:31377/TCP   27d
```

In this case, you can use the port-forward method instead:

``` bash
# Port-forward
$ kubectl --namespace fission port-forward $(kubectl --namespace fission get pod -l svc=router -o name) <local port>:80 &
$ export FISSION_ROUTER=127.0.0.1:<local port>
```

Now, `curl http://${FISSION_ROUTER}/` will open a connection that goes
through the port forward you just created.  This is useful for local
testing of your function.
