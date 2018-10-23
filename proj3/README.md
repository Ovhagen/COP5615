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

An answer is given as a decimal number in the command prompt, representing the calculation of the average number of hops to resolve a request. It can take up to a minute to produce an answer, as the chord network requires time to stabilize before the test can be run.

Parameters in `config/config.exs` can be adjusted to change the chord operating conditions:
- `id_bits`: the number of bits to use for node and key IDs
- `timeout`: the time that a node will wait before timing out on a request to another node
- `delay`: delay between calls to stabilize, fix_fingers, and check_predecessor
- `jitter`: random variation added to the delay values above
- `replication`: controls replication of data, 0 = no replication (discussed in bonus section)


## What is working

All the requirements stated in the project description has been fully fulfilled and our implementation reflects the API calls specified in the original Chord paper. The program simulates the nodes in the network -- using one actor for each peer -- where you can successfully store keys on each node in the network and perform a key lookup.

We modified the pseudocode algorithms from the Chord paper in the following ways:
- When a node updates its finger table through fix_fingers(), it will update all entries in the table for which the new finger is the successor. Furthermore, the next finger to be updated will be the one after the last entry that was just updated. This optimization speeds up the initial finger table update for new nodes.
- Similarly, when a node receives notifications from potential predecessors, it will also check the node against its finger table. This also helps speed up stabilization when a new chord network is started.
- We have also implemented failure handling and data replication (discussed in the bonus section below).

## What is the largest network you managed to deal with

Our implementation of is capable of handling an arbitrary number of nodes, but on a single machine we reached a limit of roughly 50,000 nodes before we were constrained by processing power. We can increase this limit marginally by reducing the frequency of the maintenance functions executed by each node so the processor is not overwhelmed by the number of messages.

Number of nodes | Requests | Average number of hops
--- | ---:| ---:
50,000 | 100,000 | 9.85619

## Bonus

Our chord nodes can handle and respond to failures in neighboring nodes. Failures are detected when a request times out, at which point the requesting node will remove the failed node from its finger table and retry with the next best successor. In order to detect failures correctly and avoid cascading timeouts on requests that jump across the chord, all messaging must be done asynchronously (casts instead of calls).

The Chord paper did extensive testing of performance under failure conditions, so we decided to test data loss under varying data replication schemes. We created a configuration parameter (`replication` in `config.exs`) which instructs the chord nodes to store multiple copies of each key within the chord. The value is exponential 2^n, e.g. a value of 0 will store one copy (no replication), a value of 1 will store two copies, 2 will store four copies, etc.

The Chord paper mentioned a possible replication scheme where copies are stored in multiple successors, but we decided on a much simpler implementation. The copies are stored at "equidistant" locations along the chord, so effectively each key gets multiple ids and lookups will attempt to find the key at each id before failing.

### Results

We tested our system by initializing a network of 2000 nodes, seeding it with an average of 20 keys per node, triggering failure on some proportion of the nodes, and then attempting to retrieve all of the keys. With no replication, the data loss is equal to or greater than the failure rate. We observed that data loss sometimes exceeded 50% when only 25% of the nodes had failed. We believe this is due to "orphaned" nodes which lost all connections to the rest of the chord when the failure occurred, or perhaps the chord split into multiple disjoint networks. Triggering the failures slowly over time, to allow the network to maintain its integrity, could alleviate this problem.

When storing two copies of each key, the network still lost a small amount of data (~0.2%) when only 5% of the nodes failed. However, even at 15% failure rates, the data loss was only about 2%.

Performance improved dramatically with four copies of each key: there was no data lost at all with a 15% failure rate, and roughly 1% data loss at 25% failure rate. At eight copies the chord safely retained all data even when 25% of the nodes failed simultaneously.

You can run data replication tests by changing the value of the `replication` parameter and then running the following script:

```sh
$ mix run bonus.exs numNodes failure_rate
```

where `failure_rate` is a float between 0 and 1.
