# Proj1

This is project 1 in the course COP5615 Distributed Operating System Principles.

In this project we use actor modeling to determine the perfect square of a
consecutive sum of squares and then return the start of all such sequences.

Authors: **Lars Pontus Ovhagen & James Howes**

## Installation
1. Make sure to have Elixir installed and that it is correctly added to you Environment PATH variable. You should be able to run i.e. iex, mix run etc.
2. Unzip the project directory into desired location on local drive.

## Running the program
Simply run the program by opening up your command prompt of choice. Start the program by using the command __mix run__ with the script name __proj1.exs__ as well as two numeric arguments. One for the upper-bound on the search and the other for the total length of the squared sequence. An example of how to run the program is shown below.

>$ mix run proj1.exs 40 24
Generated proj1 app
1
9
20
25
CPU time:   128 ms
Clock time: 31 ms
Ratio: 4.129032258064516

## Project questions

### Size of the work unit
The size of the work distributed to individual child processes are determined by the number of active cores. We arrived at this conclusion by...

### The result of running 1000000 4

### The running time.


### The largest problem you managed to solve.


