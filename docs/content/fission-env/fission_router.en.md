---
title: "FISSION_ROUTER"
draft: false
weight: 47
---

`FISSION_ROUTER` is the environment variable for user to access functions through the fission router. 

Normally, you don’t need to set this environment variable unless you want to expose the function to external network for public access.

### Minikube

If you're using minikube, use these commands:

``` bash
$ export FISSION_ROUTER=$(minikube ip):$(kubectl -n fission get svc router -o jsonpath='{...nodePort}')
```

#### Cloud Provider

The service type of router service must be `LoadBalancer`. 

```bash
$ kubectl --namespace fission get svc

NAME             TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
router           LoadBalancer   10.107.80.21     <pending>     80:31314/TCP     11d
```

If the field `EXTERNAL-IP` shows `<pending>`, it means that kubernetes is waiting for cloud provider to allocate the public IP address. It often takes couple minutes to get IP address. Then:

``` bash
# AWS
$ export FISSION_ROUTER=$(kubectl --namespace fission get svc router -o=jsonpath='{..hostname}')

# GCP
$ export FISSION_ROUTER=$(kubectl --namespace fission get svc router -o=jsonpath='{..ip}')
```

### Test

```bash
$ curl http://${FISSION_ROUTER}/<url-path>
```

### Troubleshooting

If your cluster is running in an environment that does not support external load balancer (e.g., minikube), the EXTERNAL-IP of fission router will stay in pending state.

```
$ kubectl --namespace fission get svc router
NAME      TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
router    LoadBalancer   10.39.253.73   <pending>   80:31377/TCP   27d
```

In this case, you can access function using the service NodePort above, or using Port-forward method instead.

``` bash
# Port-forward
$ kubectl --namespace fission port-forward $(kubectl --namespace fission get pod -l svc=router -o name) <local port>:80
$ export FISSION_ROUTER=127.0.0.1:<local port>
```
