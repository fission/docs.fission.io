---
title: "Using Python with Fission"
weight: 10
---

Fission supports functions written in Python.  Both Python 2.x and
Python 3.x are supported.  In this usage guide we'll cover how to set
up and use a Python environment on Fission, write functions, and work
with dependencies.  We'll also cover basic troubleshooting.

## Before you start

We'll assume you have Fission and Kubernetes setup.  If not, head over
to the [installation guide](/latest/installation).  Verify your Fission setup with:

```
$ fission --version
```

## Add the Python environment to your cluster

Fission language support is enabled by creating an _Environment_.  An
environment is the language-specific part of Fission.  It has a
container image in which your function will run.

```
$ fission environment create --name python --image fission/python-env --builder fission/python-builder --version 3
```

(The version argument controls some Fission-internal features.  Don't
worry about it much; the right version varies across different
language environments but is fixed for each language.)

## Write a simple function in Python

Create a file named `hello.py`:

```python
def main():
    return "Hello, world!"
```

Create a Fission function (this uploads the file to Fission on the
cluster):

```bash
$ fission function create --name hello --env python --code hello.py 
```

Invoke this function through the Fission CLI:

```bash
$ fission function test --name hello
Hello, world!
```

You can also invoke this function by creating an HTTP trigger and
making an HTTP request to the Fission router.  Ensure you have your
router's address in the `FISSION_ROUTER` environment variable as 
[this guide describes](https://docs.fission.io/0.11.0/installation/env_vars/#fission-router-address).
Then,

```bash
$ fission route create --method GET --url /hello --function hello 

$ curl $FISSION_ROUTER/hello
Hello, world!
```

## Function input and output interface

In this section we'll describe the input and output interfaces of
Python functions in Fission.  Fission's Python integration is built on
the Flask framework.  You can access HTTP requests and responses as
you do in Flask.  We'll provide some examples below.

### Accessing HTTP Requests

#### HTTP Headers

Write a simple `headers.py` with something like this:

```python
from flask import request

def main():
    myHeader = request.headers['x-my-header']
    return "The header's value is '%s'" % myHeader
```

Create that function, assign it a route, and invoke it with an HTTP header:

```bash
$ fission function create --name headers --env python --code headers.py

$ fission route create --name /headers --function headers

$ curl -H "X-My-Header: Hello" $FISSION_ROUTER/headers 
The header's value is 'Hello'
```

#### Query parameters

HTTP Query parameters are the key-value pairs in a URL after the `?`.
They are also available through the request object:

Write a simple `query.py` with something like this:

```python
from flask import request

def main():
    queryParam = request.args.get('myKey')
    return "Value for myKey: %s" % queryParam
```

Create that function, assign it a route, and invoke it with a query parameter:

```bash
$ fission function create --name query --env python --code query.py

$ fission route create --name /query --function query

$ curl $FISSION_ROUTER/query?myKey=myValue
Value for myKey: myValue
```

#### Body 

HTTP POST and PUT requests can have a request body.  Once again, you
can access this body through the request object.

For requests with a JSON Content-Type, you can directly get a parsed
object with `request.get_json()`
[[docs]](http://flask.pocoo.org/docs/1.0/api/#flask.Request.get_json).  

For form-encoded requests ( application/x-www-form-urlencoded), use
`request.form.get('key')`
[[docs]](http://flask.pocoo.org/docs/1.0/api/#flask.Request.form).

For all other requests, use `request.data`
[[docs]](http://flask.pocoo.org/docs/1.0/api/#flask.Request.data) to
get the full request body as a string of bytes.

You can find the full docs on the request object in [the flask
docs](http://flask.pocoo.org/docs/1.0/api/#incoming-request-data).

### Controlling HTTP Responses

The simplest way to return a response is to return a string.  This
implicitly says that your function succeeded with a status code of
200; the returned string becomes the body.  However, you can control
the response more closely using the Flask `response` object.

#### Setting Response Headers

```python
import flask

def main():
    resp = flask.Response("Hello, world!")
    resp.headers['X-My-Response-Header'] = 'Something'
    return resp
```

#### Setting Status Codes 

```python
import flask

def main():
    resp = flask.Response("Hello, world!")
    resp.status_code = 200
    return resp
```

#### HTTP Redirects

### Logging

TODO

## Working with dependencies

### Specifying dependencies and building your source on the cluster

quick intro + link to more info in pip docs

### What to do if your build fails

### Custom builds

TODO show how to provide a build.sh and what it needs to do

TODO you can also add any other stuff to the image, see the next section

## Modifying the environment images

TODO -- link to source code and instructions for rebuilding

## Resource usage 

TODO recommend using min memory and cpu requests. 

TODO -- run hello world with 128m, 256m and find a reasonable minimum
to recommend to people


