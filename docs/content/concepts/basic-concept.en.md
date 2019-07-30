---
title: "Basic Concepts"
draft: false
weight: 20
---

There are three basic concepts/elements of fission:

![Trigger, Function, Environment](../images/trigger-function-environment.svg)

## Function

A snippet of code write in specific programming language and will be invoked when requests come to fission router.

Following is a simple nodejs helloworld sample

```js
module.exports = async function(context) {
    return {
        status: 200,
        body: "Hello, world!\n"
    };
}
```

Currently, fission supports multiple popular language like NodeJs, Go, Python, Java...etc. For more examples in different languages, please visit [fission language examples](https://github.com/fission/fission/tree/master/examples).

## Environment

The environment(language) container which runs user function to serve HTTP requests. When a request hit fission router, the env container will load user function into runtime container first, then execute the function to serve the request. 

## Trigger

A fission object maps incoming requests to the backend functions. When a trigger receives requests/events, 
it will invoke the target function defined in trigger object by sending a HTTP request through router to function pod. 

![fission http call](../images/fission-http-call.svg)

Currently, fission supports following types of trigger:

* HTTP Trigger
    * The trigger first registers a specific url path to router and proxy all requests hit the url to user function.
* Time trigger
    * A function will be invoked based on the schedule of `cron` spec.
* Message Queue Trigger
    * The trigger will subscribe and handle any messages sent to the message queue topic. Then, publish function response/error to the predefined response/error topic.
* Kubernetes Watch Trigger
    * A watcher will be created to watch changes of kubernetes objects. If any changes occurred, invoke the target user function.
