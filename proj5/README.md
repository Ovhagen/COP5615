# Proj5
A project in the course Distributed Operating System Principles COP5615. This project is a continuation of Project 4 and mainly involve additional implementation to run a larger simulation with the Bitcoin protocol. Especially, we focus on implementing compatibility for various scenarios in the protocol, with respect to miners and wallets, to ensure correctness compared to the original whitepaper. These additional scenarios can be tested with new independent unit tests with mix, and include functionality tests for e.g. fork functionality for miners and nodes. The second part of the project was to visualize the simulation with different statistics, taken from the simulation in realtime. To accomplish this we utilize the web framework Phoenix in Elixir to dynamically update charts with statistical samples taken from the live simulation.


### Authors
* James Howes (UFID 9262-9312)
* Lars Pontus Ovhagen (UFID 2992-9498)

## Installation
Download the project zip to your desired location and unzip it. Make sure you have Elixir/Erlang installed on your computer and that the OS path includes the elixir prompt for easy command access.

## Phoenix Setup

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create your database with `mix ecto.create`
  * Install Node.js dependencies with `cd assets && npm install`
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

In the application you can see various statistics and metrics collected from a live simulation of the bitcoin protocol.

### Learn more

  * Official website: http://www.phoenixframework.org/
  * Guides: http://phoenixframework.org/docs/overview
  * Docs: https://hexdocs.pm/phoenix
  * Mailing list: http://groups.google.com/group/phoenix-talk
  * Source: https://github.com/phoenixframework/phoenix

## Bitcoin Tests
Since this project was built on a previous project, additional features were added to fully implement the distributed Bitcoin protocol.
