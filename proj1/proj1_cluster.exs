# Read in the command line arguments.
# First argument is size of the search space,
# second argument is the length of each sum.
[space, length] = Enum.map_every(System.argv, 1, fn(arg) -> String.to_integer(arg) end)

# Connect to remote nodes
nodes = [{:master, System.schedulers_online, Proj1.benchmark(self())}] ++ Proj1.init_cluster()

# Break the problem down based on the total number of cores available
cores = Enum.reduce(nodes, 0, fn {_node, cores, _benchmark}, acc -> acc + cores end)
chunks = Proj1.chunk_space({space, length}, max(trunc(space/10_000_000), cores))
total = Enum.reduce(nodes, 0, fn {_node, _cores, benchmark}, acc -> acc + benchmark end)

{clock_time, results} = :timer.tc(fn ->
    Enum.map_reduce(nodes, {length(chunks), cores, total}, fn {node, n_cores, benchmark}, {chunks, cores, total} ->
	    {{node, max(n_cores, min(chunks-cores+n_cores, round(chunks*benchmark/total)))},
	    {chunks - max(n_cores, min(chunks-cores+n_cores, round(chunks*benchmark/total))), cores - n_cores, total - benchmark}}
	  end)
	|> elem(0)
    |> Enum.map_reduce(nodes, 0, fn {node, n_chunks}, acc -> {{node, Enum.slice(chunks, acc..acc+n_chunks-1)}, n_chunks + acc} end)
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