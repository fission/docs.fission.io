---
title: "Building Java Functions"
draft: false
weight: 45
---

With jvm environment there is now support to build functions in Java language. This tutorial explains the working and some inner details of the way Java functions work in Fission.

Let's build a simple "Hello World" function with JVM environment. This example is present in the fission/example/jvm/java directory. Maven will be used as a the tool for managing dependencines and build workflow.

# JVM Environment

The JVM environment in Fission is based on Spring boot and Spring web frameworks. Spring boot & web is already loaded in JVM and if you are using this depdnecney, you can mark it at provided scope. The environment loads the function code from Jar file during specialization and then executes it.

# Fission contract

A function needs to implement the `io.fission.Function` class and override the `call` method. The call method recieves the `RequestEntity` and `Context` as inputs and needs to return `ResponseEntity` object. Both `RequestEntity` and `ResponseEntity` are from `org.springframework.http` package and provide a fairly high level and rich API to interact with request and response.

```
ResponseEntity call(RequestEntity req, Context context);
```

The `Context` object is a placeholder to interact with the platform and provide information about the platform to the code. This also is a extension mechanism to provide more information to runtime code in future.

For both of above to be available to function code, you need to add following dependency with provided scope:

```
<dependency>
	<groupId>io.fission</groupId>
	<artifactId>fission-java-core</artifactId>
	<version>0.0.2-SNAPSHOT</version>
	<scope>provided</scope>
</dependency>
```

# Building a function

## Source code & test

The function code responds with a "Hello World" in response body. `HelloWorldTest.java` is a simple unit test which asserts that expected output is same as actual output.

```
public class HelloWorld implements Function {

	@Override
	public ResponseEntity<?> call(RequestEntity req, Context context) {
		return ResponseEntity.ok("Hello World!");
	}

}
```

## Project & dependencies with Maven

First you have to define the the basic information about the function:

```
	<modelVersion>4.0.0</modelVersion>
	<groupId>io.fission</groupId>
	<artifactId>hello-world</artifactId>
	<version>1.0-SNAPSHOT</version>
	<packaging>jar</packaging>

	<name>hello-world</name>
```
You will have to add two dependencies which are provided by the function runtime, so both them of scope as provided.

One of the key things when packaging the Java function is to package it as a uber jar (fat jar) so that the class and all other dependencies are packaged with function. For that you can use `maven-assembly-plugin` and it is coupled to the package phase of the build.

```
<execution>
	<id>make-assembly</id> <!-- this is used for inheritance merges -->
	<phase>package</phase> <!-- bind to the packaging phase -->
	<goals>
		<goal>single</goal>
	</goals>
</execution>
```

Lastly since the `fission-java-core` is currently in the snapshot release, you need to explicitely add the sonatype repository which is where it is published. 

```
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
```
docker run -it --rm  -v "$(pwd)":/usr/src/mymaven -w /usr/src/mymaven maven:3.5-jdk-8 mvn clean package
```

At this stage we assume that build succeeded you have the jar file of the function ready.

## Deploying the function

First you will need to create an environment. The `extract` flag is important for Java based applications packaged as Jar file. This flag will ensure that the fetcher won't extract the Jar file into a directory. Currently JVM environment only supports version 2 & above so we specify the environment version as 2

```
$ fission env create --name jvm --image fission/jvm-env --version 2 --extract=false
```

When creating the function we provide the jar file built in earlier steps and the environment. The entrypoint signifies the fully qualified name of the class which implements the Fission's `Function` interface. 

```
$ fission fn create --name hello --deploy target/hello-world-1.0-SNAPSHOT-jar-with-dependencies.jar --env jvm --entrypoint io.fission.HelloWorld
```
Lastly you can create a route and test that the function works!

```
$ fission route create --function hello --url /hellon --method GET

$ curl $FISSION_ROUTER/hello
Hello World!
```