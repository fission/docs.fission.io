---
title: "Upgrade Guide"
weight: -1
description: >
  Upgrade guidance 1.10 onwards
---

Note: Fission upgrades cause a downtime as of now. Please upvote the [issue](https://github.com/fission/fission/issues/1856) so we can priortize fixing it


# Upgrade to latest Fission version:

1. Update the CRDs by running : 
```sh
kubectl replace -k "github.com/fission/fission/crds/v1?ref={{% release-version %}}"
```

2. Please make sure you have the latest CLI installed : 

```sh
$ curl -Lo fission https://github.com/fission/fission/releases/download/{{% release-version %}}/fission-cli-linux \
    && chmod +x fission && sudo mv fission /usr/local/bin/
```

3. Update the helm repo and upgrade by mentioning the namespace Fission is installed in :
```sh
export FISSION_NAMESPACE="fission"
helm upgrade --namespace $FISSION_NAMESPACE fission fission-charts/fission-all
```
