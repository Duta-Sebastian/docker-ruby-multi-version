# Docker Ruby Multi-Version

# Description

This project builds a docker image that contains the
latest minor version for each major ruby version from
2.3 to 3.3, inclusive. The rubies are managed by rvm.

## Prerequisites
- Docker

## Project Information
- The docker image is build using a [Dockerfile](./Dockerfile)
- The image is based on the docker image ubuntu:24.04
- The built image occupies ~5 GB of storage space
- The build time is ~10-15 minutes

## Dockerfile and ruby configuration
As the rubies needed in this project cover a large range of versions,
the installation process has to be separated into 3 categories:
- **Ruby version 2.3.8** -> this version needs `openssl 1.0` to properly compile
- **Ruby versions 2.4.10, 2.5.9, 2.6.10, 2.7.8, 3.0.7** -> these versions need `openssl 1.1` to properly compile
- **Ruby versions 3.1.6, 3.2.6, 3.3.6** -> these versions need `openssl 3.0` to properly compile

As we need all 3 openssl versions to use the installed rubies and their bundlers,
we have to build each of them from scratch so we can set a distinct install location. In this case,
the following locations were chosen :
- **Openssl 1.0** is installed at `/usr/local/ssl1.0`
- **Openssl 1.1** is installed at `/usr/local/ssl1.1`
- **Openssl 3.0** is installed at `/usr/local/ssl3.0`

Because support has ended for `openssl 1.0` and `openssl 1.1` has been
discontinued, the certificates associated with them are invalid.
As such, we will not be able to use the rubies that have been compiled
using them to do http requests or similar.

Each Ruby version uses the latest bundler version it supports, ensuring compatibility with Gemfiles and other dependencies.

## Limitations
As we are using 3 different `openssl` versions, some of which are discontinued (i.e 1.0 and 1.1), there can be situations in
which a certain gem will not work. For example an app using the `http` gem will not work as it will try to 
access websites without a valid certificate ( the app will execute, but it will have runtime errors ).

## Tests
1. The first test written to ensure the solution successfully solves the given task is the
[verify_ruby_builder](./verify_ruby_builder.sh). This bash script cycles through all the 
installed versions and executes a small ruby program ( [print_ruby_version](./print_ruby_version.rb) )
that print the ruby and the bundler versions. The bash script compares the actual output to
the expected output and exits with code 1 if there are any mismatches.<br>
This test ensures that all expected ruby versions have been installed.<br>

2. The second test is a simple ruby app that uses the `json` gem (installed using a
[Gemfile](./simple_ruby_app/Gemfile)). The app is run using a bash script that cycles
through all the versions and tests if the bundler works (i.e. installs the necessary gem)
and if the output matches the expected output ( if not, the bash script will exit with code 1).<br>
This test ensures that all ruby versions can use a Gemfile.

All the tests are copied to the docker image after all the rubies have been compiled ( to a directory named ruby_tests).
Afterward, the tests are run and the build process stops if any of the tests are unsuccessful.

## How to build
To build the image you have to the run command `docker build -t <image_name> .`. After the build process finishes,
you can access create a container using the created image using `docker run -it <image_name>`. The build process will
fail if the aforementioned tests fail.

## 