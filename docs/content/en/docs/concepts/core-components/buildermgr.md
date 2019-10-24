---
title: "Builder Manager"
weight: 6
description: >
  Compile the source code into a runnable function
---

The builder manager watches the package & environments CRD changes and manages 
the builds of function source code. Once an environment that contains a builder 
image is created, the builder manager will then creates the Kubernetes service 
and deployment under the fission-builder namespace to start the environment 
builder. And once a package that contains a source archive is created, the 
builder manager talks to the environment builder to build the function's source 
archive into a deploy archive for function deployment.

After the build, the builder manager asks Builder to upload the deploy archive to the 
Storage Service once the build succeeded, and updates the package status attached with build logs.
