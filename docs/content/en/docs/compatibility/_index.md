---
title: "Compatibility"
weight: 1
description: >
  Fission Compatibility with environments, Keda and Keda Connectors
---

| Fission version | Keda version | Keda Connectors image tag |
| --------------- | ------------ | ------------------------- |
| 1.11.2          | 1.5          | v0.1                      |
| 1.12.0          | 2.0          | v0.5                      |

All Keda Connector images can be used with both fission version except the Kafka connector, which has some breaking changes.

Going forward all environment images for each language would follow its own version. For now all environment image tag starts with image tag `1.11.2`.