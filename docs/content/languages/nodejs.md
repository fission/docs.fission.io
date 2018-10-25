---
title: "Fission functions with Nodejs"
weight: 10
---

Fission supports functions written in Nodejs. Current fission nodejs runtime environment supports node version greater than 7.6.0. In this usage guide we'll cover how to use this environment, write functions, and work with dependencies.

## Before you start

We'll assume you have Fission and Kubernetes setup. If not, head over to the [install guide](../installation/_index.en.md).  Verify your Fission setup with:

```
fission --version
```

## Add the Nodejs runtime environment to your cluster

Fission language support is enabled by creating an _Environment_.  An
environment is the language-specific part of Fission.  It has a
container image in which your function will run.

```
fission environment create --name nodejs --image fission/node-env
```

## Write a simple function in Nodejs

Create a file hello-world.js with the following content

```
module.exports = async function(context) {
    return {
        status: 200,
        body: "hello, world!\n"
    };
}
```

Create a function with the following command. Note that the value for `--env` flag is `nodejs` which was created with `fission env create` command above.

```
fission function create --name hello-world --code hello-world.js --env nodejs
```

Test the function with the below command and you should see "hello, world!" in the output

```
fission fn test --name hello-world
```

## HTTP requests and HTTP responses

### Accessing HTTP Requests

This section gives a few examples of invoking nodejs functions with http requests and how http request components can be extracted inside the function.
While these examples give you a rough idea of the usage, there are more real world example [here](https://github.com/fission/fission/tree/master/examples/nodejs)

#### Headers

Here's an example of extracting http headers from the http request.

Create a file hello.js with the following content. Here the function tries to access the value associated with header with name 'x-internal-token' and it could potentially do some authentication and authorization on the token before returning the response.

```
module.exports = async function(context) {
    console.log(context.request.headers);
    let token = context.request.headers['x-internal-token'];
    console.log("Token presented : ", token);

    // do some authn and authz based on token received
    
    return {
        status: 200,
        body: "hello world!"
    }
}
```

Create a function with the following command.

```
fission function create --name hello-world --code hello-world.js --env nodejs
```

Create an http trigger to invoke the function

```
fission httptrigger create --url /hello-world --function hello-world
```

Test the function with the below command and you should see "hello, world!" in the output

```
curl http://$FISSION_ROUTER/hello-world -H "X-Internal-Token: abcdefghtsdfjsldjf123"
```

#### Query string

Here's an example of extracting the query string from the http request.

Create a file hello-user.js with the following content. Here the function tries to read the value of query parameter user and returns "hello <value supplied as user parameter>". 

```
var url = require('url');

module.exports = async function(context) {
    console.log(context.request.headers);
    console.log(context.request.url)

    var url_parts = url.parse(context.request.url, true);
    var query = url_parts.query;

    console.log("query user : ", query.user);

    return {
        status: 200,
        body: "hello " + query.user + "!"
    }
}
```

Create a function with the following command.

```
fission function create --name hello-user --code hello-user.js --env nodejs
```

Create an http trigger to invoke the function

```
fission httptrigger create --url /hello-user --function hello-user
```

Test the function with the below command and you should see "hello, foo!" in the output

```
curl http://$FISSION_ROUTER/header-example?user=foo
```

#### Body 

First lets see an example of a function which extracts a request body in JSON format.

Create a file job-status.js with the following content. Here the function tries to extract the 'job_id' and the 'job_status' from the http request body and could potentially persist the status somewhere.   

```
module.exports = async function(context) {
    const stringBody = JSON.stringify(context.request.body);
    const body = JSON.parse(stringBody);
    const job = body.job_id;
    const jobStatus = body.job_status;

    // do some db write if required to save the status

    return {
        status: 200,
        body: "Successfully saved job status for job ID: " + job
    };
}
```

Create a function with the following command. 

```
fission function create --name job-status --code job-status.js --env nodejs
```

Create an http trigger to invoke the function

```
fission httptrigger create --url /job-status --function job-status --method POST 
```

Invoke the function with a POST HTTP request with the appropriate JSON body and you will see the response "Successfully saved job status for job ID: 1234"

```
curl -XPOST http://$FISSION_ROUTER/job-status -d '{"job_id" : "1234", "job_status": "Passed"}'
```

Next lets see an example of writing a function which extracts a request body in the Plain Text format

Create a file word-count.js with the following content. Here the function tries to extract a request body and returns the word count of the input text.   

```
module.exports = async function(context) {
    const stringBody = context.request.body;
    console.log("Received stringBody : " + stringBody);

    var splitStringArray = stringBody.split(" ");

    return {
        status: 200,
        body: "word count " + splitStringArray.length
    };
}
```

Create a function with the following command. 

```
fission function create --name word-count --code word-count.js --env nodejs
```

Create an http trigger to invoke the function

```
fission httptrigger create --url /word-count --function word-count --method POST 
```

Invoke the function with a POST HTTP request with a text body and you will see the count of number of words in the HTTP response.

```
curl -XPOST -H "Content-Type: text/plain" http://$FISSION_ROUTER/word-count -d '{"It's a beautiful day!"}'
```

### Controlling HTTP Responses 

This section gives a few examples of invoking nodejs functions with http requests and how the function can return various values as part of HTTP response headers and body.

#### Setting Response Headers

Create a file function-metadata.js with the following content. Here the function returns the fission function metadata added by Fission Router as part of the HTTP response header to the user.   

```
module.exports = async function(context) {
    console.log(context.request.headers);
    
    return {
        status: 200,
        headers: {
            'x-fission-function-name': context.request.headers['x-fission-function-name'],
            'x-fission-function-namespace': context.request.headers['x-fission-function-namespace'],
            'x-fission-function-resourceversion': context.request.headers['x-fission-function-resourceversion'],
            'x-fission-function-uid': context.request.headers['x-fission-function-uid'],
        },
        body: "hello world!"
    }
}
```

Create a function with the following command. 

```
fission function create --name function-metadata --code function-metadata.js --env nodejs
```

Create an http trigger to invoke the function

```
fission httptrigger create --url /function-metadata --function word-count
```

Invoke the function with a '-v' flag on curl command to display all headers

```
curl http://$FISSION_ROUTER/function-metadata -v
```

We can see the headers in the output as below

```
*   Trying 0.0.0.0
.
.
.
< HTTP/1.1 200 OK
< Content-Length: 12
< Content-Type: text/html; charset=utf-8
< Date: Tue, 23 Oct 2018 19:01:55 GMT
< Etag: W/"c-QwzjTQIHJO11oZbfwq1nx3dy0Wk"
< X-Fission-Function-Name: header-example
< X-Fission-Function-Namespace: default
< X-Fission-Function-Resourceversion: 19413500
< X-Fission-Function-Uid: 0014884b-d6e7-11e8-afb7-42010a800194
< X-Powered-By: Express
< 
* Connection #0 to host 0.0.0.0 left intact
hello world!
```

#### Setting Status Codes 

Create a file error-handling.js with the following content. Here the function tries to validate an input parameter "job_id" and sends a HTTP response code 400 when validation fails.   

```
module.exports = async function(context) {
    const stringBody = JSON.stringify(context.request.body);
    const body = JSON.parse(stringBody);
    console.log(body);

    const job = body.job_id;
    const jobStatus = body.job_status;

    console.log("Received CI job id: " + job + " job status: " + jobStatus );

    if (!job) {
        return {
            status: 400,
            body: "job_id cannot be empty"
        };
    }

    return {
        status: 200,
        body: "Successfully saved CI job status for job ID: " + job
    };
}
```

Create a function with the following command. 

```
fission function create --name error-handling --code error-handling.js --env nodejs
```

Create an http trigger to invoke the function

```
fission httptrigger create --url /error-handling --function error-handling --method POST 
```

Invoke the function with this curl command where job_id is empty and you should see "job_id cannot be empty"

```
curl -XPOST http://$FISSION_ROUTER/error-handling -d '{"job_status": "Passed"}'
```

## Working with dependencies

There may be instances where functions need to require node modules that are not packed into the nodejs runtime environment. In such instances, nodejs builder image could be used to `npm install` those modules.
This section describes ways in which this can be achieved.

### Using fission nodejs builder image

#### Example of using the nodejs builder image

fission docker hub has a nodejs builder image `fission/node-builder`. Here's an example of using this image.

First, create an environment with runtime image and builder image as follows 
 
```
fission environment create --name nodejs --image fission/node-env --builder fission/node-builder
```

Next, create a file moment-example.js with the following content. This file requires 'moment' node_module that is not packed into the fission runtime image. Also create a package.json with 'moment' listed in dependencies section.

```
const momentpackage = require('moment')

module.exports = async function(context) {

    return {
        status: 200,
        body: momentpackage().format()
    };
}  
```

Next, create a zip archive of these 2 files, let's call it node-source-example.zip

Now create a fission source package with the zip file just created. This command outputs the name of the package created. 

```
fission package create --src node-source-example.zip --env nodejs
```

Next, create a fission function with the package created above, let's assume the package name is 'node-source-example-abcd'

```
fission function create --name node-builder-example --pkg node-source-example-abcd --env nodejs --entrypoint moment-example
```

If everything was successful so far, then, build status of the source package will be set to 'succeeded'. This can be checked with the following command.

```
fission package info --name node-source-example-abcd
```

Next, test your function with the following and the output should have the current time.

```
fission fn test --name node-builder-example
```

#### Details of the fission nodejs builder image

The builder has a build.sh script that performs an `npm install` of the node modules listed in user provided package.json. The builder image runs this script and packages the result into an archive.   
When the function is invoked, one of the pods running the runtime image is specialized. What this means is that the archive created by the builder is fetched and extracted in the file system.
Next, the user function is loaded according to the entry point specified with `fission fn create command`

### Creating a custom nodejs builder image 

If you'd like to do more than just `npm install` in the build step, you could customize the build.sh.
Here's the link to the source code of fission [nodejs builder](https://github.com/fission/fission/tree/master/environments/nodejs/builder)

As you can see, the build.sh performs a `npm install` inside a directory defined by the environment variable SRC_PKG and copies the built archive into a directory defined by environment variable DEPLOY_PKG 
You could create a customized version of this build.sh with whatever additional commands needed to be run during the build step.

Finally the image can be built with `docker build -t <USER>/nodejs-custom-builder .` and pushed to docker hub with `docker push <USER>/nodejs-custom-builder`

Now you are ready to create a nodejs env with your custom builder image supplied to `--builder` flag

## Modifying the nodejs runtime image

If you wish to modify the nodejs runtime image to add more dependencies without using/creating a builder image, you can do so too.

Here's the link to the source code of fission [nodejs runtime](https://github.com/fission/fission/tree/master/environments/nodejs)

As you can see, there is a package.json in the directory with a list of node modules listed under dependencies section. 
You can add the node modules required to this list and then build the docker image with `docker build -t <USER>/nodejs-custom-runtime .` and push the image `docker push <USER>/nodejs-custom-runtime`

You are now ready to create a nodejs env with your image supplied to `--image` flag

## Resource usage 

Currently the nodejs environment containers are run with default memory limit of 512 MiB and a memory request of 256 MiB. Also, a default CPU limit of 1 and a CPU request of 0.5 cores.

If you wish to create functions with higher resource requirements, you could supply `--mincpu`, `--maxcpu`, `--minmemory` and `--maxmemory` flags during `fission fn create`. Also supply `--executortype newdeploy` to the CLI.


