# Read in the command line arguments.
# First argument is the number of nodes in the network.
# Second argument is the network topology to be used.
# The third argument us the algorithm; either gossip or push-sum
[numNodes, topology, algorithm] = Enum.map_every(System.argv, 1, fn(arg) -> arg end)


[numNodes, topology, algorithm] |> Enum.each(fn(arg) -> IO.puts(arg <> " ") end)



#Case match arguments
case [numNodes, topology, algorithm] do
  [nodes, "full", "gossip"] ->
    {:ok, pid} = Proj2.Supervisor.start_link([nodes |> String.to_integer, topology, algorithm])
    active_children = SupervisorHelper.map_children(pid)
    neighbors = SupervisorHelper.roll_neighbors(active_children, topology)
    Proj2.Supervisor.distributeNeighbors(neighbors)
    Proj2.Supervisor.start_simulation(Enum.random(neighbors))
   _->
    IO.puts "Arguments did not match supported topology or algorithm"
end

#Map the children
