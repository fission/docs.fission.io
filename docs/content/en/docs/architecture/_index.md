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

### [Controller](controller.md)
Accept REST API requests and create Fission resources

### [Executor](executor.md)
Component to spin up function pods

### [Router](router.md)
Bridge between triggers and functions

### [Function Pod](function-pod.md)
Place to load and execute the user function

### [Builder Manager](buildermgr.md)
Compile the source code into a runnable function

### [Builder Pod](builder-pod.md)
Place to load and execute the user function

### [StorageSvc](storagesvc.md)
Home for source and deployment archives


## Optional Components

The optional components include:

### [Logger](logger.md)
Record and persist function logs

### [KubeWatcher](kubewatcher.md)
Hawkeye to watch resource changes in Kubernetes cluster

### [Message Queue Trigger](message-queue-trigger.md)
Subscribe topics and invoke functions

### [Timer](timer.md)
Invoke functions periodically
