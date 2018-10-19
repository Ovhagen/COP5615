# Project 3

This is project 3 in the course COP5615 Distributed Operating System Principles.

In this project we implemented the Chord protocol for a peer-to-peer distributed hash table. The project is exclusively written in Elixir with the help of the actor model functionality.

### Authors
Lars Pontus Ovhagen (UFID 2992-9498)

James Howes (UFID 9262-9312)

## Running the program

You can run the program for a single input with the following command:

```sh
$ mix run proj3.exs numNodes numRequests
```

where `numNodes` is an integer > 1 and `numRequests` is an integer > `numNodes`*.

An answer is given as a decimal number in the command prompt, representing the calculation of the average number of hops to resolve a request.

* Note that if the number of requests is less than the number of nodes the program will fail to run.

## What is working

All the requirements stated in the project description has been fully fulfilled. 


## What is the largest network you managed to deal with

The largest network we managed to obtain with about XXX requests for each node was:



