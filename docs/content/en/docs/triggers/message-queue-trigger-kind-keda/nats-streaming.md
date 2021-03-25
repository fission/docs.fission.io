---
title: "NATS Streaming"
draft: false
weight: 4
---

This tutorial will demonstrate how to use a NATS Streaming trigger to invoke a function.
We'll assume you have Fission and Kubernetes installed.
If not, please head over to the [install guide]({{% ref "../../installation/_index.en.md" %}}).

You will also need NATS Streaming server setup which is reachable from the Fission Kubernetes cluster.

## Installation

If you want to setup NATS Streaming server on the Kubernetes cluster, you can use the [information here](https://github.com/nats-io/nats-streaming-server) or you can check the documentation for nats streaming [docs](https://docs.nats.io/nats-on-kubernetes/minimal-setup).  
Also i have created a yaml file in nats-streaming-http-connector/test/nats-streaming-server folder, you can use that directly(in that i have already configured monitoring).


{{% notice info %}}
NATS streaming keda connector uses NATS monitoring to scale the deployment, to enable monitoring in nats we need to pass flags as below, you can get more [information here](https://docs.nats.io/nats-server/configuration/monitoring)

```bash
-m, --http_port PORT             HTTP PORT for monitoring    
-ms,--https_port PORT            Use HTTPS PORT for monitoring  

```
{{% /notice %}}

```sh
$ kubectl apply -f nats-dep.yaml
NAME                                         READY   STATUS    RESTARTS   AGE
nats-streaming-deployment-646768fcfd-qtpmk   1/1     Running   0          8s
```

Verify if monitoring endpoint is rechable by exec into any container
```sh
$ kubectl create deployment test --image=nginx
$ kubectl exec -it test-844b65666c-8kppc /bin/bash   
$ curl nats.default.svc.cluster.local:8222
<html lang="en">
   <head>
    <link rel="shortcut icon" href="http://nats.io/img/favicon.ico">
    <style type="text/css">
      body { font-family: "Century Gothic", CenturyGothic, AppleGothic, sans-serif; font-size: 22; }
      a { margin-left: 32px; }
    </style>
  </head>
  <body>
    <img src="http://nats.io/img/logo.png" alt="NATS">
    <br/>
	<a href=/varz>varz</a><br/>
	<a href=/connz>connz</a><br/>
	<a href=/routez>routez</a><br/>
	<a href=/gatewayz>gatewayz</a><br/>
	<a href=/leafz>leafz</a><br/>
	<a href=/subsz>subsz</a><br/>
    <br/>
    <a href=https://docs.nats.io/nats-server/configuration/monitoring.html>help</a>
  </body>
</html>
```
## Overview

Before we dive into details, let's walk through overall flow of event and functions involved.

1. A Go producer function (producer) which acts as a producer and drops a message in a NATS queue named `request`.
2. Fission NATS Streaming trigger activates and invokes another function (consumer) with message received from producer.
3. The consumer function (consumer) gets body of message and returns a response.
4. Fission NATS streaming trigger takes the response of consumer function (consumer) and drops the message in a response queue named `response`.
   If there is an error, the message is dropped in error queue named `error`.



## Building the app

### Producer Function

The producer function is a go program which creates a message and drops into a NATS streaming queue `request`.
For brevity all values have been hard coded in the code itself.
There are different ways of loading this function into cluster, i have tried by creating the deployment. The docker and other file is present under nats-streaming-http-connector/test/producer folder.

Below are the steps i did
```sh
$ docker build . -t producer:latest 
$ kind load docker-image producer:latest --name kind-1 
$ kubectl apply -f deployment.yaml //replicas is set to 0 when deployed
```

``` go
package main

import (
	"fmt"
	"log"
	"strconv"

	"github.com/nats-io/nats.go"
	"github.com/nats-io/stan.go"
)

func main() {
	nc, err := nats.Connect("nats://nats:4222")
	if err != nil {
		log.Fatal(err)
	}
	sc, err := stan.Connect("test-cluster", "stan-sub", stan.NatsConn(nc))
	if err != nil {
		log.Fatal(err)
	}
	for i := 100; i < 500; i++ {
		sc.Publish("hello", []byte("Test"+strconv.Itoa(i)))
	}
	fmt.Println("Published all the messages")
	
	select {}
}


```

Verify that deployment succeeded before proceeding.
```sh
$ kubectl get deployment nats-pub 
NAME       READY   UP-TO-DATE   AVAILABLE   AGE
nats-pub   0/0     0            0           

```
### Consumer function

The consumer function is golang function which takes the body of the request, appends a "Hello" and returns the resulting string, the code is present in nats-streaming-http-connector/test/consumer

```go
package main

import (
	"fmt"
	"io/ioutil"
	"net/http"
)

// Handler is the entry point for this fission function
func Handler(w http.ResponseWriter, r *http.Request) {
	body, err := ioutil.ReadAll(r.Body)
	if err != nil {
		http.Error(w, "Error reading request body",
			http.StatusInternalServerError)
	}
	results := string(body)
	fmt.Println(results)
	w.Write([]byte("Hello " + results))
}

```

Let's create the environment and function:

```bash
$ fission environment create --name go --image fission/go-env-1.13 --builder fission/go-builder-1.13
$ fission fn create --name helloworld --env go --src hello.go --entrypoint Handler
```

### Connecting via trigger

We have both the functions ready but the connection between them is the missing glue.
Let's create a message queue trigger which will invoke the consumerfunc every time there is a message in `request` queue.
The response will be sent to `response` queue and in case of consumerfunc invocation fails, the error is written to `error` queue.

```bash
$ fission mqt create --name natstest --function helloworld --mqtype stan --topic hello --resptopic response --mqtkind keda --errortopic error --maxretries 3 --metadata subject=hello --metadata queueGroup=grp1 --metadata durableName=due --metadata natsServerMonitoringEndpoint=nats.default.svc.cluster.local:8222 --metadata clusterId=test-cluster --metadata natsServer=nats://nats:4222
```
Parameter list:
- natsServerMonitoringEndpoint - Location of the Nats Streaming Monitoring
- queueGroup - Queue group name of the subscribers
- durableName - Must identify the durability name used by the subscribers
- subject - Name of channel
- natsServer - Location of the Nats Streaming
- clusterId - StanClusterID to form a connection to the NATS Streaming subsystem // it will be same as in producer function

### Testing it out

Let's invoke the producer function so that the queue `request` gets some messages and we can see the consumer function in action.

```bash
$ kubectl scale --replicas=1 deployment/nats-pub
deployment.apps/nats-pub scaled
```

There are a couple of ways you can verify that the consumerfunc is called:

- Check the logs of `natstest` pods:
```sh
k logs natstest-b4f6c6579-q2bxd -f  
```

```text
{"level":"info","ts":1616588727.6284368,"caller":"app/main.go:50","msg":"Done processing message","messsage":"Hello, world!\n"}
{"level":"info","ts":1616588727.6291118,"caller":"app/main.go:36","msg":"Test102"}
{"level":"info","ts":1616588732.3232052,"caller":"app/main.go:50","msg":"Done processing message","messsage":"Hello, world!\n"}
{"level":"info","ts":1616588732.3247235,"caller":"app/main.go:36","msg":"Test105"}
{"level":"info","ts":1616588735.3536534,"caller":"app/main.go:50","msg":"Done processing message","messsage":"Hello, world!\n"}
{"level":"info","ts":1616588735.35448,"caller":"app/main.go:36","msg":"Test107"}
{"level":"info","ts":1616588737.6849225,"caller":"app/main.go:50","msg":"Done processing message","messsage":"Hello, world!\n"}
```

- Go to nats streaming server queue and check if messages are comming in response queue


## Introducing an error

Let's introduce an error scenario - instead of consumer function returning a 200, you can return 400 which will cause an error:


```go
package main

import (
	"net/http"
)

// Handler is the entry point for this fission function
func Handler(w http.ResponseWriter, r *http.Request) {
	http.Error(w, "Error reading request body",
			http.StatusNotFound)
}

```

Update the function with new code and invoke the producer function:

```bash
$ fission fn update --name consumerfunc --code hello.go
$ kubectl scale --replicas=0 deployment/nats-pub 
$ kubectl scale --replicas=1 deployment/nats-pub 
```

We can verify the message in error queue as we did earlier:
```sh
{"level":"info","ts":1616589794.4876041,"caller":"app/main.go:62","msg":"NATs consumer up and running!..."}
{"level":"info","ts":1616589794.4877403,"caller":"app/main.go:36","msg":"Test138"}
{"level":"info","ts":1616589998.6383834,"caller":"app/main.go:39","msg":"request returned failure: 400. http_endpoint: http://router.fission/fission-function/helloworld, source: natstest"}
{"level":"info","ts":1616589998.6396098,"caller":"app/main.go:36","msg":"Test129"}

```

- Go to nats streaming server and check if messages are comming in error queue

