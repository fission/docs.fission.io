---
title: "Using Python with Fission"
weight: 10
---

Fission supports functions written in Python.  Both Python 2.x and
Python 3.x are supported.  In this usage guide we'll cover how to use
this environment, write functions, and work with dependencies.

## Before you start

We'll assume you have Fission and Kubernetes setup.  If not, head over
to the [install guide]().  Verify your Fission setup with:

```
fission --version
```

## Add the Python environment to your cluster

Fission language support is enabled by creating an _Environment_.  An
environment is the language-specific part of Fission.  It has a
container image in which your function will run.

```
fission environment create --name python --image fission/python-env --builder fission/python-builder
```

## Write a simple function in Python

TODO hello world

## HTTP requests and HTTP responses

### Accessing HTTP Requests

#### Headers

TODO example of getting headers

#### Query string

TODO example of accessing query string

#### Body 

TODO example of accessing body 
-- as plain text 
-- as json

### Controlling HTTP Responses 

#### Setting Response Headers

TODO

#### Setting Status Codes 

TODO

## Working with dependencies

### requirements.txt

quick intro + link to more info in pip docs

### Custom builds

TODO show how to provide a build.sh and what it needs to do

TODO you can also add any other stuff to the image, see the next section

## Modifying the environment images

TODO -- link to source code and instructions for rebuilding

## Resource usage 

TODO recommend using min memory and cpu requests. 

TODO -- run hello world with 128m, 256m and find a reasonable minimum
to recommend to people


