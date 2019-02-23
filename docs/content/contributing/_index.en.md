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
tool](https://github.com/Masterminds/glide#install). You'll also need
[docker](https://docs.docker.com/install) for building images.

The server side is compiled as one binary ("fission-bundle") which
contains controller, poolmgr and router; it invokes the right one
based on command-line arguments.

To clone the repo, install dependencies and build `fission-bundle`:

{{% notice tip %}}
If you want to build the image with the docker inside
minikube, you'll need to set the proper environment variables with
`eval $(minikube docker-env)`
{{% /notice %}}

```sh
  # Clone the repo
  $ git clone https://github.com/fission/fission.git $GOPATH/src/github.com/fission/fission
  $ cd $GOPATH/src/github.com/fission/fission

  # Get dependencies
  $ glide install --strip-vendor

  # Run checks on your changes
  $ ./hack/verify-gofmt.sh
  $ ./hack/verify-govet.sh
```

Build fission server:

```sh
$ pushd $GOPATH/src/github.com/fission/fission/fission-bundle
$ ./build.sh
```

You now need to build the docker image for fission. You can push it to
a docker hub account. But it's easier to use minikube and its
built-in docker daemon:

```sh
$ eval $(minikube docker-env)
$ docker build -t minikube/fission-bundle .
```

Next, pull in the dependencies for the Helm chart:

```sh
$ helm dep update $GOPATH/src/github.com/fission/fission/charts/fission-all
```

Next, install fission with this image on your kubernetes cluster using the helm chart:

```sh
$ helm install --set "image=minikube/fission-bundle,pullPolicy=IfNotPresent,analytics=false" charts/fission-all
```

And if you're changing the CLI too, you can build it with:

```sh
$ cd $GOPATH/src/github.com/fission/fission/fission
$ go install
```

Finally, reset to the original current working directory:

```sh
$ popd
```
