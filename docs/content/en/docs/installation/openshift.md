---
title: "OpenShift"
weight: 5
description: >
  OpenShift specific setup 
---

# Installing Fission

See [Fission installation]({{%relref "_index.en.md" %}}) to learn more how to install Fission.

# Run Logger as privileged container

The reason to run Logger pods as privileged container is because Fission mounts `hostPath` volume to FluentBit to
read container log files and data persistence. 

The persistence is for FluentBit [tail plugin](https://github.com/fluent/fluent-bit-docs/blob/master/input/tail.md) 
to read/write it’s own sqlite database. Fission itself doesn’t persist anything.

```
Optionally a database file can be used so the plugin can have a history of tracked 
files and a state of offsets, this is very useful to resume a state if the service is restarted. 
```

Once the logger restarted, it ensures no duplicate logs will be sent to log database.

You may need to add `privileged` permission to service account `fission-svc`. 

```bash
oc adm policy add-scc-to-user privileged -z fission-svc
```

* Reference: https://github.com/fluent/fluentd-kubernetes-daemonset#running-on-openshift
