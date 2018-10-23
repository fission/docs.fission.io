---
title: "Fission functions with Nodejs"
weight: 10
---

Fission supports functions written in Nodejs. In this usage guide we'll cover how to use
this environment, write functions, and work with dependencies.

## Before you start

We'll assume you have Fission and Kubernetes setup. If not, head over
to the [install guide]().  Verify your Fission setup with:

```
fission --version
```

## Add the Nodejs environment to your cluster

Fission language support is enabled by creating an _Environment_.  An
environment is the language-specific part of Fission.  It has a
container image in which your function will run.

```
fission environment create --name nodejs --image fission/node-env --builder fission/node-builder
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

This section gives a few examples of invoking nodejs functions with http requests and how http request components can be extracted inside the function

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

Test the function with the below command and you should see "hello, world!" in the output

```
curl http://$FISSION_ROUTER/header-example?user=foo
```

#### Body 

First lets see an example of writing a function which extracts a request body in Plain text format and returns the word count

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

Create a file error-handling.js with the following content. Here the function tries to validate input parameters and sends a HTTP response code 400 when validation fails.   

```

```

Create a function with the following command. 

```
```

Create an http trigger to invoke the function

```
```

Invoke the function with a '-v' flag on curl command to display all headers

```
```

## Working with dependencies

### requirements.txt

quick intro + link to more info in pip docs

### Custom builds

TODO show how to provide a build.sh and what it needs to do

TODO you can also add any other stuff to the image, see the next section

## Modifying the environment images

TODO -- link to source code and instructions for rebuilding

## Resource usage 

TODO recommend using min memory and cpu requests. 

TODO -- run hello world with 128m, 256m and find a reasonable minimum
to recommend to people


