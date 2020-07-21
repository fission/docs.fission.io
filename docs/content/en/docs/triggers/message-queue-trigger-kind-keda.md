---
title: "MQ Trigger: Keda based"
date: 2020-07-20T14:30:01+05:30
weight: 1
---

*This is a new feature getting released in 1.11 and will be enhanced in coming releases*

# Brief Introduction

Message queue trigger integration with KEDA has enabled autoscaling of trigger handler. Now, there are two kinds of message queue triggers:

1. fission
2. keda

Message queue trigger kind can be specified using "mqtkind" flag. By default, "mqtkind" is set to "fission" which creates regular [message queue trigger](https://docs.fission.io/docs/triggers/message-queue-trigger/). To create message queue trigger of kind keda one must specify "mqtkind=keda".

# Architecture

{{< img "../assets/mqt-kind-keda.png" "" "40em" "1" >}}

1. The user creates a trigger - for Keda based integration you have to specify the “mqtkind=keda” and add all relevant parameters. These parameters are different for each message queue and hence are encapsulated in a metadata field and follow a key-value format. As soon as you create the MQ Trigger, Fission creates a ScaledObject and a consumer deployment object which is referenced by ScaledObject. The ScaledObject is a Keda’s way of encapsulating the consumer deployment and all relevant information for connecting to an event source! Keda goes ahead and creates a HPA for the deployment and scales down the deployment to zero.
2. As the message arrives in the event source - the Keda will scale the HPA and deployment from 0 - to 1 for consuming messages. As more messages arrive the deployment is scaled beyond 1 automatically too.
3. The deployment is like an connector which consumes messages from the source and then calls a function.
4. The function consumes the message and returns the response to deployment pods, which puts the response in response topic and errors in error topic as may be applicable.

# Usage

### Prerequisite
- KEDA must be installed on your cluster
- Message queue trigger KEDA integration should be enabled. 

To enable integration set the value "enabled: true" under "mqt_keda" in charts/fission-all/values.yaml or charts/fission-core/values.yaml depending on your installation.

When you a create message queue trigger of kind keda, it creates a [ScaledObject and a TriggerAuthentication](https://keda.sh/docs/1.5/concepts/#custom-resources-crd). The ScaledObjects represent the desired mapping between an event source (e.g. Apache Kafka) and the Kubernetes deployment. A ScaledObject may also reference a TriggerAuthentication which contains the authentication configuration or secrets to monitor the event source. For successful creation of these objects, user should specify the following fields while creating a message queue trigger.

1. pollinginterval: Interval to check the message source for up/down scaling operation of consumers
2. cooldownperiod: The period to wait after the last trigger reported active before scaling the consumer back to 0
3. minreplicacount: Minimum number of replicas of consumers to scale down to
4. maxreplicacount: Maximum number of replicas of consumers to scale up to
5. metadata: Metadata needed for connecting to source system in format: --metadata key1=value1 --metadata key2=value2
6. secret: Name of secret object (secret fields must be similarly specified as in mentioned for [particular scaler](https://keda.sh/docs/1.5/scalers/])

## Apache Kafka
Lets create message queue trigger with information of the kafka scaler with sasl auth enabled [described here](https://keda.sh/docs/1.5/scalers/apache-kafka/#example).

```bash
$ fission mqt create --name mqttest --function consumer --mqtype kafka \
--mqtkind keda --topic test-topic --resptopic response-topic \
--errortopic error-topic --maxretries 3 --metadata bootstrapServers=localhost:9092 \
--metadata consumerGroup=my-group --metadata topic=test-topic \
--metadata lagThreshold=50 --pollinginterval=30
```

For complete tutorial refer [this blog post](link to be updated).
