---
title: "Accessing Secrets/ConfigMaps"
draft: false
weight: 4
---

Functions can access Kubernetes [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/) and [ConfigMaps](https://kubernetes.io/docs/concepts/storage/volumes/#configmap).
Use secrets for things like API keys, authentication tokens, and so on.
Use config maps for any other configuration that doesn't need to be a secret.

## Create a Secret or a Configmap

You can create a Secret or ConfigMap with the Kubernetes CLI:

```bash
$ kubectl -n default create secret generic my-secret --from-literal=TEST_KEY="TESTVALUE"

$ kubectl -n default create configmap my-configmap --from-literal=TEST_KEY="TESTVALUE"
```

Or, use `kubectl create -f <filename.yaml>` to create these from a YAML file.

```yaml
apiVersion: v1
kind: Secret
metadata:
  namespace: default
  name: my-secret
data:
  TEST_KEY: VEVTVFZBTFVF # value after base64 encode
type: Opaque

---
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: default
  name: my-configmap
data:
  TEST_KEY: TESTVALUE
```

## Accessing Secrets and ConfigMaps

Secrets and configmaps are accessed similarly.
Each secret or configmap is a set of key value pairs.
Fission sets these up as files you can read from your function.

```text
# Secret path
/secrets/<namespace>/<name>/<key>

# ConfigMap path
/configs/<namespace>/<name>/<key>
```

From the previous example, the paths are:

```text
# secret my-secret
/secrets/default/my-secret/TEST_KEY

# confimap my-configmap
/configs/default/my-configmap/TEST_KEY
```

Now, let's create a simple python function (leaker.py) that returns the value of Secret `my-secret` and ConfigMap `my-configmap`.

```python
# leaker.py

def main():
    path = "/configs/default/my-configmap/TEST_KEY"
    f = open(path, "r")
    config = f.read()
    f.close()

    path = "/secrets/default/my-secret/TEST_KEY"
    f = open(path, "r")
    secret = f.read()
    f.close()

    msg = "ConfigMap: %s\nSecret: %s" % (config, secret)

    return msg, 200
```

Create an environment and a function:

```bash
# create python env
$ fission env create --name python --image fission/python-env

# create function named "leaker"
$ fission fn create --name leaker --env python --code leaker.py --secret my-secret --configmap my-configmap
```

You can provide multiple configmaps or secrets while creating a fission function through command line, below syntax can be used to provide more than one configmaps or secrets.

```bash
# Provide multiple Configmaps
$ fission fn create --name <fn-name> --env <env-name> --code <your-source> --configmap <configmap-one> --configmap <configmap-two>

# Provide multiple Secrets
$ fission fn create --name <fn-name> --env <env-name> --code <your-source> --secret <secret-one> --secret <secret-two>
```

Run the function, and the output should look like this:

```bash
$ fission function test --name leaker
ConfigMap: TESTVALUE
Secret: TESTVALUE
```

## Updating Secrets and ConfigMaps

{{% notice note %}}
If you have a large number of functions using a configmap or secret, updating that configmap or secret will cause a large number of pods getting re-created.
Please make sure that the cluster has enough capacity to accommodate the short spike of many pods getting terminated and new once getting created.
{{% /notice %}}

If you update the configmap or secret - the same will be updated in the function pods and newer value of configmap/secret will be used for executing functions.
The time it takes for the change to reflect depends on the time it takes for rolling update to finish.

{{% notice note %}}
In Fission version prior to 1.4.
If the Secret or ConfigMap value is updated, the function will not get the updated and may get a cached older value.
{{% /notice %}}

## Fission Function and Secrets/ConfigMaps Namespace
As of v1.12.0, you should aim to have your fission function and the secret/configmap it is accessing in the same namespace. Fission will create a `RoleBinding` called `secret-configmap-getter-binding` in your function's namespace to access secrets/configmaps in the same namespace. Unexpected behavior can occur if functions are trying to access secrets/configmaps in a different namespace because the RoleBinding Fission creates is expecting secrets/configmaps to be in the same namespace.

Do not manually create this rolebinding with the same name (`secret-configmap-getter-binding`) because Fission has a reaper function that will remove this rolebinding every 30 minutes if it cannot find functions in the same namespace as the `RoleBinding`. Here is the function that reaps dangling RoleBindings: https://github.com/fission/fission/blob/cc552d9777057ef1ae0fdfeef0a27126a1b8afcf/pkg/executor/reaper/reaper.go#L182

Errors that indicate this is an issue:

This would show in router logs
```
"level":"error",
"ts":1615498236.260082,
"logger":"triggerset.http_trigger_set.jira-cadence-integeration-api-route",
"caller":"router/functionHandler.go:650",
"msg":"error sending request to function",
"error":" - error updating service address entry for function integeration-api_default: Internal error - [integeration-api] error creating service for function: Internal error - error fetching secrets/configs: error getting secret from kubeapi",
```

In your function's fetcher container. The forbidden here indicates a permissions issue. Check if your function's namespace has the correct RoleBinding to access your secret/configmap. Creating functions and secret/configmap in the same namespace should resolve this.
```
{
  "level": "error",
  "ts": 1615415275.78049,
  "logger": "fetcher",
  "caller": "fetcher/fetcher.go:340",
  "msg": "error getting secret from kubeapi",
  "error": "secrets \"svc-secret\" is forbidden: User \"system:serviceaccount:fission-function:fission-fetcher\" cannot get resource \"secrets\" in API group \"\" in the namespace \"fission-function\"",
  "secret_name": "svc-secret",
  "secret_namespace": "fission-function",
  "stacktrace": "github.com/fission/fission/pkg/fetcher.(*Fetcher).FetchSecretsAndCfgMaps\n\t/go/src/pkg/fetcher/fetcher.go:340\ngithub.com/fission/fission/pkg/fetcher.(*Fetcher).SpecializePod\n\t/go/src/pkg/fetcher/fetcher.go:597\ngithub.com/fission/fission/pkg/fetcher.(*Fetcher).SpecializeHandler\n\t/go/src/pkg/fetcher/fetcher.go:197\nnet/http.HandlerFunc.ServeHTTP\n\t/usr/local/go/src/net/http/server.go:1995\nnet/http.(*ServeMux).ServeHTTP\n\t/usr/local/go/src/net/http/server.go:2375\ngo.opencensus.io/plugin/ochttp.(*Handler).ServeHTTP\n\t/go/pkg/mod/go.opencensus.io@v0.22.0/plugin/ochttp/server.go:86\nnet/http.serverHandler.ServeHTTP\n\t/usr/local/go/src/net/http/server.go:2774\nnet/http.(*conn).serve\n\t/usr/local/go/src/net/http/server.go:1878"
}
```


