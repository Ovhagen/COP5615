# Project 1

This is project 1 in the course COP5615 Distributed Operating System Principles.

In this project we use the actor modeling available in Elixir to determine the perfect square of a consecutive sum of squares and then return the start of all such sequences. Additionally, we can report the Real time, CPU time and the corresponding parallelism ratio after executing the program.

Authors: **Lars Pontus Ovhagen & James Howes**

## Installation
1. Make sure to have Elixir installed and that it is correctly added to you Environment PATH variable. You should be able to run i.e. iex, mix run etc.
2. Unzip the project directory into desired location on local drive.

## Running the program
Simply run the program by opening up your command prompt and change the directory to the unzipped project `~/proj1`. Run `mix compile` to compile the program. Then start the program by using the command `mix run` with the script name `proj1.exs` as well as two numeric arguments. One for the upper-bound on the search and the other for the total length of the squared sequence. An example of how to run the program is shown below.

```sh
$ mix run proj1.exs 1000000 409
71752  
CPU time:   1624 ms  
Clock time: 203 ms  
Ratio: 8.0
```

> Please note: We have commented out the code which shows running time at the end of the output, in order to exactly match the project spec. To see the running time, uncomment these lines at the end of `proj1.exs`, and remove the underscore from the beginning of `_clock_time` and `_cpu_time` on line 18.

## Project questions

### Size of the work unit
When running locally, the size of the work distributed to individual child processes is determined by the number of active cores. Our algorithm for finding perfect square sums run in linear time and doesn't use any extra memory, so we just send one subproblem to each core on the assumption that all cores will finish in roughly the same time. This assumption is generally confirmed by the parallelism we observe, e.g. ratio of CPU time to clock time is almost 4 with four cores.

When running on a distributed cluster, we distribute work according to the relative processing power of each node. This is determined by running a short __benchmark test__ on each node during the cluster initialization. The benchmark test is run exactly as the local test above, with the number of work units equal to the number of cores on the node. This heuristic allows us to attain significant parallelism without the more complex architecture required to dynamically allocate work to nodes.

### The result of running 1000000 4
The result of running the program with *N* = 1000000 and a sequence length of *k* = 4 was that __no sequence exist for this range__. Hence, there is no perfect square for any sequence of four consecutive squares in the number space 1-1000000.

### The running time.
After executing the program with the parameters 1000000 4 we get the following on a 8 core processor:
>$ mix run proj1.exs 1000000 4  
CPU time:   248 ms  
Clock time: 31 ms  
Ratio: 8.0

### The largest problem you managed to solve.
The largest problem we managed to solve was *N* = 10,000,000,000 with a sequence length of *k* = 24:

```sh
1  
9  
20  
25  
44  
76  
121  
197  
304  
353  
540  
856  
1301  
2053  
3112  
3597  
5448  
8576  
12981  
20425  
30908  
35709  
54032  
84996  
128601  
202289  
306060  
353585  
534964  
841476  
1273121  
2002557  
3029784  
3500233  
5295700  
8329856  
12602701  
19823373  
29991872  
34648837  
52422128  
82457176  
124753981  
196231265  
296889028  
342988229  
518925672  
816241996  
1234937201  
1942489369  
2938898500  
3395233545  
5136834684  
8079962876  
CPU time:   14427160 ms  
Clock time: 449422 ms  
Ratio: 32.1015883245591
```

We achieved this result while running a cluster of our two laptops plus four AWS EC2 instances. The machines had a total of 36 cores, which is only slightly greater than the parallelism ratio recorded in the test.

## Bonus Assignment: Remote nodes
We have developed a version of the program that is capable of running on multiple remote nodes.

### Setup
Each node needs an updated version of Elixir and the project repository. On the master node (the one which will execute the script), you will need the "cookie" to allow the nodes to connect to one another. The cookie is stored in a file named .erlang.cookie in the user root directory. The default cookie value on a new installation is usually a random string of characters. Record this value.

For each remote node, determine the __public__ IP address and choose a short name such as node1, node2, etc. Then run the following command in the project root directory:

```sh
iex --name node@0.0.0.0 --cookie COOKIE -S mix
```
Replace `node` with your node's short name, `0.0.0.0` with the node's IP address, and `COOKIE` with the cookie from your master node. This will start the IEx shell with the project loaded. Then, enter the following expression to start the remote node supervisor:

```elixir
Task.Supervisor.start_link(name: Proj1.Supervisor)
```

After starting the supervisor on all __remote__ nodes, configure your __master__ node so it knows which remote nodes to connect to. Within the project configuration file `./config/config.exs` change the `nodes:` entry to list the full name of each remote node. You need only change the configuration on the __master__ node; remote nodes will not be affected.

### Executing the program
You are now ready to run the distributed program on your cluster. On the master node in the project directory, run the following command using the desired arguments for the problem size as specified:

```sh
$ mix run proj1_cluster.exs 1000000 409
```

You will see a brief status message once all nodes have been connected and benchmarked, and then the solution will be displayed once all nodes have finished their work.
