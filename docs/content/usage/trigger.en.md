---
title: "Triggers"
draft: false
weight: 44
---

### Create a HTTP Trigger

An HTTP trigger invokes a function when there is an HTTP request.  

You can specify the relative URL and HTTP method for a trigger:

```
$ fission ht create --url /hello --method GET --function hello
trigger '94cd5163-30dd-4fb2-ab3c-794052f70841' created
```

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
