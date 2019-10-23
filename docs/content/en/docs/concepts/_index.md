---
title: "Concepts"
weight: 30
description: >
  Concepts of Fission architecture and components
---

Fission has three main concepts: Functions, Environments, and
Triggers.

## Functions

A Fission function is something that Fission executes.  It's usually a
module with one entry point, and that entry point is a function with a
certain interface.  A number of programming languages are supported
for Functions; see below.

## Environments

Environments are the language-specific parts of Fission.  An
Environment contains just enough software to build and run a Fission
Function.

Since Fission invokes Functions through HTTP, this means the runtime
of an environment is a container with an HTTP server, and usually a
dynamic loader that can load a function.  Some environments also
contain builder containers, which take care of compilation and
gathering dependencies.

The following pre-built environments are currently available for use
in Fission:
 
| Environment                          | Image                     |
| ------------------------------------ | ------------------------- |
| NodeJS (Alpine)                      | `fission/node-env`        |
| NodeJS (Debian)                      | `fission/node-env-debian` |
| Python 3                             | `fission/python-env`      |
| Go                                   | `fission/go-env`          |
| Ruby                                 | `fission/ruby-env`        |
| Binary (for executables or scripts)  | `fission/binary-env`      |
| .NET                                 | `fission/dotnet-env`      |
| .NET 2.0                             | `fission/dotnet20-env`    |
| Perl                                 | `fission/perl-env`        |
| PHP 7                                | `fission/php-env`         |

To create custom environments you can extend one of the environments
in the list or create your own environment from scratch.

## Triggers

Functions are invoked on the occurence of an event; a _Trigger_ is
what configures Fission to use that event to invoke a function.  In
other words, a trigger is a binding of events to function invocations.

For example, an HTTP Trigger may bind GET requests on a certain path
to the invocation of a certain function.

There are several types of triggers besides HTTP Triggers: Timer
Trigger invoke functions based on time; Message queue triggers for
Kafka, NATS, and Azure queues; Kubernetes Watch triggers to invoke
functions when something in your cluster changes.

## Other Concepts

These are concepts you may not need while starting out, but might be
useful to know in more advanced usage.

### Archives

An Archive is a zip file containing source code or compiled binaries.

Archives with runnable functions in them are called _Deployment
Archives_; those with source code in them are called _Source
Archives_.

### Packages

A Package is a Fission object containing a Deployment Archive and
a Source Archive.  A Package also references a certain environment.

When you create a Package with a Source Archive, Fission automatically
builds it using the appropriate builder environment, and adds a
Deployment Archive to the package.

### Specifications

Specifications (specs for short) are simply YAML config files
containing the objects we've spoken about so far --- Functions,
Environments, Triggers, Packages and Archives.  

Specifications exist only on the client side, and are a way to
instruct the Fission CLI about what objects to create or update.  They
also specify how to bundle up source code, binaries etc into Archives.

The Fission CLI features an idempotent deployment tool that works
using these specifications.
