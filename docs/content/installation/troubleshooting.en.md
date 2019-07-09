---
title: "Troubleshooting"
draft: false
weight: 12
---

## Fetcher shows timeout during specialization after applying proxy configuration

Fetcher is responsible for fetching function deploy package and specializing function container by calling
it's following URL:

```
# for environment version 1
http://localhost:8888/specialize

# for environment version 2
http://localhost:8888/v2/specialize
``` 

If fetcher log shows timeout error with non-localhost IP, for example `10.22.120.211` here, that might be related to the 
underlying `docker proxy config` in your system environment.

```bash
"logger":"fetcher","caller":"fetcher/fetcher.go:644"
"msg":"error connecting to function environment pod for specialization request, retrying"
"error":"dial tcp 10.22.120.211:8888: i/o timeout"
```

Please ensure that `localhost` and `127.0.0.1` are in the `NO_PROXY` setting in your system environment.

## External IP of router stuck in pending state

If your cluster is running in an environment that does not support external load balancer (e.g., minikube), 
the EXTERNAL-IP of fission router will stay in pending state.

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
through the port you just created.  This is useful for local
testing of your function.
