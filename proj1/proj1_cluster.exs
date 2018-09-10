# Read in the command line arguments.
# First argument is size of the search space,
# second argument is the length of each sum.
[space, length] = Enum.map_every(System.argv, 1, fn(arg) -> String.to_integer(arg) end)

# Connect to remote nodes and benchmark all nodes
pid = self()
Proj1.benchmark(pid)
nodes = [{:master, System.schedulers_online, (receive do {^pid, benchmark} -> benchmark end)}] ++ Proj1.init_cluster()

# Perform all calculations and gather the results.
# 1. Wrap everything in a timer to keep track of clock time.
# 2. Divide the search space into chunks and allocate work to each node based on its relative benchmark performance
# 3. Send the work to each node, using Supervisors for remote nodes
# 4. Compile the results into a single list
to = Application.get_env(:proj1, :timeout)
{clock_time, results} = :timer.tc(fn ->
  nodes
    |> Proj1.assign_chunks(space, length)
    |> Task.async_stream(fn
        {:master, chunks} -> Task.async_stream(chunks, SqSum, :square_sums, [], timeout: to)
        {node, chunks}    -> Task.Supervisor.async_stream({Proj1.Supervisor, node}, chunks, SqSum, :square_sums, [], timeout: to)
      end, timeout: to)
    |> Enum.reduce([], fn {:ok, results}, acc ->
        acc ++ Enum.reduce(results, [], fn {:ok, result}, acc ->
  	      acc ++ result
        end)
	  end)
end)

# Output each result on a separate line, then output the total running time
Enum.each(results, fn x -> IO.puts x end)
IO.puts "Run time: #{clock_time |> Kernel./(1000) |> round()} ms"