---
title: "Fission"
linkTitle: Documentation
weight: 20
menu:
  main:
    weight: 20
description: >
  Serverless Functions for Kubernetes
---

## What is Fission?

[fission.io](http://fission.io)  [@fissionio](http://twitter.com/fissionio)

Fission is a fast, open source serverless framework for Kubernetes with a focus on developer productivity and high performance.

Fission operates on _just the code_: Docker and Kubernetes are abstracted away under normal operation, though you can use both to extend Fission if you want to.

Fission is extensible to any language; the core is written in Go, and language-specific parts are isolated in something called _environments_ (more below).
Fission currently supports NodeJS, Python, Ruby, Go, PHP, Bash, and any Linux executable, with more languages coming soon.

## Performance: 100msec cold start

Fission maintains a pool of "warm" containers that each contain a small dynamic loader.
When a function is first called, i.e. "cold-started", a running container is chosen and the function is loaded.
This pool is what makes Fission fast: cold-start latencies are typically about 100msec.

## Kubernetes is the right place for Serverless

We're built on Kubernetes because we think any non-trivial app will use a combination of serverless functions and more conventional microservices, and Kubernetes is a great framework to bring these together seamlessly.

Building on Kubernetes also means that anything you do for operations on your Kubernetes cluster &mdash; such as monitoring or log aggregation &mdash; also helps with ops on your Fission deployment.

## Fission Concepts

Visit [concepts]({{% ref "./concepts/" %}}) for more details.

## Usage

```bash
# Add the stock NodeJS env to your Fission deployment
$ fission env create --name nodejs --image fission/node-env

# A javascript one-liner that prints "hello world"
$ curl https://raw.githubusercontent.com/fission/fission/master/examples/nodejs/hello.js > hello.js

# Upload your function code to fission
$ fission function create --name hello --env nodejs --code hello.js

# Map GET /hello to your new function
$ fission route create --method GET --url /hello --function hello

# Run the function.  This takes about 100msec the first time.
$ fission function test --name hello
Hello, world!
```

## Join Us

* [Join Slack](https://join.slack.com/t/fissionio/shared_invite/enQtOTI3NjgyMjE5NzE3LTllODJiODBmYTBiYWUwMWQxZWRhNDhiZDMyN2EyNjAzMTFiYjE2Nzc1NzE0MTU4ZTg2MzVjMDQ1NWY3MGJhZmE)
* Twitter: http://twitter.com/fissionio
