---
title: "Logger"
weight: 2
description: >
  Record and persist function logs
---

Logger is deployed as DaemonSet to help to forward function logs to a centralized 
database service for log persistence. Currently, only InfluxDB is supported to store logs.

Following is a diagram describe how log service works:
1. Logger watches pod changes and creates a symlink to the container log if the pod runs on the same node.
2. Fluentd reads logs from symlink and pipes them to InfluxDB
3. `fission function logs ...` retrieve event logs from InfluxDB with optional log filter
4. Logger removes the symlink if the pod no longer exists.
