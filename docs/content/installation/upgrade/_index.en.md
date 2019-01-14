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
$ helm upgrade <release_name> https://github.com/fission/fission/releases/download/1.0-rc2/fission-all-1.0-rc2.tgz
```

Replace `fission-all` with `fission-core` if you're using the minimal
Fission install.

## If you're not using Helm 

If you installed using `kubectl apply` of a YAML file, you can simply
`kubectl apply` the new file.

```bash

$ kubectl apply -f https://github.com/fission/fission/releases/download/1.0-rc2/fission-all-1.0-rc2.yaml

```

Replace `fission-all` with `fission-core` if you're using the minimal
install.

Use the `-minikube` suffix if you're on minikube, as follows:
```bash

$ kubectl apply -f https://github.com/fission/fission/releases/download/1.0-rc2/fission-all-1.0-rc2-minikube.yaml

```

### From v0.4.x to v0.5.0
* [Upgrade guide](upgrade-from-v0.4)

### From v0.3 to v0.4.x
* [Upgrade guide](upgrade-from-v0.3)

### From v0.1 to v0.2.x
* [Upgrade guide](upgrade-from-v0.1)