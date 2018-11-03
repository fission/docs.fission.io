---
title: "Contributing to Fission"
chapter: false
weight: 250
alwaysopen: true
---

{{% notice info %}}
You only need to do this if you're making Fission changes; if you're
just deploying Fission, use fission.yaml which points to prebuilt
images.
{{% /notice %}}

You'll need the `go` compiler and tools installed, along with the
[glide dependency management
tool](https://github.com/Masterminds/glide#install).  You'll also need
docker for building images.

The server side is compiled as one binary ("fission-bundle") which
contains controller, poolmgr and router; it invokes the right one
based on command-line arguments.

To build fission-bundle: clone this repo to
`$GOPATH/src/github.com/fission/fission`, then from the top level
directory (if you want to build the image with the docker inside
minikube, you'll need to set the proper environment variables with
`eval $(minikube docker-env)`):

Install dependencies with glide:

{{< highlight bash >}}
$ glide install
{{< /highlight >}}

Build fission server:

{{< highlight bash >}}
$ pushd fission-bundle
$ ./build.sh
{{< /highlight >}}

You now need to build the docker image for fission. You can use
`push.sh` and push it to a docker hub account. But it's easiest to use
minikube and its built-in docker daemon:

{{< highlight bash >}}
$ eval $(minikube docker-env)
$ docker build -t minikube/fission-bundle .
{{< /highlight >}}

Next, pull in the dependencies for the Helm chart:

{{< highlight bash >}}
$ helm dep update charts/fission-all
{{< /highlight >}}

Next, install fission with this image on your kubernetes cluster using the helm chart:

{{< highlight bash >}}
$ helm install --set "image=minikube/fission-bundle,pullPolicy=IfNotPresent,analytics=false" charts/fission-all
{{< /highlight >}}

And if you're changing the CLI too, you can build it with:

{{< highlight bash >}}
$ cd fission && go install
{{< /highlight >}}

Finally, reset to the original current working directory

{{< highlight bash >}}
$ popd
{{< /highlight >}}
