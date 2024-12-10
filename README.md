# Docker Ruby Multi-Version

# Table of Contents
- [Description](#description)
- [Prerequisites](#prerequisites)
- [Project Information](#project-information)
- [Dockerfile and Ruby Configuration](#dockerfile-and-ruby-configuration)
- [Handling Ruby Compilation and Installation](#handling-ruby-compilation-and-installation)
- [Limitations](#limitations)
- [Tests](#tests)
- [How to Build](#how-to-build)
- [CI/CD and Docker Hub](#cicd-and-docker-hub)

## Description

This project builds a Docker image containing the latest minor versions of Ruby
(2.3 to 3.3 inclusive), enabling seamless multi-version Ruby development and testing.
The image uses `RVM` to manage Ruby installations, ensuring compatibility
across diverse environments.

## Prerequisites
- Docker

## Project Information
- The docker image is build using a [Dockerfile](./Dockerfile)
- The image is based on ubuntu:24.04.
- The image size is approximately 5 GB.
- Build time is around 10-15 minutes, depending on system performance.

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

## Handling Ruby Compilation and Installation
Since most Ruby versions in the given list are not available as precompiled binaries,
nearly all of them must be compiled from source. The compilation process can be quite
time-consuming, so tasks are executed concurrently to save time.

### Dependency Installation
Before starting the Ruby installations, all necessary dependencies are installed
sequentially. This step avoids potential race conditions caused by attempting to
run `apt-get update` from multiple processes simultaneously.

### Concurrent Ruby Installation
The Ruby versions are iterated and installed in parallel, with a 10-second delay
between starting each process. This delay is introduced to mitigate race conditions
arising from rvm accessing shared files during the installation process.

### Installing Bundler
After all Ruby versions are installed, the bundler gem is installed for
each version using the same approach. By applying the same precautions
during this step, the process avoids conflicts and ensures stability.

## Limitations
Since this project uses three different openssl versions (1.0, 1.1, and 3.0), with 1.0 
and 1.1 being deprecated,some gems may encounter issues. For instance, an application 
using the http gem might attempt to access websites without valid certificates. 
While the application will execute, it could result in runtime errors during such requests.

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

```bash
# Build the Docker image
docker build -t <image_name> .

# Run a container
docker run -it <image_name>
```

## CI/CD and Docker Hub
The Docker image is built automatically on every push to the repository and uploaded to
[Docker hub](https://hub.docker.com/repository/docker/sebastian2309/ruby-multi-version/general). On every build it checks
Before the image is pushed, the pipeline ensures that all requirements are met 
by running the specified tests. If any test fails, the build is halted, 
and the pipeline fails.