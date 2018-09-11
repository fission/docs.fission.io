---
title: "Environments"
draft: false
weight: 22
---

An environment contains the language and runtime specific parts of a function. An environment is essentially a container with a webserver and a dynamic loader for the function code.

The following pre-built environments are currently available for use in Fission:
 
| Environment                          | Image                     |
| ------------------------------------ | ------------------------- |
| Binary (for executables or scripts)  | `fission/binary-env`      |
| Go                                   | `fission/go-env`          |
| Java                                 | `fission/fission/jvm-env` |    
| .NET                                 | `fission/dotnet-env`      |
| .NET 2.0                             | `fission/dotnet20-env`    |
| NodeJS (Alpine)                      | `fission/node-env`        |
| NodeJS (Debian)                      | `fission/node-env-debian` |
| Perl                                 | `fission/perl-env`        |
| PHP 7                                | `fission/php-env`         |
| Python 3                             | `fission/python-env`      |
| Ruby                                 | `fission/ruby-env`        |

To create custom environments you can extend one of the environments in the list or create your own environment from scratch.

## Environment Interface

Currently, fission environment has two interfaces:  v1, v2

* v1
  * Support to load a function from one single file.

* v2
  * Support to load the function from one file or from the directory
  * Support `--entrypoint` to specify which function need to be loaded in.
  * Support pkg builder to build pkg from a source package

Following is the interface implementation status

Environment | v1 | v2
------------ | --- | ---
binary | v | v
go | v | v
jvm (language run on jvm)| v | v
python | v | v
dotnet | v | x
dotnet20 | v | x
nodejs | v | x
perl | v | x
php7 | v | x
ruby | v | x

For how to contribute environment v2 interface, please refer: https://github.com/fission/fission/issues/807 
