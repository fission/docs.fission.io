---
title: "Upgrade Guide"
weight: -1
description: >
  Upgrade guidance 1.11 onwards
---

Note: Fission upgrades cause a downtime as of now. Please upvote the [issue](https://github.com/fission/fission/issues/1856) so we can priortize fixing it


# Upgrade to latest Fission version:

1. Update the CRDs by running : 
```sh
kubectl replace -k "github.com/fission/fission/crds/v1?ref={{% release-version %}}"
```

2. Please make sure you have the latest CLI installed :

{{< tabs "fission-cli-install" >}}
{{< tab "MacOS" >}}
```sh
$ curl -Lo fission https://github.com/fission/fission/releases/download/{{% release-version %}}/fission-{{% release-version %}}-darwin-amd64 \
    && chmod +x fission && sudo mv fission /usr/local/bin/
```
{{< /tab >}}
{{< tab "Linux" >}}
```sh
$ curl -Lo fission https://github.com/fission/fission/releases/download/{{% release-version %}}/fission-{{% release-version %}}-linux-amd64 \
    && chmod +x fission && sudo mv fission /usr/local/bin/
```
{{< /tab >}}
{{< tab "Windows" >}}
For Windows, you can use the linux binary on WSL. Or you can download
this windows executable: [fission.exe](https://github.com/fission/fission/releases/download/{{% release-version %}}/fission-cli-windows.exe)
{{< /tab >}}
{{< /tabs >}}

3. Update the helm repo and upgrade by mentioning the namespace Fission is installed in :
```sh
export FISSION_NAMESPACE="fission"
helm upgrade --namespace $FISSION_NAMESPACE fission fission-charts/fission-all
```
