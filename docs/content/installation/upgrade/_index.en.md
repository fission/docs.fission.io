---
title: "Upgrading Fission"
weight: 30
---

## If you're using Helm 

If you installed Fission using `helm`, upgrade is as simple as `helm
upgrade`:

```bash
# Find the name of the release you want to upgrade
$ helm list

# Upgrade it 
$ helm upgrade <release_name> https://github.com/fission/fission/releases/download/0.12.0/fission-all-0.12.0.tgz
```

Replace `fission-all` with `fission-core` if you're using the minimal
Fission install.

## If you're not using Helm 

If you installed using `kubectl apply` of a YAML file, you can simply
`kubectl apply` the new file.

```bash

$ kubectl apply -f https://github.com/fission/fission/releases/download/0.12.0/fission-all-0.12.0.yaml

```

Replace `fission-all` with `fission-core` if you're using the minimal
install.

Use the `-minikube` suffix if you're on minikube, as follows:
```bash

$ kubectl apply -f https://github.com/fission/fission/releases/download/0.12.0/fission-all-0.12.0-minikube.yaml

```




## Upgrading older versions

Please see older documentation versions to upgrade version prior to
0.4.x:

https://docs.fission.io/0.12.0/installation/upgrade/

