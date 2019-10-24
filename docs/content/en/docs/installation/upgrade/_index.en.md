---
title: "Upgrading Fission"
weight: 2
description: >
  Upgrade guide for Fission installation 
---

# With Helm 

If you installed Fission using `helm`, upgrade is as simple as `helm upgrade`:

```bash
# Find the name of the release you want to upgrade
$ helm list

# Upgrade it 
$ helm upgrade <release_name> https://github.com/fission/fission/releases/download/1.6.0/fission-all-1.6.0.tgz
```

Replace `fission-all` with `fission-core` if you're using the minimal
Fission install.

# Without Helm 

If you installed using `kubectl apply` of a YAML file, you can simply
`kubectl apply` the new file.

```bash
$ kubectl apply -f https://github.com/fission/fission/releases/download/1.6.0/fission-all-1.6.0.yaml
```

Replace `fission-all` with `fission-core` if you're using the minimal
install.

Use the `-minikube` suffix if you're on minikube, as follows:
```bash
$ kubectl apply -f https://github.com/fission/fission/releases/download/1.6.0/fission-all-1.6.0-minikube.yaml
```
