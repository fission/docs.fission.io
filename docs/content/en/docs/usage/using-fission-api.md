---
title: "Using Fission API"
date: 2020-04-18T14:56:20+05:30
draft: false
---

# Introduction

The Fission API can be accessed from Kubernetes API as well as from the Fission controller directly.

# With Kubernetes API 

Fission is built using Kubernetes CRDs and the Fission API follows the standard Kubernetes API model. If you are not aware of Kubernetes API or never used it before, it would be a good idea to have a [Kubernetes API documentation](https://kubernetes.io/docs/concepts/overview/kubernetes-api). Kubernetes also supports the OpenAPI standard and provides Swagger definitions as you can notice in the [Kubernetes API documentation page](https://kubernetes.io/docs/concepts/overview/kubernetes-api/#openapi-and-swagger-definitions). For more details on authentication and authorization with the API you can check the documentation on [Controlling Access to Kubernetes API](https://kubernetes.io/docs/reference/access-authn-authz/controlling-access/)

You can download the entire the Kubernetes API documentation from a cluster which has Fission installed - so you also get Fission API calls built in the definition.

- To download the entire Kubernetes API Swagger definition, assuming you are proxying the API server on localhost use the URL: [http://localhost:8001/openapi/v2](http://localhost:8001/openapi/v2). The Kubernetes API document is huge and generally consumes a lot of resources when you are trying to load it in browser. You can use https://editor.swagger.io/ to load the doc in browser or sign up at http://app.swaggerhub.com/ and then create APIs by importing the document.

- We have also hosted a Swagger DOC created in April 2020 here for a Kubernetes cluster with Fission installed: https://app.swaggerhub.com/apis/Infracloud/kubernetes/v1.15.9#/fissionIo_v1


![Kubernetes API](/images/fission-k8s.png)


# With Fission Controller

To download only the Fission Swagger API doc, assuming you are proxying the API server on localhost use the URL: [http://localhost:8001/api/v1/namespaces/fission/services/controller:80/proxy/v2/apidocs.json](http://localhost:8001/api/v1/namespaces/fission/services/controller:80/proxy/v2/apidocs.json)

For accessing this API, you will have to proxy the controller pod locally and then access the API. For programmatic access this means you should be able to access controller pod from outside the cluster.

```
$ kubectl port-forward controller-548c5d8988-fgqxt 8888:8888
Forwarding from 127.0.0.1:8888 -> 8888
Forwarding from [::1]:8888 -> 8888
Handling connection for 8888

```

![Fission Controller API](/images/fission-controller-api.png)

# Reccomended Approach


