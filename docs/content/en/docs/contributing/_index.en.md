---
title: "Contributing to Fission"
weight: 250
description: >
  Build deploy and contribute to Fission!
---

Thanks for helping make Fission better😍!

There are many areas we can use contributions - ranging from code, documentation, feature proposals, issue triage, samples, and content creation. 

First, please read the [code of conduct](CODE_OF_CONDUCT.md). By participating, you're expected to uphold this code.

Table of Contents
=================

   * [Choose something to work on](#choose-something-to-work-on)
         * [Get Help.](#get-help)
   * [Contributing - building &amp; deploying](#contributing---building--deploying)
      * [Prequisite](#prequisite)
      * [Getting Started](#getting-started)
         * [Use Skaffold with Kind/K8S Cluster to build and deploy](#use-skaffold-with-kindk8s-cluster-to-build-and-deploy)
      * [Validating Installation](#validating-installation)
      * [Understanding code structure](#understanding-code-structure)
         * [cmd](#cmd)
         * [pkg](#pkg)
         * [Charts](#charts)
         * [Environments](#environments)

# Choose something to work on

* The easiest way to start is to look at existing [issues](https://github.com/fission/fission/issues) and see if there's something there that you'd like to work on. You can filter issues with label "[Good first issue](https://github.com/fission/fission/issues?q=is%3Aopen+is%3Aissue+label%3A%22good+first+issue%22)" which are relatively self sufficient issues and great for first time contributors.
    - If you are going to pick up an issue, it would be good to add a comment stating the intention.
    - If the contribution is a big change/new feature, please raise an issue and discuss the needs, design in the issue in detail.

* For contributing a new Fission environment, please check the [environments repo](https://github.com/fission/environments)

* For contributing a new Keda Connector, please check the [Keda Connectors repo](https://github.com/fission/keda-connectors)


### Get Help.

Do reach out on Slack or Twitter and we are happy to help.

 * Drop by the [slack channel](https://join.slack.com/t/fissionio/shared_invite/enQtOTI3NjgyMjE5NzE3LTllODJiODBmYTBiYWUwMWQxZWRhNDhiZDMyN2EyNjAzMTFiYjE2Nzc1NzE0MTU4ZTg2MzVjMDQ1NWY3MGJhZmE).
 * Say hi on [twitter](https://twitter.com/fissionio).


# Contributing - building & deploying

## Pre-requisite

- You'll need the `go` compiler and tools installed. Currently version 1.12.x of Go is needed.

- You'll also need [docker](https://docs.docker.com/install) for building images locally.

- You will need a Kubernetes cluster and you can use one of options from below.
  - [Minikube](https://github.com/kubernetes/minikube)
  - [Kind](https://kind.sigs.k8s.io/)
  - Cluster in cloud such as GKE (Google Kubernetes Engine cluster)/ EKS (Elastic Kubernetes Service)/ AKS (Azure Kubernetes Service)

- Kubectl and Helm installed.

- [Skaffold](https://skaffold.dev/docs/install/) for local development workflow to make it easier to build and deploy Fission.

- And of course some basic concepts of Fission such as environment, function are good to be aware of!

#### cmd

Cmd package is entrypoint for all runtime components and also has Dockerfile for each component.
The actual logic here will be pretty light and most of logic of each component is in `pkg` (Discussed later)

| Component        | Runtime Component | Used in                   |
|:-----------------|:------------------|:--------------------------|
| fetcher          | Docker Image      | Environments              |
| fission-bundle   | Docker Image      | Binary for all components |
| fission-cli      | CLI Binary        | CLI by user               |
| preupgradechecks | Docker Image      | Pre-install upgrade       |


```text
.
cmd
├── fetcher
│   ├── Dockerfile.fission-fetcher
│   ├── app
│   └── main.go
├── fission-bundle
│   ├── Dockerfile.fission-bundle
│   ├── main.go
│   └── mqtrigger
├── fission-cli
│   ├── app
│   ├── fission-cli
│   └── main.go
└── preupgradechecks
    ├── Dockerfile.fission-preupgradechecks
    ├── main.go
    └── preupgradechecks.go
```

**fetcher** : is a very lightweight component and all of related logic is in fetcher package itself.
Fetcher helps in fetching and uploading code and in specializing environments.

**fission-bundle** : is a component which is a single binary for all components.
Based on arguments you pass to fission-bundle - it becomes that component.
For ex.


```test
/fission-bundle --controllerPort "8888" # Runs Controller

/fission-bundle --kubewatcher --routerUrl http://router.fission  # Runs Kubewatcher
```

So most server side components running on server side are fission-bundle binary wrapped in container and used with different arguments.
Various arguments and environment variables are passed from manifests/helm chart.

**fission-cli** : is the cli used by end user to interact Fission

**preupgradechecks** : is again a small independent component to do pre-install upgrade tasks.

#### pkg

Pkg is where most of core components and logic reside.
The structure is fairly self-explanatory for example all of executor related functionality will be in executor package and so on.

```text
.
├── pkg
│   ├── apis
│   ├── builder
│   ├── buildermgr
│   ├── cache
│   ├── canaryconfigmgr
│   ├── controller
│   ├── crd
│   ├── error
│   ├── executor
│   ├── fetcher
│   ├── fission-cli
│   ├── generator
│   ├── info
│   ├── kubewatcher
│   ├── logger
│   ├── mqtrigger
│   ├── plugin
│   ├── publisher
│   ├── router
│   ├── storagesvc
│   ├── throttler
│   ├── timer
│   └── utils
```

### Charts

Fission currently has two charts - and we recommend using fission-all for development.

```
.
├── charts
│   ├── README.md
│   ├── fission-all
│   └── fission-core
```

### Environments

Each of runtime environments is in fission/environments repository and fairly independent. If you are enhancing or creating a new environment - most likely you will end up making changes in that repository.

```text
.
├── environments
│   ├── binary
│   ├── dotnet
│   ├── dotnet20
│   ├── go
│   ├── jvm
│   ├── nodejs
│   ├── perl
│   ├── php7
│   ├── python
│   ├── ruby
│   └── tensorflow-serving
```