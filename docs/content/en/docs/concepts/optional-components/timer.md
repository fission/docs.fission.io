---
title: "Timer"
weight: 5
description: >
  Invoke functions periodically
---

The timer works like kubernetes CronJob but instead of creating a pod to do the task, 
it sends a request to router to invoke the function. It's suitable for the background tasks that
need to executor periodically.

The timer works like a Kubernetes CronJob, but instead of creating a 
pod to do the task, it sends a request to the router to invoke the 
function. It is suitable for background tasks that need to execute periodically.
