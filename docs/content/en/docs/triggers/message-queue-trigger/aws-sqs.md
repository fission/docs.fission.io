---
title: "AWS SQS"
draft: false
weight: 78
---

This tutorial will demonstrate how to use a AWS SQS trigger to invoke a function.
We'll assume you have Fission and Kubernetes installed with AWS SQS Queue integration installed.
If not, please head over to the [install guide]({{% ref "../../installation/_index.en.md" %}}).

You will also need AWS SQS setup which is reachable from the Fission Kubernetes cluster.

## Installation

If you want to setup SQS on the Kubernetes cluster, you can use the [information here](https://github.com/localstack/localstack) or you can create queue using your aws account [docs](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-setting-up.html).

## Overview

Before we dive into details, let's walk through overall flow of event and functions involved.

1. A Go producer function (producerfunc) or aws cli command which acts as a producer and drops a message in a SQS queue named `input`.
2. Fission SQS trigger activates and invokes another function (consumerfunc) with body of SQS message.
3. The consumer function (consumerfunc) gets body of message and returns a response.
4. Fission SQS trigger takes the response of consumer function (consumerfunc) and drops the message in a response queue named `output`.
   If there is an error, the message is dropped in error queue named `error`.

{{% notice info %}}
When communicating to localstack we need aws cli installed in the respactive container(deployment). This is because it uses aws configuration to connect to localstack.
Below are the commmand to create and send the message to a queue

```bash
aws sqs create-queue --queue-name input
aws sqs create-queue --queue-name output
aws sqs create-queue --queue-name error

aws sqs list-queues

aws sqs send-message --queue-url https://sqs.ap-south-1.amazonaws.com/xxxxxxxx/input --message-body 'Test Message!'
```
{{% /notice %}}

## Building the app

### Producer Function

The producer function is a go program which creates a message with timestamp and drops into a queue `input`.
For brevity all values have been hard coded in the code itself.

``` go
package main
​
import (
	"fmt"
	"log"
​
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/sqs"
)
​
func main() {
​
	queueURL := "https://sqs.ap-south-1.amazonaws.com/xxxxxxxxxxxx/input"
	region := "ap-south-1"
	config := &aws.Config{
		Region:      &region,
		Credentials: credentials.NewStaticCredentials("xxxxxxxxxxxx", "xxxxxxxxxx", ""),
	}
​
	sess, err := session.NewSession(config)
	if err != nil {
		log.Panic("Error while creating session")
	}
	svc := sqs.New(sess)
​
	for i := 100; i < 200; i++ {
		msg := fmt.Sprintf("Hello Msg %v", i+1)
		_, err := svc.SendMessage(&sqs.SendMessageInput{
			DelaySeconds: aws.Int64(10),
			MessageBody:  &msg,
			QueueUrl:     &queueURL,
		})
		if err != nil {
			log.Panic("Error while writing message")
		}
	}
}
```

Since the go program uses SQS queue, we need to create the input queue to run the above program.

We are now ready to package this code and create a function so that we can execute it later.
Following commands will create a environment, package and function.
Verify that build for package succeeded before proceeding.

```sh
$ fission env create --name goenv --image fission/go-env --builder fission/go-builder
$ zip -qr sqs.zip *
$ fission package create --env goenv --src sqs.zip
Package 'sqs-zip-xpoi' created
$ fission fn create --name producerfunc --env goenv --pkg sqs-zip-xpoi --entrypoint Handler
$ fission package info --name sqs-zip-xpoi
Name:        sqs-zip-xpoi
Environment: go-sqs
Status:      succeeded
Build Logs:
Building in directory /usr/src/sqs-zip-xpoi-1bicov
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
$ fission fn create --name consumerfunc --env nodeenv --code hellosqs.js
```

### Connecting via trigger

We have both the functions ready but the connection between them is the missing glue.
Let's create a message queue trigger which will invoke the consumerfunc every time there is a message in `input` queue.
The response will be sent to `output` queue and in case of consumerfunc invocation fails, the error is written to `error` queue.

```bash
$ fission mqt create  --name sqstest --function consumerfunc --mqtype aws-sqs-queue --topic input --resptopic output --mqtkind keda --errortopic error --maxretries 3 --metadata queueURL=https://sqs.ap-south-1.amazonaws.com/xxxxxxxx/input --metadata awsRegion=ap-south-1 --cooldownperiod=30 --pollinginterval=5 --secret awsSecrets
```

{{% notice info %}}
In case of localstack we don't have to give secret, for connecting to aws we need to create the secret e.g.
```bash
 kubectl create secret generic awsSecrets --from-env-file=./secret.yaml
 ```
and secret.yaml file should contain values like
```yaml
AWS_ACCESS_KEY_ID=foo
AWS_SECRET_ACCESS_KEY=bar
```
{{% /notice %}}

### Testing it out

Let's invoke the producer function so that the queue `input` gets some messages and we can see the consumer function in action.

```bash
$ fission fn test --name producerfunc
Successfully sent to input
```

There are a couple of ways you can verify that the consumerfunc is called:

- Check the logs of `mqtrigger-sqs` pods:

```text
{"level":"info","ts":1602057916.444865,"caller":"app/main.go:165","msg":"message deleted"}
{"level":"info","ts":1602057917.4880567,"caller":"app/main.go:165","msg":"message deleted"}
```

- Go to aws SQS queue and check if messages are comming in output queue


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
$ fission fn update --name consumerfunc --code hellosqs.js

$ fission fn test --name producerfunc
Successfully sent to input
```

We can verify the message in error queue as we did earlier:

- Go to aws SQS queue and check if messages are comming in error queue

