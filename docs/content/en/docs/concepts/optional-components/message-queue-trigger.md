---
title: "Message Queue Trigger"
weight: 4
description: >
  Subscribe topics and invoke functions
---

A message queue trigger binds a message queue topic to a function:
Events from that topic cause the function to be invoked with the
message as the body of the request. The trigger may also contain a
response topic: if specified, the function's output is sent to this
response.
