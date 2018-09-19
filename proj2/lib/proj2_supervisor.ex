defmodule Proj2.Supervisor do
  use Supervisor

  alias Proj2.GossipWorker, as: Node

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args)
  end

  def init(args) do
    numNodes = Enum.at(args, 0)
    conv_nbr = 10

    children = generate_children(conv_nbr, numNodes)
    Supervisor.init(children, strategy: :one_for_one)
    #Supervisor.count_children(pid)
  end

  # Helper functions
  def generate_children(limit, numNodes) do
    Enum.map(1..numNodes, fn(nbr) ->
      Supervisor.child_spec({Proj2.GossipWorker, [limit, 0, []]}, id: nbr)
    end)
  end

  #Distribute the the neighbors to the active children
  def distributeNeighbors(neighbor_tuples) do
    IO.puts "Supervisor: Distributing neighbors..."
    neighbor_tuples
    |> Enum.each(fn {child_pid, nodes} -> GenServer.cast(child_pid, {:setneighbors, nodes}) end)
  end

  def start_simulation(child_tuple) do
    GenServer.call(elem(child_tuple, 0), :start)
  end

end
