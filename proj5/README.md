# Proj5
A project in the course Distributed Operating System Principles COP5615. This project is a continuation of Project 4 and mainly involves additional implementation to run a larger simulation with the Bitcoin protocol. Especially, we focus on implementing compatibility for various scenarios in the protocol, with respect to miners and wallets, to emphasize correctness with the original whitepaper. These additional scenarios can be tested with new independent unit tests with mix, and include functionality tests for e.g. handling the presence of fork in the blockchain for miners and regular nodes. The second part of the project was to visualize the simulation with different statistics, taken from the simulation in realtime. To accomplish this we utilize the web framework Phoenix in Elixir to dynamically update charts with statistical samples taken from the live simulation.


### Authors
* James Howes (UFID 9262-9312)
* Lars Pontus Ovhagen (UFID 2992-9498)

## Installation
Download the project zip to your desired location and unzip it. Make sure you have Elixir/Erlang installed on your computer and that the OS path includes the elixir prompt for easy command access.

## Phoenix Setup

To start your Phoenix server:

  * Install dependencies with `mix deps.get`.
  * Make sure to install PostgreSQL. Choose link depending on OS. [`PostgreSQL Website`](https://www.postgresql.org/download/)
  * Create your database with `mix ecto.create`.
  * Install Node.js dependencies with `cd assets && npm install`.
  * Go to project root folder. Start Phoenix endpoint with `mix phx.server`.

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

In the application you can see various statistics and metrics collected from a live simulation of the bitcoin protocol.

## Bitcoin Tests
Since this project was built on a previous project, additional features were added to fully implement the distributed Bitcoin protocol.
Our new unit tests include ....
You can run them individually by .....

## Network observations
* Graph1
* Graph2
* Graph3
...

## Scenarios

#### Forks
* Handle branches and drop them dynamically as the chain progresses.

#### Transactions
* Transaction exclusion (low fee, still guaranteed to be included? how long does it take?)
* Wallet displaying balance after certain amount of confirmations

#### ....
