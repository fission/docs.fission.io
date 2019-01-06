---
title: "Basic Concepts"
draft: false
weight: 20
---

The architecture behind fission revolves around three core concepts,[Trigger, Function, Environment](../images/trigger-function-environment.svg)

## Functions, Triggers, and Environments: A quick example flow.

Before defining these concepts in detail, lets walk through a simple example of how a typical application might work in Fission.

- A fission *Trigger* is activated by a user, a kubernetes event, or some other external stimulus, resulting in an HTTP request.
- A request is sent to a fission *Router* based on the incoming stimulus.
- The fission *Router* then invokes a corresponding backend *Function*.
- The *Environment* loads the above *Function* into runtime a conainer first, then executes it and returns back its response to the initial
request.

These concepts are defined in detail below.

## Function

The backbone of any Serverless execution model is the *function*, which 
statelessly executes some snippet of code whenever necessary.

In fission, we define the *Function* as 
- a snippet of code
- written and executable by single programming language

These functions will will ultimately be triggered when *requests* or other *triggers* (defined later) come to the fission router.

For example, a function implementation in the Node.js programming language might look like this:
```js
module.exports = async function(context) {
    return {
        status: 200,
        body: "Hello, world!\n"
    };
}
```

Fission supports multiple popular languages (binary, dotnet, dotnet20, go, JVM, node, perl, php, python, ruby) right out of the box.  For corresponding examples you can take a look at [fission language examples](https://github.com/fission/fission/tree/master/examples).

In addition to these languages, you can create, and contribute *your own environments for other langauges* (see below) - anything programming langauge which you can containerize can be run as function in fission.

## Environment

Code snippets encode business logic: but they don't have implementation details required to run production software.  Any non-trivial application may require libraries (i.e. for logging, OS specific functionality, system calls), and/or a langauge runtime (i.e. like the JVM).  Even static binaries, for example, require a certain type of linux kernel with to execute.

That is: any code snippet ultimately requires an *environment* to run in.

An Environment in fission is a *container* which runs *user function* which ultimately services HTTP requests, and this is typically triggered by traffic which goes into a fission router.

## Trigger

A fission object maps incoming requests to the backend functions. When a trigger receives requests/events, it will invoke the target function defined in trigger object by sending a HTTP request through router to function pod. 

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
