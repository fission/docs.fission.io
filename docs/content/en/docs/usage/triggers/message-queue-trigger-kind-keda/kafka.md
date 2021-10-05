---
title: "Kafka"
date: 2021-10-04T16:25:20+05:30
---

This tutorial will demonstrate how to use a Kafka trigger to invoke a function.
We'll assume you have Fission and Kubernetes installed.
If not, please head over to the [install guide]({{% ref "../../../installation/_index.en.md" %}}).

You will also need Redis setup which is reachable from the Fission Kubernetes cluster.

## Installation

If you want to setup Apache Kafka on the Kubernetes cluster, you can use the [information here](https://strimzi.io/docs/operators/latest/quickstart.html#proc-install-product-str).

## Overview

Before we dive into details, let's walk through overall flow of event and functions involved.

1. A Go producer function (producer) which acts as a producer and drops a message in a Kafka queue named `request-topic`.
2. Fission Kafka trigger activates and invokes another function (consumer) with message received from producer.
3. The consumer function (consumer) gets body of message and returns a response.
4. Fission Kafka trigger takes the response of consumer function (consumer) and drops the message in a response queue named `response-topic`.
   If there is an error, the message is dropped in error queue named `error-topic`.

## Building the app

### Kafka Topics

Create three Kafka topics as mentioned below, replace namespace and cluster accordingly.

1. Kafka topic for function invocation

```sh
cat << EOF | kubectl create -n my-kafka-project -f -
apiVersion: kafka.strimzi.io/v1beta1
kind: KafkaTopic
metadata:
  name: request-topic
  labels:
    strimzi.io/cluster: "my-cluster"
spec:
  partitions: 3
  replicas: 2
EOF
```

2. Kafta topic for function response

```sh
cat << EOF | kubectl create -n my-kafka-project -f -
apiVersion: kafka.strimzi.io/v1beta1
kind: KafkaTopic
metadata:
  name: response-topic
  labels:
    strimzi.io/cluster: "my-cluster"
spec:
  partitions: 3
  replicas: 2
EOF
```

3. Kafta topic for error response

```sh
cat << EOF | kubectl create -n my-kafka-project -f -
apiVersion: kafka.strimzi.io/v1beta1
kind: KafkaTopic
metadata:
  name: error-topic
  labels:
    strimzi.io/cluster: "my-cluster"
spec:
  partitions: 3
  replicas: 2
EOF
```

### Producer Function

The producer function is a go program which creates a message with timestamp and drops into a queue `request-topic`.
For brevity all values have been hard coded in the code itself.

```go
package main

import (
	"fmt"
	"net/http"
	"time"

	sarama "github.com/Shopify/sarama"
)

func Handler(w http.ResponseWriter, r *http.Request) {
	brokers := []string{"my-cluster-kafka-brokers.my-kafka-project.svc:9092"}
	producerConfig := sarama.NewConfig()
	producerConfig.Producer.RequiredAcks = sarama.WaitForAll
	producerConfig.Producer.Retry.Max = 100
	producerConfig.Producer.Retry.Backoff = 100
	producerConfig.Producer.Return.Successes = true
	producerConfig.Version = sarama.V1_0_0_0
	producer, err := sarama.NewSyncProducer(brokers, producerConfig)
	fmt.Println("Created a new producer ", producer)
	if err != nil {
		panic(err)
	}
	for msg := 1; msg <= 1000; msg++ {
		ts := time.Now().Format(time.RFC3339)
		message := fmt.Sprintf("{\"message_number\": %d, \"time_stamp\": \"%s\"}", msg, ts)
		_, _, err = producer.SendMessage(&sarama.ProducerMessage{
			Topic: "request-topic",
			Value: sarama.StringEncoder(message),
		})

		if err != nil {
			w.Write([]byte(fmt.Sprintf("Failed to publish message to topic %s: %v", "request-topic", err)))
			return
		}
	}
	w.Write([]byte("Successfully sent to request-topic"))
}
```

We are now ready to package this code and create a function so that we can execute it later.
Following commands will create a environment, package and function.
Verify that build for package succeeded before proceeding.

```sh
$ mkdir kafka_test && cd kafka_test
$ go mod init

# create a producer.go file with above code replacing the placeholder values with actual ones
$ go mod tidy
$ zip -qr kafka.zip *

$ fission env create --name go --image fission/go-env-1.12:1.10.0 --builder fission/go-builder-1.12:1.10.0
$ fission package create --env go --src kafka.zip
$ fission fn create --name producer --env go --pkg kafka-zip-zlre --entrypoint Handler
$ fission package info --name kafka-zip-zlre
Name:        kafka-pkg
Environment: go
Status:      succeeded
Build Logs:
Building in directory /usr/src/kafka-zip-zlre-2gucll
```

### Consumer function

The consumer function is nodejs function which takes the body of the request, appends a "Hello" and returns the resulting string.

```js
module.exports = async function (context) {
  console.log(context.request.body);
  let obj = context.request.body;
  return {
    status: 200,
    body: "Consumer Response " + JSON.stringify(obj),
  };
};
```

Let's create the environment and function:

```bash
$ fission env create --name nodeenv --image fission/node-env
$ fission fn create --name consumer --env nodeenv --code consumer.js
```

### Connecting via trigger

We have both the functions ready but the connection between them is the missing glue.
Let's create a message queue trigger which will invoke the consumer function every time there is a message in `request-topic` queue.
The response will be sent to `response-topic` queue and in case of consumer function invocation fails, the error is written to `error-topic` queue.

```bash
$ fission mqt create --name kafkatest --function consumer --mqtype kafka --mqtkind keda --topic request-topic --resptopic response-topic --errortopic error-topic --maxretries 3 --metadata bootstrapServers=my-cluster-kafka-brokers.my-kafka-project.svc:9092 --metadata consumerGroup=my-group --metadata topic=request-topic  --cooldownperiod=30 --pollinginterval=5
```

Parameter list:

- bootstrapServers - Kafka brokers “hostname:port” to connect to for bootstrap.
- consumerGroup - Name of the consumer group used for checking the offset on the topic and processing the related lag.
- topic - Name of the topic on which processing the offset lag.

### Testing it out

Let's invoke the producer function so that the queue `request-topic` gets some messages and we can see the consumer function in action.

```bash
$ fission fn test --name producer
Successfully sent to request-topic
```

There are a couple of ways you can verify that the consumer is called:

- Check the logs of `mqtrigger-kafka` pods:

```text
{"level":"info","ts":1630296782.86601,"caller":"app/main.go:58","msg":"Message sending to response successful"}
{"level":"info","ts":1630296782.8708184,"caller":"app/main.go:58","msg":"Message sending to response successful"}
```

- Connect to your kafka cluster and check if messages are coming in the `response-topic` queue.

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
$ fission fn update --name consumer --code hello.js

$ fission fn test --name producer
Successfully sent to input
```

We can verify the message in error queue as we did earlier:

- Connect to your kafka cluster and check if messages are coming in `error-topic` queue.
