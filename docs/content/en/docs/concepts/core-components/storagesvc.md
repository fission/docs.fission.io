---
title: "StorageSvc"
weight: 7
description: >
  Home for source and deployment archives
---

The storage service is the home for all archives of packages with sizes larger than 256KB.
The Builder pulls the source archive from the storage service and uploads deploy archive to it.
The fetcher inside the function pod also pulls the deploy archive for function specialization.
