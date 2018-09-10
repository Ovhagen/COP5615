# Proj1

This is project 1 in the course COP5615 Distributed Operating System Principles.

In this project we use the actor modeling available in Elixir to determine the perfect square of a
consecutive sum of squares and then return the start of all such sequences. Additionally, we report the Real time, CPU time and the corresponding ratio (CPU usage) of these after executing the program.

Authors: **Lars Pontus Ovhagen & James Howes**

## Installation
1. Make sure to have Elixir installed and that it is correctly added to you Environment PATH variable. You should be able to run i.e. iex, mix run etc.
2. Unzip the project directory into desired location on local drive.

## Running the program
Simply run the program by opening up your command prompt of choice. Run *mix compile* to compile the program. Then start the program by using the command *mix run* with the script name *proj1.exs* as well as two numeric arguments. One for the upper-bound on the search and the other for the total length of the squared sequence. An example of how to run the program is shown below.

>$ mix run proj1.exs 40 24

>71752

>CPU time:   1760 ms

>Clock time: 234 ms

>Ratio: 7.521367521367521

## Project questions

### Size of the work unit
The size of the work distributed to individual child processes are determined by the number of active cores. We arrived at this conclusion by...

### The result of running 1000000 4
The result of running the program with *N* = 1000000 and a sequence length of *k* = 4 was that __no sequence exist for this range__. Hence, there is no perfect square for any sequence of four consecutive squares in the number space 1-1000000.

### The running time.
After executing the program with the parameters 1000000 4 we get a running time of __Something good...__

### The largest problem you managed to solve.
The largest problem we managed to solve was 

