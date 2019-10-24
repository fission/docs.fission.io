---
title: "Environment Container"
weight: 5
description: >
  Place to load and execute the user function
---

Environment containers run user-defined functions and are language-specific. 
Each environment container must contain an HTTP server and a loader for functions.

The pool manager deploys the environment container into a pod with fetcher 
(fetcher is a simple utility that can fetch an HTTP URL to a file at a 
configured location). This pod forms a "generic pod" because it can
be loaded with any function in that coding language.

When the pool manager needs to create a service for a function, it calls
fetcher to fetch the function. Fetcher downloads the function into a
volume shared between fetcher and this environment container. Poolmgr
then requests the container to load the function.
