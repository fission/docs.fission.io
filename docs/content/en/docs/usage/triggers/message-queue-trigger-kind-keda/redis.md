---
title: "Redis"
date: 2021-08-30T06:49:42+05:30
---

This tutorial will demonstrate how to use a Redis List trigger to invoke a function.
We'll assume you have Fission and Kubernetes installed.
If not, please head over to the [install guide]({{% ref "../../../installation/_index.en.md" %}}).

You will also need Redis setup which is reachable from the Fission Kubernetes cluster.

## Installation

If you want to setup Redis server on the Kubernetes cluster, you can use the [information here](https://ot-container-kit.github.io/redis-operator/guide).

## Overview

Before we dive into details, let's walk through overall flow of event and functions involved.

1. A Go producer function (producerfunc) which acts as a producer and drops a message in a Redis queue named `request-topic`.
2. Fission Redis trigger activates and invokes another function (consumerfunc) with message received from producerfunc.
3. The consumer function (consumerfunc) gets body of message and returns a response.
4. Fission Redis trigger takes the response of consumer function (consumerfunc) and drops the message in a response queue named `response-topic`.
   If there is an error, the message is dropped in error queue named `error-topic`.

## Building the app

### Producer Function

The producer function is a go program which creates a message with timestamp and drops into a queue `request-topic`.
For brevity all values have been hard coded in the code itself.

```go
package main
​
import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"
	"time"

	"github.com/go-redis/redis/v8"
)

type publish_data struct {
	Sid  int    `json:"sid"`
	Data string `json:"data"`
	Time int64  `json:"time"`
}

func Handler(w http.ResponseWriter, r *http.Request) {

	address := "redis-headless.ot-operators.svc.cluster.local:6379"
	password := ""
	listName := "request-topic"

	var ctx = context.Background()
	rdb := redis.NewClient(&redis.Options{
		Addr:     address,
		Password: password,
		DB:       0,
	})

	for i := 0; i < 10; i++ {
		current_time := time.Now()
		secs := current_time.Unix()
		resp := publish_data{
			Sid:  i,
			Data: "Message number: " + strconv.Itoa(i+1),
			Time: secs,
		}
		resp_json, _ := json.Marshal(resp)
		_, err := rdb.RPush(ctx, listName, resp_json).Result()
		if err != nil {
			w.Write([]byte(fmt.Sprintf("Failed to publish message to topic %s: %v", listName, err)))
			return
		}
	}
	w.Write([]byte(fmt.Sprintf("Successfully sent to %s", listName)))
}
```

We are now ready to package this code and create a function so that we can execute it later.
Following commands will create a environment, package and function.
Verify that build for package succeeded before proceeding.

```sh
$ mkdir redis_test && cd redis_test
$ go mod init

# create a producer.go file with above code replacing the placeholder values with actual ones
$ go mod tidy
$ zip -qr redis.zip *

$ fission env create --name goenv --image fission/go-env-1.13 --builder fission/go-builder-1.13
$ fission package create --env goenv --src redis.zip
$ fission fn create --name producerfunc --env goenv --pkg redis-zip-zlre --entrypoint Handler
$ fission package info --name redis-zip-zlre
Name:        redis-pkg
Environment: goenv
Status:      succeeded
Build Logs:
Building in directory /usr/src/redis-zip-zlre-2gucll
```

### Consumer function

The consumer function is nodejs function which takes the body of the request, appends a "Hello" and returns the resulting string.

```js
module.exports = async function (context) {
  console.log(context.request.body);
  let obj = context.request.body;
  return {
    status: 200,
    body: "Hello " + JSON.stringify(obj),
  };
};
```

Let's create the environment and function:

```bash
$ fission env create --name nodeenv --image fission/node-env
$ fission fn create --name consumerfunc --env nodeenv --code hello.js
```

### Connecting via trigger

We have both the functions ready but the connection between them is the missing glue.
Let's create a message queue trigger which will invoke the consumerfunc every time there is a message in `request-topic` queue.
The response will be sent to `response-topic` queue and in case of consumerfunc invocation fails, the error is written to `error-topic` queue.

```bash
$ fission mqt create --name redistest --function consumerfunc --mqtype redis --mqtkind keda --topic request-topic --resptopic response-topic --errortopic error-topic --maxretries 3 --metadata address=redis-headless.ot-operators.svc.cluster.local:6379 --metadata listLength=10 --metadata listName=request-topic
```

Parameter list:

- address - Host and port of redis server
- listLength - Length of list after which the function should be triggered
- listName - The list to be monitored

### Testing it out

Let's invoke the producer function so that the queue `request-topic` gets some messages and we can see the consumer function in action.

```bash
$ fission fn test --name producerfunc
Successfully sent to request-topic
```

There are a couple of ways you can verify that the consumerfunc is called:

- Check the logs of `mqtrigger-redis` pods:

```text
{"level":"info","ts":1630296782.86601,"caller":"app/main.go:58","msg":"Message sending to response successful"}
{"level":"info","ts":1630296782.8708184,"caller":"app/main.go:58","msg":"Message sending to response successful"}
```

- Connect to your redis server and check if messages are coming in the `response-topic` queue.

## Introducing an error

Let's introduce an error scenario - instead of consumer function returning a 200, you can return 400 which will cause an error:

```js
module.exports = async function (context) {
  console.log(context.request.body);
  let obj = context.request.body;
  return {
    status: 400,
    body: "Hello " + JSON.stringify(obj),
  };
};
```

Update the function with new code and invoke the producer function:

```bash
$ fission fn update --name consumerfunc --code hello.js

$ fission fn test --name producerfunc
Successfully sent to input
```

We can verify the message in error queue as we did earlier:

- Connect to your redis server and check if messages are coming in `error-topic` queue.
