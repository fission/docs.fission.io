---
title: "NATS Streaming"
draft: false
weight: 64
---

#### Installation

Fission now install NATS Streaming service by default while helm installation.

You should see a pod with `nats-streaming` prefix with following command.

```bash
$ kubectl -n fission get pod -l svc=nats-streaming
```

If the NATS Streaming is enabled, a kubernetes deployment called `mqtrigger-nats-streaming` will be created as well.

```bash
$ kubectl -n fission get deploy|grep mqtrigger-nats-streaming
```    

The MQTrigger talks to NATS streaming through kubernetes service, you can get the service information with following command.

```bash
$ kubectl -n fission get svc -l svc=nats-streaming
NAME             TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)    AGE
nats-streaming   ClusterIP   10.97.32.55   <none>        4222/TCP   6d
```

{{% notice tip %}}
For further nats-streaming configuration/operation, please visit [NATS docs](https://nats.io/documentation/streaming/nats-streaming-intro/).
{{% /notice %}}

#### Connection Information

Following are the default configuration while helm installation. (To change default configuration, see [here](https://github.com/fission/fission/blob/master/charts/fission-all/values.yaml#L61-L64).)

* **Authentication Token**: defaultFissionAuthToken
* **NATS Streaming ClusterID**: fissionMQTrigger

The FQDN of nats-streaming server by default is `nats-streaming:4222` or using `nats-streaming.fission:4222` if the producer is in different namespace.
So the full connection information for NATS client is

```bash
nats://defaultFissionAuthToken@nats-streaming:4222
```

If the connection information changed, please modify the environment variable of mqtrigger-nats-streaming deployment as well.

```bash
$ kubectl -n fission edit deployment mqtrigger-nats-streaming
```  

#### Local Test

Create a message queue trigger that invokes any function you created before.

```bash
$ fission mqt create --name hello --function hello1 --topic foobar
```

To test the setup locally, we need to forward local ports traffic to nats-streaming server in kubernetes cluster.

```bash
$ export NATS_POD=$(kubectl -n fission get pod -l svc=nats-streaming -o name)
$ kubectl -n fission port-forward ${NATS_POD} 4222:4222
```

In this way we can connect to nats-streaming server locally with `127.0.0.1:4222`. (**NOTICE**: for local test only)

```bash
$ cd ${GOPATH}/src/github.com/fission/fission/test/tests/mqtrigger/nats
$ go run stan-pub.go -s nats://defaultFissionAuthToken@127.0.0.1:4222 -c fissionMQTrigger -id clientPub foobar ""
```

Then, you should see the function invocation logs.
```bash
$ fission fn logs --name hello1
[2018-12-17 07:57:44.383563857 +0000 UTC] 2018/12/17 07:57:44 fetcher received fetch request and started downloading: {1 {hello-js-60kj  default    0 0001-01-01 00:00:00 +0000 UTC <nil> <nil> map[] map[] [] nil [] }   user [] [] false}
[2018-12-17 07:57:44.563666772 +0000 UTC] 2018/12/17 07:57:44 Successfully placed at /userfunc/user
[2018-12-17 07:57:44.563726739 +0000 UTC] 2018/12/17 07:57:44 Checking secrets/cfgmaps
[2018-12-17 07:57:44.563734156 +0000 UTC] 2018/12/17 07:57:44 Completed fetch request
[2018-12-17 07:57:44.563739212 +0000 UTC] 2018/12/17 07:57:44 elapsed time in fetch request = 299.120419ms
[2018-12-17 07:57:44.648270717 +0000 UTC] user code loaded in 0sec 0.240217ms
[2018-12-17 07:57:44.659143091 +0000 UTC] ::ffff:172.17.0.28 - - [17/Dec/2018:07:57:44 +0000] "POST /specialize HTTP/1.1" 202 - "-" "Go-http-client/1.1"
[2018-12-17 07:57:44.675180546 +0000 UTC] ::ffff:172.17.0.10 - - [17/Dec/2018:07:57:44 +0000] "POST / HTTP/1.1" 200 14 "-" "Go-http-client/1.1"
```
