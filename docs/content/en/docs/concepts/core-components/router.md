---
title: "Router"
weight: 4
description: >
  Bridge between triggers and functions
---

The router forwards HTTP requests to function pods. If there's no
running service for a function, it requests one from executor, while
holding on to the request; the router will forward the request to 
the pod once the function service is ready.

The router is the only stateless component and can be scaled up if needed, according to
load.
