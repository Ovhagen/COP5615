# Read in the command line arguments.
# First argument is size of the search space,
# second argument is the length of each sum.
[space, length] = Enum.map_every(System.argv, 1, fn(arg) -> String.to_integer(arg) end)

# Connect to remote nodes
nodes = [master: System.schedulers_online] ++ Proj1.init_cluster()

# Break the problem down based on the total number of cores available
num_subproblems = Enum.reduce(nodes, 0, fn {node, cores}, acc -> acc + cores end)
subproblems = (for n <- 0..num_subproblems-1, do: {round(n*space/num_subproblems + 1), round((n+1)*space/num_subproblems), length})

{clock_time, results} = :timer.tc(fn ->
    Enum.map_reduce(nodes, 0, fn {node, cores}, acc -> {{node, Enum.slice(subproblems, acc..acc+cores-1)}, cores + acc} end)
    |> elem(0)
    |> Task.async_stream(fn
        {:master, chunk} -> Task.async_stream(chunk, SqSum, :square_sums, [], timeout: 600000)
        {node, chunk}    -> Task.Supervisor.async_stream({Proj1.Supervisor, node}, chunk, SqSum, :square_sums, [], timeout: 600000)
      end, timeout: 600000)
    |> Enum.reduce([], fn {:ok, results}, acc ->
        acc ++ Enum.reduce(results, [], fn {:ok, result}, acc ->
  	      acc ++ result
        end)
	  end)
  end)
 
Enum.each(results, fn x -> IO.puts x end)
IO.puts "Run time: #{clock_time |> Kernel./(1000) |> round()} ms"