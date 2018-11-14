---
title: "Kubernetes Quick Install"
draft: false
weight: 12
---

This is a quick guide to help you get started running Kubernetes on
your laptop (or on the cloud).

(This isn't meant as a production Kuberenetes guide; it's merely
intended to give you something quickly so you can try Fission on it.)

## Minikube

Minikube is the usual way to run Kubernetes on your laptop:

### Install and start Kubernetes on OSX:

```bash
$ curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/darwin/amd64/kubectl && chmod +x kubectl && sudo mv kubectl /usr/local/bin

$ curl -Lo minikube https://storage.googleapis.com/minikube/releases/v0.26.1/minikube-darwin-amd64 && chmod +x minikube && sudo mv minikube /usr/local/bin/

$ minikube start
```

### Or, install and start Kubernetes on Linux:

```bash
$ curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl && chmod +x kubectl && sudo mv kubectl /usr/local/bin

$ curl -Lo minikube https://storage.googleapis.com/minikube/releases/v0.26.1/minikube-linux-amd64 && chmod +x minikube && sudo mv minikube /usr/local/bin/

$ minikube start
```

## Google Container Engine

Alternatively, you can use [Google Kubernetes Engine's](https://cloud.google.com/container-engine/) free trial to
get a 3-node cluster.  Hop over to [Google Cloud](https://cloud.google.com/container-engine/) to set that up.

