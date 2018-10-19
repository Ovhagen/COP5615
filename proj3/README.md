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

where `numNodes` is an integer > 1 and `numRequests` is an integer which specifies the number of requests each peer has to make.

An answer is given as a decimal number in the command prompt, representing the calculation of the average number of hops to resolve a request.


## What is working

All the requirements stated in the project description has been fully fulfilled and our implementation reflects the API calls specified in the original Chord paper. The program simulates the nodes in the network -- using one actor for each peer -- where you can successfully store keys on each node in the network and perform a key lookup.


## What is the largest network you managed to deal with

The largest network we managed to obtain with about XXX requests for each node. For this specific run we had the following parameters:

Number of nodes | Requests | Average number of hops
--- | ---:| ---:
50,000 | 100,000 | 9.85619

