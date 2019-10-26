---
title: "Builder Pod"
weight: 7
description: >
  Place to load and execute the user function
---

# Brief Intro

Builder Pod is to build source archive into a deployment archive that is able to use in the function pod. 
It contains two containers: Fetcher and Builder Container. 

# Diagram

{{< img "../assets/builder-pod.png" "Fig.1 Builder Pod" "50em" "1" >}}

1. Builder Manager asks Fetcher to pull the source archive.
2. Fetcher pulls the source archive from the StorageSvc.
3. Save the archive to the shared volume.
4. Builder Manager sends a build request to the Builder Container to start the build process.
5. Builder Container reads source archive from the volume, compiles it into deployment archive. </br>
Finally, save the result back to the share volume.  
6. Builder Manager asks Fetcher to upload the deployment archive.

# Builder Container
Builder Container compiles function source code into executable binary/files and is language-specific.

# Fetcher

Fetcher is responsible to pull source archive from the StorageSvc and verify the checksum
of file to ensure the integrity of file. After the build process, it uploads the deployment archive to StorageSvc.
