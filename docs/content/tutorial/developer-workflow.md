---
title: "Source Code Organization and Your Development Workflow"
date: 2017-12-01T18:01:57-08:00
weight: 61
---

You've made a Hello World function in your favourite language, and
you've run it on your Fission deployment.  What's next?

How should you organize source code when you have lots of functions?
How should you automate deployment into the cluster?  What about
version control?  How do you test before deploying?

The answers to these questions start from a common first step: how do
you _specify an application_?

## Declarative Specifications

Instead of invoking the Fission CLI commands, you can specify your
functions in a set of YAML files.  This is better than scripting the
`fission` CLI, which is meant as a user interface, not a programming
interface.

You'll usually want to track these YAML files in version control along
with your source code.  Fission provides CLI tools for generating
these specification files, validating them, and "applying" them to a
Fission installation.

What does it mean to _apply_ a specification?  It means putting
specification to effect: figuring out the things that need to be
changed on the cluster, and updating them to make them the same as the
specification.

Applying a Fission spec goes through these steps:

 * Resources (functions, triggers, etc) that are in the specification
   but don't exist on the cluster are created.  Local source files are
   packaged and uploaded.
   
 * Resources that are both in the specs and on the cluster are
   compared.  If they're different, the ones on the cluster are
   changed to match the spec.
   
 * Resources present only on the cluster and not in the spec are
   destroyed.  (This deletion is limited to resources that were
   created by a previous _apply_; this makes sure that Fission doesn't
   delete unrelated resources.  See below for how this calculation
   works.)

Note that running _apply_ more than once is equivalent to running it
once: in other words, it's idempotent.

## Usage Summary

Start using Fission's declarative application specifications in 3 steps:

 1. Initialize a directory of specs: `fission spec init`
 1. Generate some YAMLs: `fission function create --spec ...`
 1. Apply them to a cluster: `fission spec apply --wait`

You can also deploy continuously with `fission spec apply --watch`.

We'll see examples of all these commands in the tutorial below.

## Tutorial

This tutorial assumes you've already set up Fission, and tested a
simple hello world function to make sure everything's working.  To
learn how to do that, head over to the [installation
guide](/latest/installation/installation).

We'll make a small calculator app with one python environment and two
functions, all of which will be declaratively specified using YAML
files.  This is a somewhat contrived example, but it is just meant as
an illustration.

### Make an empty directory

```
mkdir spec-tutorial
cd spec-tutorial
```

### Initialize the specs directory

```
fission spec init
```

This creates a `specs/` directory.  You'll see a `fission-config.yaml`
in there.  This file has a unique ID in it; everything created on the
cluster from these specs will be annotated with that unique ID.

### Setup a Python environment

```
fission env create --spec --name python --image fission/python-env:0.10.0 --builder fission/python-builder:0.10.0
```

This command creates a YAML file under specs called `specs/env-python.yaml`.

### Code two functions

One function simply returns a simple web form.  You can download the
code or copy paste from the contents below:

```
  curl -Lo form.py http://xxx
```

Here are its contents:

```python

def main():
    return """
       <html>
         <body>
           <form action="/calculate" method="GET">
             <input name="num_1"/>
             <input name="num_2"/>
             <input name="operator"/>
             <button>Calculate</button>
           </form>
         </body>
       </html>
    """
```

The form accepts a simple arithmetic expression.  When it is
submitted, it makes a request to the second function, which calculates
the expression entered.

Here's the calculator function:

```
   curl -Lo calc.py http://yyy
```

That function is pretty simple too:

```python
def main():
    num_1 = int(request.form['num_1'])
    num_2 = int(request.form['num_2'])
    operator = request.form['operator']

    if operator == '+':
        result = num_1 + num_2
    elsif operator == '-':
        result = num_1 - num_2
        
    return "%s %s %s = %s" % (num_1, operator, num_2, result)
```

### Create specs for these functions

Let's create a specification for each of these functions.  This
specifies the function name, where the code lives, and associates the
function with the python environment:

```
fission function create --spec --name calc-form --env python --src form.py --entrypoint form.main

fission function create --spec --name calc-eval --env python --src calc.py --entrypoint calc.main
```

You can see the generated YAML files in
`specs/function-calc-form.yaml` and `specs/function-calc-eval.yaml`.

### Create HTTP trigger specs

```
fission route create --spec --method GET --url /form --function calc-form
fission route create --spec --method GET --url /eval --function calc-eval
```

This creates YAML files specifying that GET requests on /form and /eval
invoke the functions calc-form and calc-eval respectively.

### Validate your specs

Spec validation does some basic checks: it makes sure there are no
duplicate functions with the same name, and that references between
various resources are correct.

```
fission spec validate
```

You should see no errors.

### Apply: deploy your functions to Fission

You can simply use apply to deploy the environment, functions and HTTP
triggers to the cluster.

```
fission spec apply --wait
```

(This uses your kubeconfig to connect to Fission, just like kubectl.
See Usage Reference below for options.)

### Test a function

Make sure your function is working:

```
fission function test --name calc-form
```

You should see the output of the calc-form function.

To test the other function, open the URL of the Fission router service
in a browser, enter two numbers and an operator, and click submit.

(If you don't know the address of the Fission router, you can find it
with kubectl: `kubectl -n fission get service router`.)

### Modify the function and re-deploy it

Let's try modifying a function: let's change the `calc-eval` function
to support multiplication, too.

```
    ...
    
    elsif operator == '*':
        result = num_1 * num_2

    ...
```

You can add the above lines to `calc.py`, or just download the
modified function:

```
curl -Lo calc.py http://zzz
```

To deploy your changes, simply apply the specs again:

```
fission spec apply --wait
```

This should output something like:

```
1 archive updated: calc-eval-xyz
1 package updated: calc-eval-xyz
1 function updated: calc-eval
```

Your new updated function is deployed!

Test it out by entering a `*` for the operator in the form!

### Add dependencies to the function

Let's say you'd like to add a pip `requirements.txt` to your function,
and include some libraries in it, so you can `import` them in your
functions.

Create a `requirements.txt`, and add something to it:

```
xxx
```

Modify the ArchiveUploadSpec inside specs/function-<name>.yaml

Once again, deploying is the same:

```
fission spec apply --wait
```

This command figures out that one function has changed, uploads the
source to the cluster, and waits until the Fission builder on the
cluster finishes rebuilding this updated source code.

## A bit about how this works

Kubernetes manages its state as a set of _resources_.  Deployments,
Pod, Services are examples of resources.  They represent a target
state, and Kubernetes then does the work to ensure this target state
is met.

Kubernetes resources can be extended, using _Custom Resources_.
Fission runs on top of Kubernetes and sets up your functions,
environments and triggers as Custom Resources.  You can see even these
custom resources from `kubectl`: try `kubectl get
customeresourcedefinitions` or `kubectl get function.fission.io`

Your specs directory is, basically, set of resources plus a bit of
configuration.  Each YAML file contains one or more resources.  They
are separated by a "---" separator.  The resources are functions,
environments, triggers.

There's a special resource there, _ArchiveUploadSpec_.  This is in
fact not a resource, just looks like one in the YAML files.  It is
used to specify and name a set of files that will be uploaded to the
cluster.  `fission spec apply` uses these `ArchiveUploadSpec`s to
create archives locally and upload them.  The specs reference these
archives using `archive://` URLs.  These aren't "real" URLs; they are
replaced by http URLs by the `fission spec` implementation after the
archives are uploaded to the cluster.  On the cluster, Archives are
tracked with checksums; the Fission CLI only uploads archives when
their checksum has changed.

## Usage Reference

```
NAME:
   fission spec - Manage a declarative app specification

USAGE:
   fission spec command [command options] [arguments...]

COMMANDS:
     init      Create an initial declarative app specification
     validate  Validate Fission app specification
     apply     Create, update, or delete Fission resources from app specification
     destroy   Delete all Fission resources in the app specification
     helm      Create a helm chart from the app specification

OPTIONS:
   --help, -h  show help
   
```

### fission spec init

```
NAME:
   fission spec init - Create an initial declarative app specification

USAGE:
   fission spec init [command options] [arguments...]

OPTIONS:
   --specdir value  Directory to store specs, defaults to ./specs
   --name value     (optional) Name for the app, applied to resources as a Kubernetes annotation
   
```

### fission spec validate

```
NAME:
   fission spec validate - Validate Fission app specification

USAGE:
   fission spec validate [command options] [arguments...]

OPTIONS:
   --specdir value  Directory to store specs, defaults to ./specs
```

### fission spec apply

```
NAME:
   fission spec apply - Create, update, or delete Fission resources from app specification

USAGE:
   fission spec apply [command options] [arguments...]

OPTIONS:
   --specdir value  Directory to store specs, defaults to ./specs
   --delete         Allow apply to delete resources that no longer exist in the specification
   --wait           Wait for package builds
   --watch          Watch local files for change, and re-apply specs as necessary
```

### fission spec destroy

```
NAME:
   fission spec destroy - Delete all Fission resources in the app specification

USAGE:
   fission spec destroy [command options] [arguments...]

OPTIONS:
   --specdir value  Directory to store specs, defaults to ./specs

```
