---
title: "Triggers"
draft: false
weight: 44
---

### Create a HTTP Trigger

An HTTP trigger invokes a function when there is an HTTP request.  

You can specify the relative URL and HTTP method for a trigger:

```
$ fission httptrigger create --url /hello --method GET --function hello
trigger '94cd5163-30dd-4fb2-ab3c-794052f70841' created
```

If you want to create a ingress for the HTTP trigger, you can provide the flag along with the hostname. Hostname is the host field as per HTTP1.1 specifications. If the hostname is not provided, it defaults to "*" which indicates wildcard host.

```
$ fission ht create --url /hello --method GET --function hello --createingress --host acme.com
trigger '94cd5163-30dd-4fb2-ab3c-794052f70841' created

$ fission route list
NAME                                 METHOD HOST     URL      INGRESS FUNCTION_NAME
94cd5163-30dd-4fb2-ab3c-794052f70841 GET    acme.com /hello   true    hello

```

Please note that for ingress to work, you will have to deploy an ingress controller in Kubernetes cluster. Kubernetes currently supports and maintains the following ingress controllers:

- [Nginx Ingress Controller](https://github.com/kubernetes/ingress-nginx)
- [GCE Ingress Controller](https://github.com/kubernetes/ingress-gce)

[F5 networks](http://clouddocs.f5.com/products/connectors/k8s-bigip-ctlr/v1.5/) and [Kong](https://konghq.com/blog/kubernetes-ingress-controller-for-kong/) also offer ingress controllers which are supported and maintained by them.

### Create a Time Trigger

Time-based triggers invoke functions based on time.  They can run once
or repeatedly.  They're specified using [cron string
specifications](https://en.wikipedia.org/wiki/Cron):

```
$ fission tt create --name halfhourly --function hello --cron "*/30 * * * *"
trigger 'halfhourly' created
```

You can also use a friendlier syntax such "@every 1m" or "@hourly":

```
$ fission tt create --name minute --function hello --cron "@every 1m"
trigger 'minute' created
```

And you can list time triggers to see their associated function and cron strings:

```
$ fission tt list
NAME       CRON       FUNCTION_NAME
halfhourly 0 30 * * * hello
minute     @every 1m  hello
```

### Create a Message Queue Trigger

A message queue trigger invokes a function based on messages from an
message queue.  Optionally, it can place the response of a function
onto another queue.

NATS and Azure Storage Queue are supported queues:

```
$ fission mqt create --name hellomsg --function hello --mqtype nats-streaming --topic newfile --resptopic newfileresponse 
trigger 'hellomsg' created
```

You can list or update message queue triggers with `fission mqt list`,
or `fission mqt update`.
