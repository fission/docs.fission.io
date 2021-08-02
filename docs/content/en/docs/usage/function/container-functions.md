---
title: "Running container as functions"
draft: false
weight: 46
---

Note: Support for containers in **alpha**, we plan to improve experience over coming releases.
Your feedback is most appreciated to improve it.

With 1.14 release, Fission allows you to run your existing container as a function.

#### Running container image with Fission

`fission function run-container` provides required options to run an exiting container image as a Fission function.

```sh
$ fission function run-container --name cn-hello --image gcr.io/google-samples/node-hello:1.0 --port 8080
function 'cn-hello' created
```

Listing functions,

```bash
$ fission function list
NAME     ENV    EXECUTORTYPE MINSCALE MAXSCALE MINCPU MAXCPU MINMEMORY MAXMEMORY TARGETCPU SECRETS CONFIGMAPS
cn-hello        container    1        1        0      0      0         0         80
```

Test container function,

```bash
$ fission fn test --name cn-hello
Hello Kubernetes!
```

We have added `spec.podspec` in Function Spec which captures container function details. Know more about options for running container with Functions,

```sh
kubectl explain functions.spec.podspec
```

You can also generate function spec with Fission CLI.

```sh
$ fission spec init
Creating fission spec directory 'specs'
$ fission function run-container --name cn-hello --image gcr.io/google-samples/node-hello:1.0 --port 8080 --spec
Saving Function 'default/cn-hello' to 'specs/function-cn-hello.yaml'
$ cat specs/function-cn-hello.yaml
apiVersion: fission.io/v1
kind: Function
metadata:
  creationTimestamp: null
  name: cn-hello
  namespace: default
spec:
  InvokeStrategy:
    ExecutionStrategy:
      ExecutorType: container
      MaxScale: 1
      MinScale: 1
      SpecializationTimeout: 120
      TargetCPUPercent: 80
    StrategyType: execution
  environment:
    name: ""
    namespace: ""
  functionTimeout: 60
  idletimeout: 120
  package:
    packageref:
      name: ""
      namespace: ""
  podspec:
    containers:
    - image: gcr.io/google-samples/node-hello:1.0
      name: cn-hello
      ports:
      - containerPort: 8080
        name: http-env
      resources: {}
  resources: {}
```

### Running Next.js app container with Fission

You can run a sample Next.js based app.

```sh
$ fission fn run-container --name=nextapp --image fission/next-sample-app:1.0.0 --port 3000
function 'nextapp' created
$ fission route create --name nextapp --function nextapp --prefix /nextapp --keepprefix
trigger 'nextapp' created
```

Visit app URL, `http://<router_url>/nextapp/`

You can refer it source for the application [here](https://github.com/fission/examples/tree/master/container-functions/next-app).

### Command options

You can also use alias, `fission fn runc` instead of `fission function run-container` OR
`fission fn updatec` instead of `fission fn updatec`.

Please check command help for more options while creating container based functions.
