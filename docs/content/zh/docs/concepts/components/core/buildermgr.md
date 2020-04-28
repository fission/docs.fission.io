---
title: "Builder Manager"
weight: 6
description: >
  Compile the source code into a runnable function
---

# Brief Intro

The builder manager watches the package & environments CRD changes and manages 
the builds of function source code. Once an environment that contains a builder 
image is created, the builder manager will then creates the Kubernetes service 
and deployment under the fission-builder namespace to start the environment 
builder. And once a package that contains a source archive is created, the 
builder manager talks to the environment builder to build the function's source 
archive into a deploy archive for function deployment.

After the build, the builder manager asks Builder to upload the deploy archive to the 
Storage Service once the build succeeded, and updates the package status attached with build logs.

# Diagram

{{< img "../assets/buildermanager.png" "Fig.1 Builder Manager" "30em" "1" >}}

1. Builder Manager watches the environment changes.
2. Create/delete service and deploy when a new environment with build image is created/deleted.
3. Builder Manager watches the packages changes.
4. Send a build request to the builder service
5. Builder pod receives build request from the builder manager
6. Builder pulls the source archive from the StorageSvc and starts the build process. </br>
If the build process succeeded, go to step 7; otherwise, go to step 8.
7. Builder uploads the deployment archive to StorageSvc for function pod to use.
8. Builder Manager updates the package status with build logs.  
