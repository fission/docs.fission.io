---
title: "Supporting Canary Deployments for Fission Functions"
draft: false
weight: 49
---

This tutorial will walk you through setting up a canary config such that a new version of a function can be deployed in production with minimal risk in a way that it gradually receives 
user traffic all the way from 0% to 100% eventually.

## Setup & pre-requisites

This feature is dependent on Prometheus metrics to check the health of the new version of the function before incrementing 
the percentage of user traffic to the new version of the function can be incremented at every interval that is configured.

Hence, Prometheus needs to be deployed and is listed as a dependency for fission chart. Issuing a `helm dependency update` before `helm install` of fission ensures the prometheus chart is fetched and installed alongside fission.

### Canary Config parameters

A Canary Config has the following parameters :

  duration: Specifies how frequently user traffic needs to be incremented for the new version of function
  
  failurethreshold: Specifies the threshold in percentage beyond which the new version of a function is declared unhealthy
  
  funcn: Specifies the name of the latest version of the function
  
  funcn-1: Specifies the name of the current stable version of the function
  
  trigger: Specifies the name of the http trigger object 
  
  weightincrement: Specifies the percentage increase of user traffic towards the new version of the function
  
  failureType: Specifies the parameter for checking the health of the new version of a function. For now, the only supported type is `status-code` which is the http status code. So if a function returns a status code other than 200, its considered to be unhealthy.  

For example, let's say the current stable version of a function is fna-v1 and the latest version of a function is fna-v2. Let's suppose we want to increment the traffic towards the new version in steps of 30% every 1m with a failure threshold of 10%. For such a scenario, the sample canary config is given below.
What happens is that every 1m, the percentage of failed requests to fna-v2 gets calculated from prometheus metrics. If it is under the configured failure threshold of 10%, then the percentage traffic to fn-v2 gets incremented by 30% and this cycle repeats until either the failure threshold has reached at which point, the deployment is rolled back or fn-v2 is receiving 100% of the user traffic.   

```bash
apiVersion: fission.io/v1
kind: CanaryConfig
metadata:
  name: canary-1
  namespace: default
spec:
  duration: 1m
  failureType: status-code
  failurethreshold: 10
  funcn: fn-a-v2
  funcn-1: fn-a-v1
  trigger: route-fna
  weightincrement: 30
```

### Steps to setup a canary config

1. Create environment for fission function :

```bash
fission env create --name nodejs --image fission/node-env
```

2. Create fission functions :

```bash
fission fn create --name fna-v1 --code hello.js --env nodejs
fission fn create --name fna-v2 --code hello2.js --env nodejs
```

3. Create an http trigger to these functions :

```bash
fission route create --name route-fna --function fna-v1 --weight 100 --function fna-v2 --weight 0
```

4. Create a canary config :

```bash
fission canary-config create --name canary-1 --funcN fna-v2 --funcN-1 fna-v1 --httptrigger route-fna --increment-step 30 --increment-interval 1m --failure-threshold 10
```

### Steps to verify the status of a canary deployment

```bash
fission canary-config get --name canary-1
```

This prints the status of the canary deployment of the new version of the function. 
The status is "Pending" if the canary deployment is in progress.
The status is "Succeeded" if the new version of the function is receiving 100% of the user traffic.
The status is "Failed" if the failure threshold reached for the new version of the function and as a result 100% of the traffic gets routed to the old version of the function(rollback).
The status is "Aborted" if there were some failures during the canary deployment.

### Note

The `scrape_interval` for Prometheus server is 1m by default. If the "duration" parameter needs to be less than 1m, the `scrape_interval` parameter needs to configured to a much lower value.
This can be done by updating the config map for prometheus server. Just updating the config map is enough, prometheus server need not be restarted. 
 

