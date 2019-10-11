---
title: "Installing Fission"
draft: false
weight: 10
chapter : false
alwaysopen: false
---

Welcome! This guide will get you up and running with Fission on a
Kubernetes cluster.

### Cluster preliminaries

If you don't have a Kubernetes cluster, [here's a quick guide to set
one up]({{%relref "installation/kubernetessetup.en.md" %}}).

First, let's ensure you have the Kubernetes CLI and Helm installed and
ready.  If you already have helm, [skip ahead to the fission install](#install-fission).

If you cannot (or don't want to) use Helm, there is an alternative
installation method possible; see [installing without
Helm.](#install-without-helm).

#### Kubernetes CLI

Ensure you have the Kubernetes CLI.

You can get the Kubernetes CLI for OSX like this:
```sh
$ curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/darwin/amd64/kubectl && chmod +x kubectl && sudo mv kubectl /usr/local/bin
```

Or, for Linux:
```sh
$ curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl && chmod +x kubectl && sudo mv kubectl /usr/local/bin
```

Next, ensure you have access to a cluster.  Do this by using kubectl
to check your Kubernetes version:

```sh
$ kubectl version
```

We will need at least Kubernetes 1.9.

#### Set up Helm

Helm is an installer for Kubernetes.  If you already use helm, [skip to
the next section](#install-fission).

To install Helm, first you'll need the helm CLI:

On __OS X__:
```sh
$ curl -LO https://storage.googleapis.com/kubernetes-helm/helm-v2.11.0-darwin-amd64.tar.gz

$ tar xzf helm-v2.11.0-darwin-amd64.tar.gz

$ mv darwin-amd64/helm /usr/local/bin
```

On __Linux__:
```sh
$ curl -LO https://storage.googleapis.com/kubernetes-helm/helm-v2.11.0-linux-amd64.tar.gz

$ tar xzf helm-v2.11.0-linux-amd64.tar.gz

$ mv linux-amd64/helm /usr/local/bin
```

Next, install the Helm server on your Kubernetes cluster.  Before you
do that, you have to give helm's server privileges to install software
on your cluster.

For example, you can use the following steps to install helm using a
dedicated service account with full cluster admin privileges.

```sh
$ kubectl create serviceaccount --namespace kube-system tiller

$ kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller

$ helm init --service-account tiller
```

Or, if your cluster is already set up with a permissive service
account (this varies by version and how your Kubernetes was
installed), you can simply do:

```sh
$ helm init
```

### Install Fission (if you have helm)

List of all supported configurations for the charts `fission-all` and `fission-core` can be found [here](https://github.com/fission/fission/tree/master/charts#configuration)

#### Minikube

Since minikube 0.26.0 the default bootstrapper is kubeadm which enables RBAC by default. For those who work on versions before 0.26.0, please follow the steps below to enable RBAC.

```sh
# For minikube before version 0.26.0
$ minikube start --extra-config=apiserver.Authorization.Mode=RBAC
```

Then, you should see the cluster role `cluster-admin`.

``` sh
$ kubectl get clusterroles cluster-admin
NAME            AGE
cluster-admin   44d
```

#### Install fission with helm 

**NOTE**: Prometheus operator doesn't work on Kubernetes 1.16. You have to disable it when using helm to install Fission. See [issue](https://github.com/helm/charts/issues/17511).

```sh
# Kubernetes version before 1.16
$ helm install --name fission --namespace fission \
    --set serviceType=NodePort,routerServiceType=NodePort \
    https://github.com/fission/fission/releases/download/1.6.0/fission-all-1.6.0.tgz

# Kubernetes version 1.16
# Disable prometheus deployment before the prometheus operator gets fixed.
$ helm install --name fission --namespace fission \
    --set serviceType=NodePort,routerServiceType=NodePort,prometheusDeploy=false \
    https://github.com/fission/fission/releases/download/1.6.0/fission-all-1.6.0.tgz
```

The serviceType variable allows configuring the type of Kubernetes
service outside the cluster.  You can use `ClusterIP` if you don't
want to expose anything outside the cluster.

#### Cloud hosted clusters (GKE, AWS, Azure etc.)

You may need to add token to `~/.kube/config` manually or different steps for connecting kubernetes cluster based on the platform you use.

1. GKE: https://cloud.google.com/kubernetes-engine/docs/how-to/cluster-access-for-kubectl
2. AWS: https://docs.aws.amazon.com/eks/latest/userguide/create-kubeconfig.html
3. Azure: https://docs.microsoft.com/en-us/azure/aks/kubernetes-walkthrough#connect-to-the-cluster

```sh
# Kubernetes version before 1.16
$ helm install --name fission --namespace fission \
    https://github.com/fission/fission/releases/download/1.6.0/fission-all-1.6.0.tgz

# Kubernetes version 1.16
# Disable prometheus deployment before the prometheus operator gets fixed.
$ helm install --name fission --namespace fission --set prometheusDeploy=false \
    https://github.com/fission/fission/releases/download/1.6.0/fission-all-1.6.0.tgz
```

#### Minimal version

The fission-all helm chart installs a full set of services including
the NATS message queue, influxDB for logs, etc. If you want a more
minimal setup, you can install the fission-core chart instead:

```sh
# Kubernetes version before 1.16
$ helm install --name fission --namespace fission 
    https://github.com/fission/fission/releases/download/1.6.0/fission-core-1.6.0.tgz

# Kubernetes version 1.16
# Disable prometheus deployment before the prometheus operator gets fixed.
$ helm install --name fission --namespace fission --set prometheusDeploy=false \
    https://github.com/fission/fission/releases/download/1.6.0/fission-core-1.6.0.tgz
```

### Install Fission -- alternative method without helm

This method uses `kubectl apply` to install Fission.  You can edit the
YAML file before applying it to your cluster, if you want to change
anything in it.

Create namespace for fission installation.

```sh
$ kubectl create namespace fission 
```

**NOTE**: If you want to install in another namespace, please consider to using `helm`.  
**NOTE**: Prometheus operator doesn't work on Kubernetes 1.16. 
So this alternative method may not work on kubernetes 1.16 for now. 
Please use helm before the problem gets fixed. See [issue](https://github.com/helm/charts/issues/17511).

Choose _one_ of the following commands to run:

```sh
# Full Fission install, cloud hosted cluster:
$ kubectl -n fission apply -f https://github.com/fission/fission/releases/download/1.6.0/fission-all-1.6.0.yaml

# Full install on minikube:
$ kubectl -n fission apply -f https://github.com/fission/fission/releases/download/1.6.0/fission-all-1.6.0-minikube.yaml

# Minimal install on cloud hosted cluster:
$ kubectl -n fission apply -f https://github.com/fission/fission/releases/download/1.6.0/fission-core-1.6.0.yaml

# Minimal install on minikube:
$ kubectl -n fission apply -f https://github.com/fission/fission/releases/download/1.6.0/fission-core-1.6.0-minikube.yaml
```

Next, install the Fission CLI.

### Install the Fission CLI

#### OS X

Get the CLI binary for Mac:

```sh
$ curl -Lo fission https://github.com/fission/fission/releases/download/1.6.0/fission-cli-osx && chmod +x fission && sudo mv fission /usr/local/bin/
```

#### Linux

```sh
$ curl -Lo fission https://github.com/fission/fission/releases/download/1.6.0/fission-cli-linux && chmod +x fission && sudo mv fission /usr/local/bin/
```

#### Windows

For Windows, you can use the linux binary on WSL. Or you can download
this windows executable: [fission.exe](https://github.com/fission/fission/releases/download/1.6.0/fission-cli-windows.exe)

### Run an example

Finally, you're ready to use Fission!

```sh
$ fission env create --name nodejs --image fission/node-env:1.6.0

$ curl -LO https://raw.githubusercontent.com/fission/fission/master/examples/nodejs/hello.js

$ fission function create --name hello --env nodejs --code hello.js

$ fission function test --name hello
Hello, world!
```

For more language tutorials, visit [Language](/languages/).

### What's next?

If something went wrong, we'd love to help -- please [drop by the
slack channel](http://slack.fission.io) and ask for help.

Check out the
[examples](https://github.com/fission/fission/tree/master/examples)
for some example functions.
