---
title: "Building Java Functions"
draft: false
weight: 64
---

With the [JVM environment](https://github.com/fission/fission/tree/master/environments/jvm) there is now support to use Java functions in Fission. This tutorial explains about the working and some inner details of the way Java functions work in Fission.

To see this Java support in action, we are going to build a simple "Hello World" function with the JVM environment. This example can also be found in [examples directory on GitHub](https://github.com/fission/fission/tree/master/examples/jvm/java).

# JVM Environment

The JVM environment in Fission is based on [Spring boot](https://spring.io/projects/spring-boot) and [Spring web frameworks](https://docs.spring.io/spring/docs/current/spring-framework-reference/web.html). Spring boot & web is already loaded in JVM and if you are using this dependency, you can mark it at provided scope. The environment loads the function code from JAR file during specialization and then executes it.

# Fission contract

A function needs to implement the `io.fission.Function` class and override the `call` method. The call method receives the `RequestEntity` and `Context` as inputs and needs to return `ResponseEntity` object. Both `RequestEntity` and `ResponseEntity` are from `org.springframework.http` package and provide a fairly high level and rich API to interact with request and response.

```java
ResponseEntity call(RequestEntity req, Context context);
```

The `Context` object is a placeholder to interact with the platform and provide information about the platform to the code. This also is a extension mechanism to provide more information to runtime code in future.

# Building a function

## Source code & test

The function code responds with "Hello World" in response body.

```java
public class HelloWorld implements Function {

	@Override
	public ResponseEntity<?> call(RequestEntity req, Context context) {
		return ResponseEntity.ok("Hello World!");
	}

}
```

## Project & dependencies with Maven

First you have to define the the basic information about the function:

```xml
<modelVersion>4.0.0</modelVersion>
<groupId>io.fission</groupId>
<artifactId>hello-world</artifactId>
<version>1.0-SNAPSHOT</version>
<packaging>JAR</packaging>

<name>hello-world</name>
```
You will have to add two dependencies which are provided by the function runtime, so both them of scope as provided.

```xml
<dependencies>
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
</dependencies>
```


One of the key things when packaging the Java function is to package it as a uber/fat JAR so that the class and all other dependencies are packaged with function. For that you can use `maven-assembly-plugin`:

```xml
<execution>
	<id>make-assembly</id> <!-- this is used for inheritance merges -->
	<phase>package</phase> <!-- bind to the packaging phase -->
	<goals>
		<goal>single</goal>
	</goals>
</execution>
```

Lastly since the `fission-java-core` is currently in the snapshot release, you need to explicitely add the sonatype repository which is where it is published. 

```xml
<repositories>
	<repository>
		<id>fission-java-core</id>
		<name>fission-java-core-snapshot</name>
		<url>https://oss.sonatype.org/content/repositories/snapshots/</url>
	</repository>
</repositories>
```
## Building the package

For building the source Java code with Maven, you either need Maven and Java installed locally or you can use the `build.sh` helper script which builds the code inside a docker image which has those dependencies.
```bash
$ docker run -it --rm  -v "$(pwd)":/usr/src/mymaven -w /usr/src/mymaven maven:3.5-jdk-8 mvn clean package
```

At this stage we assume that build succeeded and you have the JAR file of the function ready.

## Deploying the function

First you will need to create an environment. The `extract` flag is important for Java based applications packaged as JAR file. This flag will ensure that the fetcher won't extract the JAR file into a directory. Currently JVM environment only supports version 2 & above so we specify the environment version as 2

```bash
$ fission env create --name jvm --image fission/jvm-env --version 2 --keeparchive
```

When creating the function we provide the JAR file built in earlier steps and the environment. The entrypoint signifies the fully qualified name of the class which implements the Fission's `Function` interface. 

```bash
$ fission fn create --name hello --deploy target/hello-world-1.0-SNAPSHOT-JAR-with-dependencies.JAR --env jvm --entrypoint io.fission.HelloWorld
```
Lastly you can create a route and test that the function works!

```bash
$ fission route create --function hello --url /hellon --method GET

$ curl $FISSION_ROUTER/hello
Hello World!
```

# What's next

- More examples can be found in [examples directory on GitHub](https://github.com/fission/fission/tree/master/examples/jvm/)
