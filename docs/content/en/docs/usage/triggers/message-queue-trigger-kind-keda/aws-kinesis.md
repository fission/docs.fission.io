---
title: "AWS Kinesis"
draft: false
weight: 3
---

This tutorial will demonstrate how to use a AWS Kinesis trigger to invoke a function.
We'll assume you have Fission and Kubernetes installed.
If not, please head over to the [install guide]({{% ref "../../../installation/_index.en.md" %}}).

You will also need AWS Kinesis setup which is reachable from the Fission Kubernetes cluster.

## Installation

If you want to setup Kinesis on the Kubernetes cluster, you can use the [information here](https://github.com/localstack/localstack) or you can create streams using your aws account [docs](https://aws.amazon.com/kinesis/data-streams/getting-started/?nc=sn&loc=3).  

Also note that, if you are using localstack then it is only good for testing and dev environments and not for production usage. 

## Overview

Before we dive into details, let's walk through overall flow of event and functions involved.

1. A Go producer function (producerfunc) or aws cli command which acts as a producer and drops a message in a Kinesis stream named `request`.
2. Fission Kinesis trigger activates and invokes another function (consumerfunc) with body of Kinesis message.
3. The consumer function (consumerfunc) gets body of message and returns a response.
4. Fission Kinesis trigger takes the response of consumer function (consumerfunc) and drops the message in a response stream named `response`.
   If there is an error, the message is dropped in error stream named `error`.

{{% notice info %}}
When communicating to localstack we need aws cli installed in the respactive container(deployment). This is because it uses aws configuration to connect to localstack.
Below are the commmand to create and send the message to a stream

```bash
$ aws kinesis create-stream --shard-count 2  --stream-name request
$ aws kinesis create-stream --shard-count 1  --stream-name response
$ aws kinesis create-stream --shard-count 1  --stream-name error
$ aws kinesis list-streams
$ aws kinesis put-record --stream-name request --partition-key 111 --data 'Test Message'
```
{{% /notice %}}

## Building the app

### Producer Function

The producer function is a go program which creates a message with timestamp and drops into a kinesis stream `request`.
For brevity all values have been hard coded in the code itself.

``` go
package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/kinesis"
)

type message struct {
	Content string `json:"content"`
}

func Handler(w http.ResponseWriter, r *http.Request) {
	region := "ap-south-1"
	config := &aws.Config{
		Region:      &region,
		Credentials: credentials.NewStaticCredentials("xxxxxxxxxxxx", "xxxxxxxxxx", ""),
	}

	s, err := session.NewSession(config)
	if err != nil {
		w.Write([]byte(fmt.Sprintf("error creating a session: %v", err)))
		return
	}

	kc := kinesis.New(s)
	for i := 11; i <= 20; i++ {
		record, err := json.Marshal(&message{
			Content: fmt.Sprintf("message count %v", i+1),
		})

		if err != nil {
			w.Write([]byte(fmt.Sprintf("error marshalling the message: %v", err)))
			return
		}
		params := &kinesis.PutRecordInput{
			Data:         record,                      // required
			PartitionKey: aws.String(strconv.Itoa(i)), // required
			StreamName:   aws.String("request"),       // required
		}
		_, err = kc.PutRecord(params)
		if err != nil {
			w.Write([]byte(fmt.Sprintf("error putting a record: %v", err)))
			return
		}
	}
	w.Write([]byte("messages sent successfully"))
}
```

Since the go program uses Kinesis stream, we need to create the request stream to run the above program.

We are now ready to package this code and create a function so that we can execute it later.
Following commands will create a environment, package and function.
Verify that build for package succeeded before proceeding.

```sh
$ fission env create --name goenv --image fission/go-env --builder fission/go-builder
$ zip -qr kinesis.zip *
$ fission package create --env goenv --src kinesis.zip
Package 'kinesis-zip-cy16' created
$ fission fn create --name producerfunc --env goenv --pkg kinesis-zip-cy16 --entrypoint Handler
$ fission package info --name kinesis-zip-cy16
Name:        kinesis-zip-cy16
Environment: goenv
Status:      succeeded
Build Logs:
Building in directory /usr/src/kinesis-zip-cy16-o3vrx1
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
$ fission fn create --name consumerfunc --env nodeenv --code hellokinesis.js
```

### Connecting via trigger

We have both the functions ready but the connection between them is the missing glue.
Let's create a message queue trigger which will invoke the consumerfunc every time there is a message in `request` stream.
The response will be sent to `response` stream and in case of consumerfunc invocation fails, the error is written to `error` stream.

```bash
$ fission mqt create  --name kinesisdeployment --function helloworld --mqtype aws-kinesis-stream --topic request --resptopic response --mqtkind keda --errortopic error --maxretries 3 --metadata streamName=request --metadata shardCount=2 --metadata awsRegion=ap-south-1 --secret awsSecrets
```
Parameter list:
- streamName - Name of AWS Kinesis Stream
- awsRegion - AWS Region for the Kinesis Stream
- shardCount - The target value that a Kinesis data streams consumer can handle.
- secret - AWS credentials require to connect the stream e.g. below

{{% notice info %}}
if we are using localstack we don't have to give secret but if we are using aws to create kinesis stream we need to provide the secret, below is the example to create secret
```bash
 $ kubectl create secret generic awsSecrets --from-env-file=./secret.yaml
 ```
and secret.yaml file should contain values like
```yaml
AWS_ACCESS_KEY_ID=foo
AWS_SECRET_ACCESS_KEY=bar
```
{{% /notice %}}

### Testing it out

Let's invoke the producer function so that the stream `request` gets some messages and we can see the consumer function in action.

```bash
$ fission fn test --name  
Successfully sent to input
```

There are a couple of ways you can verify that the consumerfunc is called:

- Check the logs of `mqtrigger-kinesis` pods:

```text
{"level":"info","ts":1603106377.3910372,"caller":"aws-kinesis-http-connector/main.go:212","msg":"done processing message","shardID":"shardId-000000000001","message":"Hello Msg 112"}
{"level":"info","ts":1603106377.3916092,"caller":"aws-kinesis-http-connector/main.go:212","msg":"done processing message","shardID":"shardId-000000000000","message":"Hello Msg 111"}
```

- Go to aws Kinesis stream and check if messages are comming in response stream


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
$ fission fn update --name consumerfunc --code hellokinesis.js

$ fission fn test --name producerfunc
Successfully sent to input
```

We can verify the message in error stream as we did earlier:

- Go to aws Kinesis stream and check if messages are comming in error stream

