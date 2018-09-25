defmodule Proj2.Supervisor do
  use Supervisor

  alias Proj2.GossipWorker, as: Node

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args)
  end

  def init(args) do
    numNodes = Enum.at(args, 0)
    conv_nbr = 10

    children = generate_children(conv_nbr, numNodes, self())
    Supervisor.init(children, strategy: :one_for_one)
    #Supervisor.count_children(pid)
  end

  # Helper functions
  def generate_children(limit, numNodes, sup_pid) do
    Enum.map(1..numNodes, fn(nbr) ->
      Supervisor.child_spec({Node, [limit, 0, [], sup_pid]}, id: {Node, nbr})
    end)
  end

  #Distribute the the neighbors to the active children
  def distributeNeighbors(neighbor_tuples) do
    IO.puts "Supervisor: Distributing neighbors..."
    neighbor_tuples
    |> Enum.each(fn {child_pid, nodes} -> GenServer.cast(child_pid, {:setneighbors, nodes}) end)
  end


  def start_simulation(child_tuple, nbr_of_children) do
    GenServer.call(elem(child_tuple, 0), :start)
    check_convergence(nil, nbr_of_children)
  end

  def check_convergence(child_pid, not_finished) when not_finished <= 1 do
    IO.puts "#{inspect(self())}: Shutting down last child with pid #{inspect(child_pid)}"
    Supervisor.terminate_child(self(), child_pid)
  end

  def check_convergence(child_pid, not_finished) do
    receive do
      {:finished, child_pid} -> Supervisor.terminate_child(self(), child_pid)
    end
    IO.puts "#{inspect(self())}: Shut down child with pid #{inspect(child_pid)}"
    check_convergence(child_pid, not_finished-1)
  end

end
