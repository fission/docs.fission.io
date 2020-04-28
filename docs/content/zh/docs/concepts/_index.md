---
title: "Concepts"
weight: 10
description: >
  Concepts of Fission architecture and components
---

Fission has three main concepts: **Functions, Environments, and Triggers.**

{{< img "./assets/trigger-function-environment.png" "Trigger, Function, Environment" "30em" "1" >}}

## Functions

A **Fission** function is something that Fission executes. It's usually a
module with one entry point, and that entry point is a function with a
certain interface. A number of programming languages are supported
for Functions.

Here's an example of a simple function in JavaScript:

```js
module.exports = async function(context) {
    return {
        status: 200,
        body: "hello, world!\n"
    };
}
```

## Environments

Environments are the language-specific parts of Fission. An
**Environment** contains just enough software to build and run a Fission
Function.

Since Fission invokes Functions through HTTP, this means the runtime
of an environment is a container with an HTTP server, and usually a
dynamic loader that can load a function.  Some environments also
contain builder containers, which take care of compilation and
gathering dependencies.

You can modify any of Fission's existing environments and rebuild them,
or you can also build a new environment from scratch.

See [here]({{% relref "../languages/" %}}) for the full image list.

## Triggers
 
Functions are invoked on the occurrence of an event; a **Trigger** is
what configures Fission to use that event to invoke a function.  In
other words, a trigger is a binding of events to function invocations.

For example, an **HTTP Trigger** may bind GET requests on a certain path
to the invocation of a certain function.

There are several types of triggers: 

* **HTTP Triggers** invoke functions when receiving HTTP requests.
* **Timer Triggers** invoke functions based on time.
* **Message Queue Triggers** for Kafka, NATS, and Azure queues.
* **Kubernetes Watch Triggers** to invoke functions when something in your cluster changes.

When a trigger receives requests/events, it invokes the target function 
defined in trigger object by sending an HTTP request through router to a function.

## Other Concepts

These are concepts you may not need while starting out, but might be
useful to know in more advanced usage.

### Archives

An **Archive** is a zip file containing source code or compiled binaries.

Archives with runnable functions in them are called **Deployment
Archives**; those with source code in them are called **Source
Archives**.

### Packages

A **Package** is a Fission object containing a Deployment Archive and
a Source Archive (if any). A Package also references a certain environment.

When you create a Package with a Source Archive, Fission automatically
builds it using the appropriate builder environment, and adds a
Deployment Archive to the package.

### Specifications

Specifications (**specs** for short) are simply YAML config files
containing the objects we've spoken about so far --- Functions,
Environments, Triggers, Packages and Archives.  

Specifications exist only on the client side, and are a way to
instruct the Fission CLI about what objects to create or update.  They
also specify how to bundle up source code, binaries etc into Archives.

The Fission CLI features an idempotent deployment tool that works
using these specifications.
