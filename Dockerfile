FROM ubuntu:latest
RUN apt-get update
RUN apt-get -y install g++
COPY HelloWorld /HelloWorld
WORKDIR /HelloWorld/
RUN g++ -o HelloWorld helloworld.cpp
CMD ["./HelloWorld"]
