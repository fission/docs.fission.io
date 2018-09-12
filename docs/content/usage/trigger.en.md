---
title: "Triggers"
draft: false
weight: 43
---

### Create a HTTP Trigger

An HTTP trigger invokes a function when there is an HTTP request.

You can specify the relative URL and HTTP method for a trigger:

``` bash
$ fission httptrigger create --url /hello --method GET --function hello
trigger '94cd5163-30dd-4fb2-ab3c-794052f70841' created

$ curl http://$FISSION_ROUTER/hello
Hello World!
```

{{% notice tip %}} 
FISSION_ROUTER is the externally-visible address of your
Fission router service.  For how to set up environment variable
`FISSION_ROUTER`, see [here](../installation/env_vars)
{{% /notice %}}

If you want to use Kubernetes Ingress for the HTTP Trigger, you can
provide the `--createingress` flag and a hostname.  If the hostname is
not provided, it defaults to "*", which indicates a wildcard host.

```  bash
$ fission httptrigger create --url /hello --method GET --function hello --createingress --host acme.com
trigger '94cd5163-30dd-4fb2-ab3c-794052f70841' created

$ fission route list
NAME                                 METHOD HOST     URL      INGRESS FUNCTION_NAME
94cd5163-30dd-4fb2-ab3c-794052f70841 GET    acme.com /hello   true    hello
```

Please note that for ingress to work, you will have to deploy an ingress controller in Kubernetes cluster. Kubernetes currently supports and maintains the following ingress controllers:

- [Nginx Ingress Controller](https://github.com/kubernetes/ingress-nginx)
- [GCE Ingress Controller](https://github.com/kubernetes/ingress-gce)

Other Ingress controllers exist, such as [F5 networks](http://clouddocs.f5.com/products/connectors/k8s-bigip-ctlr/v1.5/) and [Kong](https://konghq.com/blog/kubernetes-ingress-controller-for-kong/).


### Create a Time Trigger

Time-based triggers invoke functions based on time.  They can run once
or repeatedly.  They're specified using [cron string
specifications](https://en.wikipedia.org/wiki/Cron):

``` bash
$ fission tt create --name halfhourly --function hello --cron "*/30 * * * *"
trigger 'halfhourly' created
```

You can also use a friendlier syntax such "@every 1m" or "@hourly":

``` bash
$ fission tt create --name minute --function hello --cron "@every 1m"
trigger 'minute' created
```

And you can list time triggers to see their associated function and cron strings:

``` bash
$ fission tt list
NAME       CRON         FUNCTION_NAME
halfhourly 0 30 * * * * hello
minute     @every 1m    hello
```

You can also use `showschedule` to show the upcoming schedule for a
given cron spec.  Use this to test your cron strings.  And note that
the server's time is used to invoke functions, not your laptop's time!

``` bash
$ fission tt showschedule --cron "0 30 * * * *" --round 5
Current Server Time: 	2018-06-12T05:07:41Z
Next 1 invocation: 	2018-06-12T05:30:00Z
Next 2 invocation: 	2018-06-12T06:30:00Z
Next 3 invocation: 	2018-06-12T07:30:00Z
Next 4 invocation: 	2018-06-12T08:30:00Z
Next 5 invocation: 	2018-06-12T09:30:00Z
```

### Create a Message Queue Trigger

A message queue trigger invokes a function based on messages from an
message queue.  Optionally, it can place the response of a function
onto another queue.

NATS and Azure Storage Queue are supported queues:

``` bash
$ fission mqt create --name hellomsg --function hello --mqtype nats-streaming --topic newfile --resptopic newfileresponse 
trigger 'hellomsg' created
```

You can list or update message queue triggers with `fission mqt list`,
or `fission mqt update`.
