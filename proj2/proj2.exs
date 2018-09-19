# Read in the command line arguments.
# First argument is the number of nodes in the network.
# Second argument is the network topology to be used.
# The third argument us the algorithm; either gossip or push-sum
[numNodes, topology, algorithm] = Enum.map_every(System.argv, 1, fn(arg) -> arg end)


[numNodes, topology, algorithm] |> Enum.each(fn(arg) -> IO.puts(arg <> " ") end)



#Case match arguments
case [numNodes, topology, algorithm] do

  #Maps the number of active children and roll neighbors to each one of them.
  #Sends this to the supervisor to update the nodes and the start the simulation.
  [nodes, "full", "gossip"] ->
    {:ok, pid} = Proj2.Supervisor.start_link([nodes |> String.to_integer, topology, algorithm])
    active_children = UtilityFunctions.map_children(pid)
    neighbors = UtilityFunctions.roll_neighbors(active_children, topology)
    Proj2.Supervisor.distributeNeighbors(neighbors)
    Proj2.Supervisor.start_simulation(Enum.random(neighbors), length(active_children))

   _->
    IO.puts "Arguments did not match supported topology or algorithm"
end
