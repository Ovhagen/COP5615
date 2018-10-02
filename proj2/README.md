# Project 2

This is project 2 in the course COP5615 Distributed Operating System Principles.

In this project we implemented the gossip and push-sum algorithms over networks of arbitrary size with various network topologies.

### Authors
Lars Pontus Ovhagen (UFID 2992-9498)

James Howes (UFID 9262-9312)

## Running the program

You can run the program for a single input with the following command:

```sh
$ mix run proj2.exs numNodes topology algorithm
```

where `numNodes` is an integer > 1, `topology` is one of `full`, `3D`, `rand2D`, `sphere`, `line`, `imp2D` and `algorithm` is one of `gossip`, `push-sum`.

## What is working

All project requirements have been implemented fully, with one slight modification to the spec in order to improve the performance of the push-sum algorithm.

### Topologies

The Proj2.Topology module provides functions which can generate all of the topologies in the project spec and many more.

The `grid/4` function can produce any orthogonal grid topology of an arbitrary number of dimensions, with the options to have the dimensions "wrap around" as in the sphere topology, as well as include random neighbors as in the imperfect line topology. Furthermore, the number of nodes need not be a perfect square/cube/hypercube.

The `proximity/4` function produces a proximity-based topology as in the random 2D grid, but can handle an arbitrary number of dimensions, as well as a fixed distribution instead of random.

> Note that proximity-based topologies are not checked for connectedness. Therefore, random grid networks with too few nodes (~300 or fewer, for a 2D grid) are unlikely to be connected and will fail to achieve convergence.

### Communication algorithms

The gossip algorithm is implemented as described in the specification. Since the specification described __termination__ but not convergence, we assumed that the network converged when every node had received the message at least once.

The push-sum algorithm is implemented as described, with one modification: Nodes will not converge until the ratio did not change for __5__ consecutive rounds instead of 3. The reason we made this modification is because a "round" is defined as sending a message, and in some networks it not uncommon for a node to send 3 messages before ever receiving a message from a neighbor. Increasing this threshold to 5 improves the likelihood that all nodes converge close to the true average. Increasing it to 10 will provide near-certainty that all nodes converge to the true average with negligible error, at the cost of increasing running time.

Furthermore, our gossip nodes are generic so many different algorithms can be implemented. See the Proj2.Messenger and Proj2.PushSum modules for examples of how to configure the nodes.

### Configuration

Additionally, we made accommodations to configure the program for alternative operation, using the `config/config.exs` file:

- `delay`: the minimum delay between sending messages. The maximum delay is _e_ times this number.
- `msg_count`: for _Gossip_, the maximum number of messages a node can receive before terminating.
- `ps_count`: for _Push-Sum_, the number of rounds with minimal change in ratio before terminating.
- `epsilon`: for _Push-Sum_, the threshold for registering a change in ratio.

## Largest networks handled

### Gossip

Topology | Size | Messages to convergence
--- | ---:| ---:
Full | 16,384 | 330,318
3D Grid | 16,384 | 5,185,458
Random 2D Grid | 32,768 | 889,462
Sphere | 16,384 | 10,105,995
Line | 4,096 | 2,195,643
Imperfect Line | 32,768 | 29,654,700

### Push-Sum

Topology | Size | Messages to convergence
--- | ---:| ---:
Full | 10,000 | 478,433
3D Grid | 32,768 | 2,543,005
Random 2D Grid | 16,384 | 727,928
Sphere | 32,768 | 2,706,382
Line | 1,024 | 110,897
Imperfect Line | 65,536 | 6,442,885
