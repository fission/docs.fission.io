---
title: "Using Java with Fission JVM environment"
weight: 10
---

Fission supports functions written in Java and runs then on JVM. Current JVM environment is based on openjdk8 and uses Spring boot as framework.

## Before you start

We'll assume you have Fission and Kubernetes setup.  If not, head over
to the [install guide](../installation/_index.en.md).  Verify your Fission setup with:

```
fission --version
```

## Add JVM environment to your cluster

Fission language support is enabled by creating an _Environment_.  An environment is the language-specific part of Fission.  It has a container image in which your function will run.

```
fission environment create --name python --image fission/jvm-env --builder fission/jvm-builder
```

## Write a simple function in Java

A function needs to implement the `io.fission.Function` class and override the `call` method. The call method receives the `RequestEntity` and `Context` as inputs and needs to return `ResponseEntity` object. Both `RequestEntity` and `ResponseEntity` are from `org.springframework.http` package and provide a fairly high level and rich API to interact with request and response objects.

```
ResponseEntity call(RequestEntity req, Context context);
```

The function code responds with "Hello World" in response body looks as shown below:

```
package io.fission;

import org.springframework.http.RequestEntity;
import org.springframework.http.ResponseEntity;

import io.fission.Function;
import io.fission.Context;

public class HelloWorld implements Function {

	@Override
	public ResponseEntity<?> call(RequestEntity req, Context context) {
		return ResponseEntity.ok("Hello World!");
	}

}
```

## HTTP requests and HTTP responses

Java function provides easy access to the Request and Response using Spring framework's `RequestEntity` and `ResponseEntity` objects.

### Accessing HTTP Requests

#### Headers

You can access headers object from the request object and then use various methods on header object to retrieve a specific header or get a collection of all headers.

```
    HttpHeaders headers = req.getHeaders();
    List<String> values = headers.get("keyname");
```

#### Query string

You can use the URI object in request object and parse the query parameters as shown below.

```
        Map<String, String> query_pairs = new LinkedHashMap<String, String>();
		URI url = req.getUrl();
		String query = url.getQuery();
		String[] pairs = query.split("&");
		for (String pair : pairs) {
	        int idx = pair.indexOf("=");
	        query_pairs.put(URLDecoder.decode(pair.substring(0, idx), "UTF-8"), URLDecoder.decode(pair.substring(idx + 1), "UTF-8"));
	    }
```

#### Body 

The body of the request object can be accessed as a map. You can use the map to convert to a value object using Jackson library's `ObjectMappper`.

```
final ObjectMapper mapper = new ObjectMapper();
HashMap data = (HashMap) req.getBody();
Data iotData = mapper.convertValue(data, Data.class);
```

### Controlling HTTP Responses 

#### Setting Response Headers & Status code

The response object allows adding headers before sending the response back to the user. You can also set status code, body etc. on response object

```
        HttpHeaders headers = new HttpHeaders();
		headers.add("Access-Control-Allow-Origin", "*");
		return ResponseEntity.status(HttpStatus.OK).headers(headers).build();
```

## Working with dependencies

### Maven

JVM environment can accept any executable JAR with entrypoint method that implements the interface of `io.fission.Function`. Currently the dependencies in the JVM environment are managed with Maven so we will take that as an example but you can use the others tools as well such as Gradle.

JVM environment already has the spring-boot-starter-web and fission-java-core as dependencies so you need to declare them at provided scope. You can add additional dependencies that your application needs.
```
		<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-starter-web</artifactId>
			<version>2.0.1.RELEASE</version>
			<scope>provided</scope>
		</dependency>
		<dependency>
			<groupId>io.fission</groupId>
			<artifactId>fission-java-core</artifactId>
			<version>0.0.2-SNAPSHOT</version>
			<scope>provided</scope>
		</dependency>
```

### Custom builds

The current build environment for Java has support for Maven builds. You can upload the source code and the JVM builder will build the source code into a jar. Let's take [Java example from here](https://github.com/fission/fission/tree/master/examples/jvm/java) and build using Fission builder.

Let's first create a JVM environment with builder. For JVM environment you need to pass `--keeparchive` so that the jar file built from source is not extracted for running the function. You also need to use version 2 or higher of environment.

```
fission env create --name java --image fission/jvm-env --builder fission/jvm-builder --keeparchive --version 2
```

Next create a package with the builder environment by providing the source package.  This will kick off the build process.
```
$zip java-src-pkg.zip -r *
$fission package create --env java --src java-src-pkg.zip 
Package 'java-src-pkg-zip-dqo5' created
```

You can check the status of build by running the `info` command on package. After the build succeeds, the status will turn to `succeeded` and the build logs will be visible.

```
$ fission package info --name java-src-pkg-zip-dqo5
Name:        java-src-pkg-zip-dqo5
Environment: java
Status:      running
Build Logs:

$ fission package info --name java-src-pkg-zip-dqo5
Name:        java-src-pkg-zip-dqo5
Environment: java
Status:      succeeded
Build Logs:
[INFO] Scanning for projects...
[INFO] 
[INFO] -----------------------< io.fission:hello-world >-----------------------
[INFO] Building hello-world 1.0-SNAPSHOT
[INFO] --------------------------------[ jar ]---------------------------------
[INFO] 

<< TRUNCATED FOR SIMPLICITY >>

[INFO] Building jar: /packages/java-src-pkg-zip-dqo5-aevhi1/target/hello-world-1.0-SNAPSHOT-jar-with-dependencies.jar
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time: 6.588 s
[INFO] Finished at: 2018-10-25T12:46:09Z
[INFO] ------------------------------------------------------------------------
```

Finally let's create a function with package created earlier and provide an entrypoint. The function can be tested with `fission fn test` command.

```
$fission fn create --name javatest --pkg  java-src-pkg-zip-dqo5 --env java --entrypoint io.fission.HelloWorld --executortype newdeploy --minscale 1 --maxscale 1
$fission fn test --name javatest
Hello World!
```

You might have noticed that we did not provide any build command to package for building from source. The build still worked because the builder used the default built in command to build the source. You can override this build command to suit your needs. The only requirement is to instruct the builder on how to copy resulting Jar file to function by using the environment variables `$SRC_PKG` and  `$DEPLOY_PKG`. The `$SRC_PKG` is the root from where build will be run so you can form a relative oath to Jar file and copy the file to `$DEPLOY_PKG` Fission will at runtime inject these variables and copy the Jar file.

```
#!/bin/sh
set -eou pipefail
mvn clean package
cp ${SRC_PKG}/target/*with-dependencies.jar ${DEPLOY_PKG}
```

## Modifying the environment images

The JVM environment's source code is available [here](https://github.com/fission/fission/tree/master/environments/jvm). If you only want to add libraries to the OS or add some additional files etc. to environment, it would be easier to simply extend the official Fission JVM environment image and use it.

The JVM builder image source code is [available here](https://github.com/fission/fission/tree/master/environments/jvm/builder) and could be extended or written from scratch to use other tools such as Gradle etc. It would be easier to extend the Fission official image and then add tools.

## Resource usage 

A minimum memory of 128MB is needed for JVM environment.

## Samples

- The Fission Kafka sample is a complete application written in Java and uses Kafka to interact between functions. The source code and more information can be found [here](https://github.com/fission/fission-kafka-sample)

- The Fission workflow sample uses [Fission workflows](https://github.com/fission/fission-workflows) and Java functions. The source code and more information can be found [here](https://github.com/fission/fission-workflow-sample)