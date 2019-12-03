---
title: "Installing Fission"
linkTitle: Installing Fission
weight: 20
description: >
  Installation guide for Fission installation 
---

Welcome! This guide will get you up and running with Fission on a
Kubernetes cluster.

# Cluster preliminaries

First, let's ensure you have the Kubernetes CLI and Helm installed and
ready.  If you already have helm, [skip ahead to the fission install](#install-fission).

If you cannot (or don't want to) use Helm, there is an alternative
installation method possible; see [installing without
Helm](#without-helm).

## Kubernetes Cluster

If you don't have a Kubernetes cluster, [here's a official guide to set one up](https://kubernetes.io/docs/setup/).

{{% notice info %}}
Fission requires Kubernetes 1.9 or higher
{{% /notice %}}

## Kubectl

Kubectl is a command line interface for running commands against Kubernetes clusters, 
visit [here](https://kubernetes.io/docs/tasks/tools/install-kubectl/) to see how to install it.

See [how to setup config correctly on different platforms]({{% relref "trouble-shooting/kubernetes.md" %}}#kubeconfig-for-connecting-to-cluster)
Next, ensure you have access to a cluster.  Do this by using kubectl to check your Kubernetes version:

```sh
$ kubectl version
```

## Helm

Helm is an installer for Kubernetes.  If you already use helm, [skip to
the next section](#install-fission).

To install helm, first you'll need the helm CLI. Visit [here](https://helm.sh/docs/using_helm/#installing-the-helm-client) 
to see how to install it.

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

# Install Fission

## What version should I use: All vs Core

* fission-all **(Recommend)**
    * Install a full set of services including the NATS message queue, influxDB for logs, etc. 
    and enable all Fission features. It's suitable for people who want to try all the cool features
    Fission has and for companies that use features that don't include in the core version.

* fission-core
    * Install core components for creating and serving a function.

Following, we will use `fission-all` to demonstrate how to install Fission.

List of all supported configurations for the charts `fission-all` and `fission-core` can be found [here](https://github.com/fission/fission/tree/master/charts#configuration).

## With Helm

### OpenShift, Minikube, Docker Desktop

{{< tabs "fission-install" >}}
{{< tab "Minikube, Docker Desktop" >}}
```sh
$ helm install --name fission --namespace fission \
    --set serviceType=NodePort,routerServiceType=NodePort \
    https://github.com/fission/fission/releases/download/{{% release-version %}}/fission-all-{{% release-version %}}.tgz
```
{{< /tab >}}
{{< tab "OpenShift" >}}

Please visit [OpenShift]({{%relref "_index.en.md" %}}) for more detailed information.

```sh
$ helm install --name fission --namespace fission \
    --set serviceType=NodePort,routerServiceType=NodePort,logger.enableSecurityContext=true,prometheus.enabled=false \
    https://github.com/fission/fission/releases/download/{{% release-version %}}/fission-all-{{% release-version %}}.tgz
```
{{< /tab >}}
{{< /tabs >}}

The serviceType variable allows configuring the type of Kubernetes
service outside the cluster.  You can use `ClusterIP` if you don't
want to expose anything outside the cluster.

### Cloud Hosted Clusters

See [how to add token to kubeconfig](#kubectl) if you're not able to connect to cluster.

{{< tabs "fission-install-cloud-provider" >}}
{{< tab "GKE, AKS, EKS" >}}
```sh
$ helm install --name fission --namespace fission \
    https://github.com/fission/fission/releases/download/{{% release-version %}}/fission-all-{{% release-version %}}.tgz
```
{{< /tab >}}
{{< tab "OpenShift" >}}

Please visit [OpenShift]({{%relref "_index.en.md" %}}) for more detailed information.

```sh
$ helm install --name fission --namespace fission \
    --set logger.enableSecurityContext=true,prometheus.enabled=false \
    https://github.com/fission/fission/releases/download/{{% release-version %}}/fission-all-{{% release-version %}}.tgz
```
{{< /tab >}}
{{< /tabs >}}

## Without helm

This method uses `kubectl apply` to install Fission.  You can edit the
YAML file before applying it to your cluster, if you want to change
anything in it. Create namespace for fission installation.

```sh
$ kubectl create namespace fission 
```
  
{{% notice info %}}
* If you want to install in another namespace, please consider to use `helm`.
{{% /notice %}}

Choose _one_ of the following commands to run:

* You can choose to use `fission-all` or `fission-core`. Here, we use `fission-all` to demonstrate the installation. 

{{< tabs "fission-install-without-helm" >}}
{{< tab "Basic" >}}
```bash
$ kubectl -n fission apply -f \
    https://github.com/fission/fission/releases/download/{{% release-version %}}/fission-all-{{% release-version %}}.yaml
```
{{< /tab >}}
{{< tab "Minikube" >}}
```bash
$ kubectl -n fission apply -f \
    https://github.com/fission/fission/releases/download/{{% release-version %}}/fission-all-{{% release-version %}}-minikube.yaml
```
{{< /tab >}}
{{< tab "OpenShift" >}}

Please visit [OpenShift]({{%relref "_index.en.md" %}}) for more detailed information.

```bash 
$ kubectl -n fission apply -f \
    https://github.com/fission/fission/releases/download/{{% release-version %}}/fission-core-{{% release-version %}}-openshift.yaml
```
{{< /tab >}}
{{< /tabs >}}

# Install Fission CLI

{{< tabs "fission-cli-install" >}}
{{< tab "MacOS" >}}
```sh
$ curl -Lo fission https://github.com/fission/fission/releases/download/{{% release-version %}}/fission-cli-osx \
    && chmod +x fission && sudo mv fission /usr/local/bin/
```
{{< /tab >}}
{{< tab "Linux" >}}
```sh
$ curl -Lo fission https://github.com/fission/fission/releases/download/{{% release-version %}}/fission-cli-linux \
    && chmod +x fission && sudo mv fission /usr/local/bin/
```
{{< /tab >}}
{{< tab "Windows" >}}
For Windows, you can use the linux binary on WSL. Or you can download
this windows executable: [fission.exe](https://github.com/fission/fission/releases/download/{{% release-version %}}/fission-cli-windows.exe)
{{< /tab >}}
{{< /tabs >}}

# Run an example

Finally, you're ready to use Fission!

```sh
$ fission env create --name nodejs --image fission/node-env:{{% release-version %}}

$ curl -LO https://raw.githubusercontent.com/fission/fission/master/examples/nodejs/hello.js

$ fission function create --name hello --env nodejs --code hello.js

$ fission function test --name hello
Hello, world!
```

For more language tutorials, visit [Language]({{% relref "../languages/" %}}).

# What's next?

If something went wrong, we'd love to help -- please [drop by the
slack channel](http://slack.fission.io) and ask for help.

Check out the
[examples](https://github.com/fission/fission/tree/master/examples)
for some example functions.
