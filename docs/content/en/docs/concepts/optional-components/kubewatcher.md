---
title: "KubeWatcher"
weight: 3
description: >
  Hawkeye to watch resource changes in Kubernetes cluster
---

Kubewatcher watches the Kubernetes API and invokes functions
associated with watches, sending the watch event to the function.

The controller keeps track of the user's requested watches and associated
functions. Kubewatcher watches the API based on these requests; when
a watch event occurs, it serializes the object and calls the function
via the router.

While a few simple retries are done, there isn't yet a reliable
message bus between Kubewatcher and the function. Work for this is
tracked in issue #64.
