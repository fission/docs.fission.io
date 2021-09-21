---
title: "Contributing to Fission"
linkTitle: Contributing
weight: 50
description: >
  Build deploy and contribute to Fission!
---

Thanks for helping make Fission better😍!

There are many areas we can use contributions - ranging from code, documentation, feature proposals, issue triage, samples, and content creation.

First, please read the [code of conduct](https://github.com/fission/.github/blob/main/CODE_OF_CONDUCT.md). By participating, you're expected to uphold this code.

- [Choose something to work on](#choose-something-to-work-on)
  - [Get Help.](#get-help)
- [Contributing - building & deploying](#contributing---building--deploying)
  - [Pre-requisite](#pre-requisite)
    - [Use Skaffold with Kind/K8S Cluster to build and deploy](#use-skaffold-with-kindk8s-cluster-to-build-and-deploy)
  - [Validating Installation](#validating-installation)
  - [Examples](#examples)
  - [Understanding code structure](#understanding-code-structure)
    - [cmd](#cmd)
      - [pkg](#pkg)
    - [Custom Resource Definitions](#custom-resource-definitions)
    - [Charts](#charts)
    - [Environments](#environments)
  
# Choose something to work on

- The easiest way to start is to look at existing [issues](https://github.com/fission/fission/issues) and see if there's something there that you'd like to work on. You can filter issues with label "[Good first issue](https://github.com/fission/fission/issues?q=is%3Aopen+is%3Aissue+label%3A%22good+first+issue%22)" which are relatively self sufficient issues and great for first time contributors.

- If you are going to pick up an issue, it would be good to add a comment stating the intention.
- If the contribution is a big change/new feature, please raise an issue and discuss the needs, design in the issue in detail.

Please check following repositories for your areas of interest,

- For contributing a new Fission environment, please check the [environments repo](https://github.com/fission/environments)
- For contributing a new Keda Connector, please check the [Keda Connectors repo](https://github.com/fission/keda-connectors)
- You can contribute to the Fission Docs by adding content to the [docs repo](https://github.com/fission/docs.fission.io)

## Get Help.

Do reach out on Slack or Twitter and we are happy to help.

- Drop by the [slack channel](https://join.slack.com/t/fissionio/shared_invite/enQtOTI3NjgyMjE5NzE3LTllODJiODBmYTBiYWUwMWQxZWRhNDhiZDMyN2EyNjAzMTFiYjE2Nzc1NzE0MTU4ZTg2MzVjMDQ1NWY3MGJhZmE).
- Say Hi on [twitter](https://twitter.com/fissionio).

# Contributing - building & deploying

## Pre-requisite

- You'll need the [`go` compiler](https://golang.org/) and tools installed. Currently version 1.16.x of Go is needed.
- You'll also need [docker](https://docs.docker.com/install) for building images locally. For Mac and Windows, Docker Desktop is recommended. You may prefer any compatible options for you OS.
- You will need a Kubernetes cluster and you can use one of options from below.
  
  - [Kind](https://kind.sigs.k8s.io/)(Preferred)
  - [Minikube](https://github.com/kubernetes/minikube)
  - Cluster in cloud such as GKE (Google Kubernetes Engine cluster)/ EKS (Elastic Kubernetes Service)/ AKS (Azure Kubernetes Service)

- Kubectl and [Helm](https://helm.sh/) installed.
- [Goreleaser](https://goreleaser.com/install/) for building the Go binaries.
- [Skaffold](https://skaffold.dev/docs/install/) for local development workflow to make it easier to build and deploy Fission.
- And of course some basic concepts of Fission such as environment, function are good to be aware of!

### Use Skaffold with Kind/K8S Cluster to build and deploy

You should create a Kubernetes cluster using Kind/Minikube cluster or if using a cloud provider cluster then Kubecontext should be pointing to appropriate cluster.

- For building & deploying to Cloud Provider K8S cluster such as GKE/EKS/AKS:

```sh
$ skaffold config set default-repo vishalbiyani  // (vishalbiyani - should be your registry/Dockerhub handle)
$ skaffold run
```

- For building & deploying to Kind cluster use Kind profile
  
```sh
$ kind create cluster
$ kubectl create ns fission
$ make skaffold-prebuild # This builds all Go binaries required for Fission
$ skaffold run -p kind
```

- If you want your new changes to reflect after skaffold deploy,

```sh
$ skaffold delete
$ kubectl delete ns fission-function
$ make skaffold-prebuild # This builds all Go binaries required for Fission
$ skaffold run -p kind
```

## Validating Installation

If you are using Helm, you should see release installed:

```sh
$ helm list -n fission -oyaml
- app_version: 1.14.1
  chart: fission-all-1.14.1
  name: fission
  namespace: fission
  revision: "1"
  status: deployed
  updated: 2021-09-13 13:16:28.51769 +0530 IST
```

Also, you should see the Fission services deployed and running:

```sh
$ kubectl get pods -nfission
NAME                                                    READY   STATUS             RESTARTS   AGE
buildermgr-6f778d4ff9-dqnq5                             1/1     Running            0          6h9m
controller-d44bd4f4d-5q4z5                              1/1     Running            0          6h9m
executor-557c68c6fd-dg8ld                               1/1     Running            0          6h9m
influxdb-845548c959-2954p                               1/1     Running            0          6h9m
kubewatcher-5784c454b8-5mqsk                            1/1     Running            0          6h9m
logger-bncqn                                            2/2     Running            0          6h9m
mqtrigger-kafka-765b674ff-jk5x9                         1/1     Running            0          6h9m
mqtrigger-nats-streaming-797498966c-xgxmk               1/1     Running            3          6h9m
nats-streaming-6bf48bccb6-fmmr9                         1/1     Running            0          6h9m
router-db76576bd-xxh7r                                  1/1     Running            0          6h9m
storagesvc-799dcb5bdf-f69k9                             1/1     Running            0          6h9m
timer-7d85d9c9fb-knctw                                  1/1     Running            0          6h9m
```

## Examples

In [examples repo](https://github.com/fission/examples), we have a few Fission function samples for different languages.
You can add your own samples also, so that they can provide help to a wider community.

## Understanding code structure

### cmd

[Cmd](https://github.com/fission/fission/tree/master/cmd) package is entrypoint for all runtime components and also has Dockerfile for each component.
The actual logic here will be pretty light and most of logic of each component is in [pkg](https://github.com/fission/fission/tree/master/pkg) (Discussed later).

| Component                | Runtime Component      |Used in|
| :-------------           |:-------------          |:-|
| fetcher                  | Docker Image           |Environments|
| fission-bundle           | Docker Image           |Binary for all components|
| fission-cli              | CLI Binary             |CLI by user|
| preupgradechecks         | Docker Image           |Pre-install upgrade|
| reporter                 | Docker Image           |Used for analytics |

```text
cmd
├── builder
│   ├── Dockerfile.fission-builder
│   ├── app
│   │   └── server.go
│   └── main.go
├── fetcher
│   ├── Dockerfile.fission-fetcher
│   ├── app
│   │   └── server.go
│   └── main.go
├── fission-bundle
│   ├── Dockerfile.fission-bundle
│   ├── main.go
│   └── mqtrigger
│       └── mqtrigger.go
├── fission-cli
│   ├── app
│   │   └── app.go
│   └── main.go
├── preupgradechecks
│   ├── Dockerfile.fission-preupgradechecks
│   ├── main.go
│   └── preupgradechecks.go
└── reporter
    ├── Dockerfile.reporter
    ├── app
    │   ├── app.go
    │   └── cmd_event.go
    └── main.go
```

**fetcher** : is a very lightweight component and all of related logic is in [fetcher package](https://github.com/fission/fission/tree/master/pkg/fetcher) itself.
Fetcher helps in fetching and uploading code and in specializing environments.

**fission-bundle** : is a component which is a single binary for all components.
Based on arguments you pass to fission-bundle - it becomes that component.
For ex.

```sh
$ /fission-bundle --controllerPort "8888" # Runs Controller

$ /fission-bundle --kubewatcher --routerUrl http://router.fission  # Runs Kubewatcher
```

So, most server side components running on server side are fission-bundle binary wrapped in container and used with different arguments.
Various arguments and environment variables are passed from manifests/helm chart.

**fission-cli** : is the cli used by end user to interact Fission

**preupgradechecks** : is again a small independent component to do pre-install upgrade tasks.

#### pkg

Pkg is where most of core components and logic reside.
The structure is fairly self-explanatory for example all of executor related functionality will be in executor package and so on.

```text
pkg
├── apis
├── builder
├── buildermgr
├── cache
├── canaryconfigmgr
├── controller
├── crd
├── error
├── executor
├── featureconfig
├── fetcher
├── fission-cli
├── generated
├── generator
├── info
├── kubewatcher
├── logger
├── mqtrigger
├── plugin
├── poolcache
├── publisher
├── router
├── storagesvc
├── throttler
├── timer
├── tracker
└── utils
```

### Custom Resource Definitions

Fission defines few Custom Resources Definitions, which helps in Fission defining Kubernetes like APIs for Fission entities,
and in extending APIs as per Fission needs.

You can visualize CRDs [here](https://doc.crds.dev/github.com/fission/fission).
YAML definition can be found in [crds folder](https://github.com/fission/fission/tree/master/crds).

All definitions are defined in [pkg/apis/core/v1/types.go](https://github.com/fission/fission/blob/master/pkg/apis/core/v1/types.go).

### Charts

Fission currently has two charts - and we recommend using fission-all for development.

```text
charts
├── README.md
├── fission-all
└── fission-core
```

### Environments

Each of runtime environments is in [fission/environments](https://github.com/fission/environments) repository and fairly independent. If you are enhancing or creating a new environment - most likely you will end up making changes in that repository.

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

You can visualize latest environment version at [environments.fission.io](https://environments.fission.io/)
