---
title: "Contributing to Fission"
weight: 250
description: >
  Build deploy and contribute to Fission!
---

# Prequisite


- You'll need the `go` compiler and tools installed. Currently version 1.12.x of Go is needed.

- You'll also need [docker](https://docs.docker.com/install) for building images.

- You will need a Kubernetes cluster and you can use one of options from below.
	- [Minikube](https://github.com/kubernetes/minikube)
	- [Kind](https://kind.sigs.k8s.io/)
	- Cluster in cloud such as GKE (Google Kubernetes Engine cluster)/ EKS (Elastic Kubernetes Service)/ AKS (Azure Kubernetes Service)

- Kubectl and Helm installed.


- [Skaffold](https://skaffold.dev/docs/install/) for local development workflow to make it easier to build and deploy Fission.

- And of course some basic concepts of Fission such as environment, function are good to be aware of!


# Getting started

## Understanding code structure


### cmd

Cmd package is entrypoint for all runtime components and also has Dockerfile for each component. The actual logic here will be pretty light and most of logic of each component is in `pkg` (Discussecd later)


| Component         	   | Runtime Component      |Used in|
| :-------------    	   |:-------------          |:-|
| fetcher         		   | Docker Image           |Environments|
| fission-bundle           | Docker Image           |Binary for all components|
| fission-cli              | CLI Binary             |CLI by user|
| preupgradechecks         | Docker Image           |Pre-install upgrade|

```
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

**fetcher** : is a very lightweight component and all of related logic is in fetcher package itself. Fetcher helps in fetching and uploading code and in specializing environments.

**fission-bundle** : is a component which is a single binary for all components. Based on arguments you pass to fission-bundle - it becomes that component. For ex. 

```
/fission-bundle --controllerPort "8888"							 # Runs Controller

/fission-bundle --kubewatcher --routerUrl http://router.fission  # Runs Kubewatcher
```

So most serverside components running on server side are fission-bundle binary wrapped in container and used with different arguments. Various arguments and environment variables are passed from manifests/helm chart

**fission-cli** : is the cli used by end user to interact Fission

**preupgradechecks** : is again a small independent component to do pre-install upgrade tasks.


### pkg

Pkg is where most of core components and logic reside. The structure is fairly self-explanatory for example all of executor related functionality will be in executor package and so on.

```
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

### Environments

Each of runtime environments is in environments directory and fairly independent. If you are enhancing or creating a new environment - most likely you will end up making changes here. Also understand that if you change an environment - you only need to build environment image.

```
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

### Charts

Fission currently has two charts - and we reccommend using fission-all for development.

```
.
├── charts
│   ├── README.md
│   ├── fission-all
│   └── fission-core
```

### Misc

There are some more directories but the once worth mentioning in this context are:

Examples: Contains various examples functions 
Test: This is where the tests & test suite lives.


## Getting Started

Get the code locally and after you have made changes - you can verify formatting and other basic checks.

```sh
# Clone the repo
$ git clone https://github.com/fission/fission.git $GOPATH/src/github.com/fission/fission
$ cd $GOPATH/src/github.com/fission/fission

# Enable go module and get dependencies
$ export GO111MODULE=on
$ go mod vendor

# Run checks on your changes
$ ./hack/verify-gofmt.sh
$ ./hack/verify-govet.sh
```

From this step onward you should stick to either "Use Skaffold and Kind/K8S Cluster" or an automated version of "Manual Steps". Both the ways achieve the same result but Skaffold makes the development cycle faster and smoother.

### Use Skaffold and Kind/K8S Cluster

You should bring up Kind/Minikube cluster or if using a cloud provider cluster then Kubecontext should be pointing to appropriate cluster.

Now replace the "<DOCKERHUB_REPO>" with your dockerhub repo in the Skaffold.yaml definition. (This will change once there is a resolution on issue here: https://github.com/GoogleContainerTools/skaffold/issues/4090)

Now you can run `$ skaffold run` - which will build images and deploy using Helm.


### Manual Steps

#### Build the code

You will need to build images for fission-bundle, fetcher, preupgradechecks based on changes you are making. You can push it to a docker hub account. But it's easier to use minikube and its built-in docker daemon:

> If you want to build the image with the docker inside minikube, you'll need to set the proper environment variables with `eval $(minikube docker-env)`


```sh
$ docker build -t minikube/fission-bundle:<tag> -f cmd/fission-bundle/Dockerfile.fission-bundle .
```

Replace the `<tag>` with any tag you want (e.g., minikube/fission-bundle:latest).  

#### Install with Helm

Next, pull in the dependencies for the Helm chart:

```sh
$ helm dep update $GOPATH/src/github.com/fission/fission/charts/fission-all
```

Next, install fission with this image on your kubernetes cluster using the helm chart:

```sh
$ helm upgrade --install fission ./charts/fission-all --namespace fission --set namespace=fission --set repository=index.docker.io --set fetcher.image=minikube/fetcher --set fetcher.imageTag=<TAG> --set image=minikube/fission-bundle --set imageTag=<TAG> --set preUpgradeChecksImage=minikube/preupgradechecks -f ./charts/fission-all/values.yaml
```
Replace `<tag>` with the tag used to build the `minikube/fission-bundle` image.  

#### Install CLI

And if you're changing the CLI too, you can build it with:

```sh
$ cd $GOPATH/src/github.com/fission/fission/cmd/fission-cli
$ go build -o $GOPATH/bin/fission
```

## Validating Installation

If you are using Helm, you should see release installed:

```
helm list
NAME   	NAMESPACE	REVISION	UPDATED                             	STATUS	CHART            	APP VERSION
fission	fission  	1       	2020-05-19 16:31:46.947562 +0530 IST	success	fission-all-1.9.0	1.9.0
```

Also you should see the Fission services deployed and running:

```
$ kubectl get pods -nfission
NAME                                                    READY   STATUS             RESTARTS   AGE
buildermgr-6f778d4ff9-dqnq5                             1/1     Running            0          6h9m
controller-d44bd4f4d-5q4z5                              1/1     Running            0          6h9m
executor-557c68c6fd-dg8ld                               1/1     Running            0          6h9m
fission-prometheus-alertmanager-5844d99569-xq6cb        2/2     Running            0          6h9m
fission-prometheus-kube-state-metrics-54f5c98c6-r7qv2   1/1     Running            0          6h9m
fission-prometheus-node-exporter-fsq4g                  1/1     Running            0          6h9m
fission-prometheus-pushgateway-66dcbbc99b-zj67m         1/1     Running            0          6h9m
fission-prometheus-server-5f947998b9-djkjv              2/2     Running            0          6h9m
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
