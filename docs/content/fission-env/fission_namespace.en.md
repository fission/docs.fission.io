---
title: "FISSION_NAMESPACE"
draft: false
weight: 47
---

`FISSION_NAMESPACE` is the namespace where the fission installed.

Normally, you don't have to set this unless there are multiple fission controllers installed in different namespaces within the same kubernetes cluster.

``` bash
$ export FISSION_NAMESPACE <namespace>
```