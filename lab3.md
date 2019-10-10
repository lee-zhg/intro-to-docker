# Lab 3 - Custom Docker Images with C++ HelloWorld application

© Copyright IBM Corporation 2017

IBM, the IBM logo and ibm.com are trademarks of International Business Machines Corp., registered in many jurisdictions worldwide. Other product and service names might be trademarks of IBM or other companies. A current list of IBM trademarks is available on the Web at &quot;Copyright and trademark information&quot; at www.ibm.com/legal/copytrade.shtml.

This document is current as of the initial date of publication and may be changed by IBM at any time.

The information contained in these materials is provided for informational purposes only, and is provided AS IS without warranty of any kind, express or implied. IBM shall not be responsible for any damages arising out of the use of, or otherwise related to, these materials. Nothing contained in these materials is intended to, nor shall have the effect of, creating any warranties or representations from IBM or its suppliers or licensors, or altering the terms and conditions of the applicable license agreement governing the use of IBM software. References in these materials to IBM products, programs, or services do not imply that they will be available in all countries in which IBM operates. This information is based on current IBM product plans and strategy, which are subject to change by IBM without notice. Product release dates and/or capabilities referenced in these materials may change at any time at IBM&#39;s sole discretion based on market opportunities or other factors, and are not intended to be a commitment to future product or feature availability in any way.


# Overview

In this lab, we extend on our knowledge from lab 2 where we created a custom Docker Image built from a Dockerfile and deploy a Python application. We'll created a custom Docker Image based on a C++ HelloWorld application. Once we build the image, we will push it to a central registry where it can be pulled to be deployed on other environments. Also, we will briefly describe image layers, and how Docker incorporates "copy-on-write" and the union file system to efficiently store images and run containers.

The same Docker commands will be used in this lab. For full documentation on available commands check out the [official documentation](https://docs.docker.com/).


## Prerequisites

You must have docker installed, or be using https://www.katacoda.com/courses/docker/playground.


# Step 1: Clone the repository

1. Opena terminal window.

1. Run command

    ```bash
    cd /data
    git clone https://github.com/lee-zhg/intro-to-docker.git
    ```
1. Navigate to folder `intro-to-docker`

    ```bash
    cd  intro-to-docker
    ```


# Step 2: Create and build the Docker Image

One file and one folder in the root directory of the repository are specifically prepared and used for this lab.
  * Dockerfile
  * /HelloWorld

1. Sample C++ application `HelloWorld/helloworld.cpp`

    A simple Hello World C++ application is used to build the Docker image in this lab.

    ```
    #include <iostream>
    using namespace std;
     
    int main()
    {
      cout << "Hello world!" << endl;
      return 0;
    }
    ```

2. Sample `Dockerfile` file

    Sample `Dockerfile` file in the repo will be used to build the Docker image.

    ```
    FROM ubuntu:latest
    RUN apt-get update
    RUN apt-get -y install g++
    COPY HelloWorld /HelloWorld
    WORKDIR /HelloWorld/
    RUN g++ -o HelloWorld helloworld.cpp
    CMD ["./HelloWorld"]
    ```

    A Dockerfile lists the instructions needed to build a docker image. Let's go through the above file line by line.

    **FROM ubuntu:latest**
    This is the starting point for your Dockerfile. Every Dockerfile must start with a `FROM` line that is the starting image to build your layers on top of. In this case, we are selecting the `ubuntu:latest` base layer. For simplicity, the `latest` version is used for its latest distribution. 

    For security reasons, it is very important to understand the layers that you build your docker image on top of. For that reason, it is highly recommended to only use "official" images found in the [docker hub](https://hub.docker.com/), or non-community images found in the docker-store. These images are [vetted](https://docs.docker.com/docker-hub/official_repos/) to meet certain security requirements, and also have very good documentation for users to follow. 

    **RUN apt-get update and RUN apt-get -y install g++**
    This two commands install `g++` in the container to compile the sample C++ application.

    **COPY HelloWorld /HelloWorld**
    This copies the folder `HelloWorld` and C++ application in the local directory (where you will run `docker image build`) into a new layer of the image. 

    **WORKDIR /HelloWorld/**
    This entry defines the working directory.

    **RUN g++ -o HelloWorld helloworld.cpp**
    This entry compiles the sample C++ application.

    **CMD ["./HelloWorld"]**
    `CMD` is the command that is executed when you start a container. Here we are using `CMD` to run our C++ app executable. 

    There can be only one `CMD` per Dockerfile. If you specify more thane one `CMD`, then the last `CMD` will take effect. The parent `ubuntu:latest` also specifies a `CMD`. 

    The compiling process is handled in the above `Dockerfile` for the simplicity during the exercise. The `Dockerfile` below can be an alternative. However, it requires the C++ source code to be complied on the exactly same platform as the Docker base image before the Docker image is built, because the C++ libraries are different on different platforms. 

    ```sh
    FROM ubuntu:latest
    CMD ["./HelloWorld"]
    COPY HelloWorld /HelloWorld
    ```

3. Build the docker image. 

    Pass in parameter `-t` to name your image `cplus-hello-world`.

    ```sh
    $ docker image build -t cplus-hello-world .

    Sending build context to Docker daemon  23.55kB
    Step 1/3 : FROM ubuntu:latest
      ---> 3556258649b2
    Step 2/3 : CMD ["./HelloWorld"]
      ---> Running in c226de4577af
    Removing intermediate container c226de4577af
      ---> 8ea4d7516a0d
    Step 3/3 : COPY HelloWorld /HelloWorld
      ---> a16a0b0a6a65
    Successfully built a16a0b0a6a65
    Successfully tagged cplus-hello-world:latest
    ```

    > Note: it may take a while when you build this Docker image for the first time. It take time to install and prepare the `g++` environment.

4. Verify that your image shows up in your image list via `docker image ls`.

    ```sh
    $ docker image ls

    REPOSITORY                                                                           TAG                    IMAGE ID            CREATED             SIZE
    cplus-hello-world                                                                    latest                 a16a0b0a6a65        7 minutes ago       64.2MB
    ubuntu                                                                               latest                 3556258649b2        2 months ago        64.2MB
    ```

    Notice that your base image, `ubuntu:latest`, is also in your list.


# Step 3: Run the Docker image

Now that you have built the image, you can run it to see that it works.

1. Run the Docker image

    ```sh
    $ docker run cplus-hello-world

    Hello world!
    ``` 

    This is a simple C++ application. Its only action is to print `Hello World!` to the standard out.


# Step 4: Push to a central registry

1. Navigate to https://hub.docker.com and create an account if you haven't already

    For this lab we will be using the docker hub as our central registry. Docker hub is a free service to store publicly available images, or you can pay to store private images. Go to the [DockerHub](https://hub.docker.com) website and create a free account.

    Most organizations that use docker heavily will set up their own registry internally. To simplify things, we will be using the Docker Hub, but the following concepts apply to any registry.

2. Login

    You can log into the docker registry account by typing `docker login` on your terminal.

    ``` 
    $ docker login

    Login with your Docker ID to push and pull images from Docker Hub. If you don't have a Docker ID, head over to https://hub.docker.com to create one.
    Username: 
    ```

3. Tag your image with your username

    The Docker Hub naming convention is to tag your image with [dockerhub username]/[image name]. To do this, we are going to tag our previously created image `python-hello-world` to fit that format.

    ```sh
    $ docker tag <your dockerhub username>/cplus-hello-world
    ```

4. Push your image to the registry

    Once we have a properly tagged image, we can use the `docker push` command to push our image to the Docker Hub registry.

    ```sh
    $ docker push <your dockerhub username>/cplus-hello-world

    The push refers to repository [docker.io/leezhang/cplus-hello-world]
    c5ec7971f99d: Mounted from leezhang/python-hello-world 
    435ff70f00d3: Mounted from leezhang/python-hello-world 
    5f354b8b5dc0: Mounted from leezhang/python-hello-world 
    f61107386c17: Mounted from leezhang/python-hello-world 
    db49993833a0: Mounted from leezhang/python-hello-world 
    58c71ea40fb0: Mounted from leezhang/python-hello-world 
    2b0fb280b60d: Mounted from leezhang/python-hello-world 
    latest: digest: sha256:48b9a1f561c716ad62ad4328a68cf2bad518918d51abf0452535f14d48167d20 size: 1786
    ```

5. Check out your image on docker hub in your browser

    Navigate to https://hub.docker.com and go to your profile to see your newly uploaded image.

    Now that your image is on Docker Hub, other developers and operations can use the `docker pull` command to deploy your image to other environments.  

    **Note:** Docker images contain all the dependencies that it needs to run an application within the image. This is useful because we no longer have deal with environment drift (version differences) when we rely on dependencies that are install on every environment we deploy to. We also don't have to go through additional steps to provision these environments. Just one step: install docker, and you are good to go.


# Step 5: Deploying a Change
The "hello world!" application is overrated, let's update the app so that it says "Hello Beautiful World!" instead.

1. Update sample code `helloworld.cpp`

    Replace the string "Hello World" with "Hello Beautiful World!" in `helloworld.cpp`. 

2. Rebuild your image

    Now that your app is updated, you need repeat the steps above to rebuild your app and push it to the Docker Hub registry.

    First rebuild, this time use your Docker Hub username in the build command.:


    ```sh
    $  docker image build -t <your dockerhub username>/cplus-hello-world .

    Sending build context to Docker daemon  3.072kB
    Step 1/4 : FROM python:3.6.1-alpine

    ```

    Notice the "Using cache" for steps 1-3. These layers of the Docker Image have already been built and `docker image build` will use these layers from the cache instead of rebuilding them.

3. Push your image

    ```sh
    $ docker push <your dockerhub username>/cplus-hello-world

    The push refers to a repository [docker.io/jzaccone/python-hello-world]
    ```

    There is a caching mechanism in place for pushing layers too. Docker Hub already has all but one of the layers from an earlier push, so it only pushes the one layer that has changed.

    When you change a layer, every layer built on top of that will have to be rebuilt. Each line in a Dockerfile builds a new layer that is built on the layer created from the lines before it. This is why the order of the lines in our Dockerfile is important. 


# Step 6: Clean up

1. Remove the stopped containers

    ```sh
    $ docker system prune
    
    WARNING! This will remove:
        - all stopped containers
        - all volumes not used by at least one container
        - all networks not used by at least one container
        - all dangling images
    Are you sure you want to continue? [y/N] y
    Deleted Containers:
    0b2ba61df37fb4038d9ae5d145740c63c2c211ae2729fc27dc01b82b5aaafa26

    Total reclaimed space: 300.3kB
    ```

    `docker system prune` is a really handy command to clean up your system. It will remove any stopped containers, unused volumes and networks, and dangling images.


# Summary

In this lab, you created your own custom docker containers hosting your C++ sample application. 
