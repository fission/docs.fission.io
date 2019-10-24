---
title: "Controller"
weight: 2
description: >
  Accept REST API requests and create Fission resources
---

The controller contains CRUD APIs for functions, triggers, environments, Kubernetes event watches, etc. 
This is the component that the client talks to.

All fission resources are stored in kubernetes CRDs. It needs to be able to talk to kubernetes API service.
