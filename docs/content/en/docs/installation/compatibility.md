---
title: "Compatibility"
weight: 70
description: >
  Fission Compatibility with environments, Keda and Keda Connectors
---

| Fission version | Keda version | Keda Connectors image tag      |
| --------------- | ------------ | ------------------------------ |
| 1.11.2          | 1.5          | v0.1                           |
| 1.12.0          | 2.0          | v0.5                           |
| 1.13.1          | 2.0          | v0.6 (except GCP pub-sub v0.1) |
| 1.14.0          | 2.0          | v0.7 (except GCP pub-sub v0.2) |
| v1.15.0-rc1     | 2.0+         | Verify helm chart values       |

Checking Keda connectors image tag via Fission Helm chart,

```sh
$ helm show values --version {{% release-version %}} fission-charts/fission-all

# OR

$ helm show values --version {{% release-version %}} fission-charts/fission-core
```

From output you can verify keda connectors image tag.

## Keda Connectors

All Keda Connector images can be used with both fission version except the Kafka connector, which has some breaking changes.

Going forward all environment images for each language would follow its own version.
You can follow latest environment versions at [environments.fission.io](https://environments.fission.io/)
