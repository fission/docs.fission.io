---
title: "Architecture"
weight: 30
no_list: true
description: >
  Fission architecture in detail
---

Fission consists of multiple components that build up the architecture.
From a user's and contributor's perspective these components can be broadly grouped into core and optional components.

The core components are the ones you should definitely know about while using fission.
The optional components, on the other hand, are good to know and can be learned as you go.

## Core Components

The core components include:

### [Controller](controller)
Accept REST API requests and create Fission resources

### [Executor](executor)
Component to spin up function pods

### [Router](router)
Bridge between triggers and functions

### [Function Pod](function-pod)
Place to load and execute the user function

### [Builder Manager](buildermgr)
Compile the source code into a runnable function

### [Builder Pod](builder-pod)
Place to load and execute the user function

### [StorageSvc](storagesvc)
Home for source and deployment archives


## Optional Components

The optional components include:

### [Logger](logger)
Record and persist function logs

### [KubeWatcher](kubewatcher)
Hawkeye to watch resource changes in Kubernetes cluster

### [Message Queue Trigger](message-queue-trigger)
Subscribe topics and invoke functions

### [Timer](timer)
Invoke functions periodically
