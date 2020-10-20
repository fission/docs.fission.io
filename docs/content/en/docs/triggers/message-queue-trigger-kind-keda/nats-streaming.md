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

## Overview

Before we dive into details, let's walk through overall flow of event and functions involved.

1. A Go producer function (producerfunc) which acts as a producer and drops a message in a NATS queue named `request`.
2. Fission NATS Streaming trigger activates and invokes another function (consumerfunc) with message received from producerfunc.
3. The consumer function (consumerfunc) gets body of message and returns a response.
4. Fission NATS streaming trigger takes the response of consumer function (consumerfunc) and drops the message in a response queue named `response`.
   If there is an error, the message is dropped in error queue named `error`.

{{% notice info %}}
NATS streaming keda connector uses NATS monitoring to scale the deployment, to enable monitoring in nats we need to pass flags as below, you can get more [information here](https://docs.nats.io/nats-server/configuration/monitoring)

```bash
-m, --http_port PORT             HTTP PORT for monitoring  
-ms,--https_port PORT            Use HTTPS PORT for monitoring  

$ nats-server -m 8222
```

To verify if the nats streaming server is us and running check below url
```bash
$ curl http://localhost:8222/streaming/channelsz?channel=request
```
{{% /notice %}}

## Building the app

### Producer Function

The producer function is a go program which creates a message with timestamp and drops into a NATS streaming queue `request`.
For brevity all values have been hard coded in the code itself.

``` go
package main

import (
	"log"
	"strconv"

	"github.com/nats-io/nats.go"
	"github.com/nats-io/stan.go"
)

func main() {
	nc, err := nats.Connect("nats://localhost:4222")
	if err != nil {
		log.Fatal(err)
	}
	sc, err := stan.Connect("test-cluster", "stan-sub", stan.NatsConn(nc))
	if err != nil {
		log.Fatal(err)
	}
	for i := 100; i < 200; i++ {
		sc.Publish("request", []byte("Test"+strconv.Itoa(i)))
	}

	select {}
}

```
We are now ready to package this code and create a function so that we can execute it later.
Following commands will create a environment, package and function.
Verify that build for package succeeded before proceeding.

```sh
$ fission env create --name goenv --image fission/go-env --builder fission/go-builder
$ zip -qr nats.zip *
$ fission package create --env goenv --src nats.zip
Package 'nats-zip-cy16' created
$ fission fn create --name producerfunc --env goenv --pkg natss-zip-cy16 --entrypoint Handler
$ fission package info --name nats-zip-cy16
Name:        nats-zip-cy16
Environment: goenv
Status:      succeeded
Build Logs:
Building in directory /usr/src/nats-zip-cy16-o3vrx1
```

### Consumer function

The consumer function is nodejs function which takes the body of the request, appends a "Hello" and returns the resulting string.

```js
module.exports = async function (context) {
    console.log(context.request.body);
    let obj = context.request.body;
    return {
        status: 200,
        body: "Hello "+ JSON.stringify(obj)
    };
}
```

Let's create the environment and function:

```bash
$ fission env create --name nodeenv --image fission/node-env
$ fission fn create --name consumerfunc --env nodeenv --code hellonats.js
```

### Connecting via trigger

We have both the functions ready but the connection between them is the missing glue.
Let's create a message queue trigger which will invoke the consumerfunc every time there is a message in `request` queue.
The response will be sent to `response` queue and in case of consumerfunc invocation fails, the error is written to `error` queue.

```bash
$ fission mqt create  --name natstest --function helloworld --mqtype stan --topic request --resptopic response --mqtkind keda --errortopic error --maxretries 3 --metadata subject=request --metadata queueGroup=grp1 --metadata durableName=due --metadata natsServerMonitoringEndpoint=nats-monitor.default.svc.cluster.local:8222 --metadata clusterId=test-cluster --metadata clientId=stan-sub --metadata natsServer=nats://nats-monitor:4222
```
Parameter list:
- natsServerMonitoringEndpoint - Location of the Nats Streaming Monitoring
- queueGroup - Queue group name of the subscribers
- durableName - Must identify the durability name used by the subscribers
- subject - Name of channel
- natsServer - Location of the Nats Streaming
- clusterId - StanClusterID to form a connection to the NATS Streaming subsystem
- clientId  - Used by the server to uniquely identify, and restrict, a given client.

### Testing it out

Let's invoke the producer function so that the queue `request` gets some messages and we can see the consumer function in action.

```bash
$ fission fn test --name  
Successfully sent to input
```

There are a couple of ways you can verify that the consumerfunc is called:

- Check the logs of `mqtrigger-nats` pods:

```text
{"level":"info","ts":1603169199.4120834,"caller":"nats-streaming-http-connector/main.go:59","msg":"NATs consumer up and running!..."}
{"level":"info","ts":1603169209.8942852,"caller":"nats-streaming-http-connector/main.go:35","msg":"Test100"}
{"level":"info","ts":1603169209.8965409,"caller":"nats-streaming-http-connector/main.go:48","msg":"Done processing message","messsage":"Test100"}
{"level":"info","ts":1603169209.8967056,"caller":"nats-streaming-http-connector/main.go:35","msg":"Test101"}
{"level":"info","ts":1603169209.900879,"caller":"nats-streaming-http-connector/main.go:48","msg":"Done processing message","messsage":"Test101"}
```

- Go to nats streaming server queue and check if messages are comming in response queue


## Introducing an error

Let's introduce an error scenario - instead of consumer function returning a 200, you can return 400 which will cause an error:

```js
module.exports = async function (context) {
    console.log(context.request.body);
    let obj = context.request.body;
    return {
        status: 400,
        body: "Hello "+ JSON.stringify(obj)
    };
}
```

Update the function with new code and invoke the producer function:

```bash
$ fission fn update --name consumerfunc --code hellonats.js

$ fission fn test --name producerfunc
Successfully sent to input
```

We can verify the message in error queue as we did earlier:

- Go to nats streaming server and check if messages are comming in error queue

