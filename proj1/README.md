# Project 1

This is project 1 in the course COP5615 Distributed Operating System Principles.

In this project we use the actor modeling available in Elixir to determine the perfect square of a
consecutive sum of squares and then return the start of all such sequences. Additionally, we report the Real time, CPU time and the corresponding ratio (CPU usage) of these after executing the program.

Authors: **Lars Pontus Ovhagen & James Howes**

## Installation
1. Make sure to have Elixir installed and that it is correctly added to you Environment PATH variable. You should be able to run i.e. iex, mix run etc.
2. Unzip the project directory into desired location on local drive.

## Running the program
Simply run the program by opening up your command prompt and change the directory to the unzipped project *~/proj1*. Run *mix compile* to compile the program. Then start the program by using the command *mix run* with the script name *proj1.exs* as well as two numeric arguments. One for the upper-bound on the search and the other for the total length of the squared sequence. An example of how to run the program is shown below.

>$ mix run proj1.exs 1000000 409

>71752

>CPU time:   1624 ms

>Clock time: 203 ms

>Ratio: 8.0

## Project questions

### Size of the work unit
The size of the work distributed to individual child processes are determined by the number of active cores.
Our algorithm for finding perfect square sums run in linear time and doesn't use any extra memory, so we just send
one subproblem to each core on the assumption that all cores will finish in roughly the same time. This assumption
is generally confirmed by the parallelism we observe, e.g. ratio of CPU time to clock time is almost 4 with four cores.

### The result of running 1000000 4
The result of running the program with *N* = 1000000 and a sequence length of *k* = 4 was that __no sequence exist for this range__. Hence, there is no perfect square for any sequence of four consecutive squares in the number space 1-1000000.

### The running time.
After executing the program with the parameters 1000000 4 we get the following on a 8 core processor:
>CPU time:   248 ms

>Clock time: 31 ms

>Ratio: 8.0

### The largest problem you managed to solve.
The largest problem we managed to solve was 