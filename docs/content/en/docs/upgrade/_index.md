---
title: "Upgrade Guide"
weight: -1
description: >
  Upgrade guidance 1.10 onwards
---

In fission 1.11.2, OpenAPI Schema Validations were introduced, which requires to recreate whenever new fields are added to CRD. Following are the steps to upgrade from 1.10.0 to 1.11.2 or 1.12.0.

1. Take backup of your CRs.
2. Uninstall fission
3. Run `kubectl get crds | awk '{print $1}' | grep "fission.io" | xargs -n1 kubectl delete crds` to delete all customresourcedefinitions.
4. Install fission version 1.11.2 or 1.12.0