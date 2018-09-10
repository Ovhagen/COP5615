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
{clock_time, {cpu_time, results}} = :timer.tc(fn ->
  nodes
    |> Proj1.assign_chunks(space, length)
    |> Enum.map(fn
	    {:master, chunks} -> Task.async(Proj1, :calc_with_timer, [chunks])
	    {node, chunks}    -> Task.Supervisor.async({Proj1.Supervisor, node}, Proj1, :calc_with_timer, [chunks])
	  end)
    |> Enum.reduce({0, []}, fn pid, {total_time, results} ->
	    {cpu_time, result} = await(pid, Application.get_env(:proj1, :timeout))
        {total_time + cpu_time, results ++ result}
      end)
end)

# Output each result on a separate line, then output the total running time
Enum.each(results, fn x -> IO.puts x end)
IO.puts "CPU time:   #{cpu_time |> Kernel./(1000) |> round()} ms"
IO.puts "Clock time: #{clock_time |> Kernel./(1000) |> round()} ms"
if clock_time == 0 do
  IO.puts "Ratio: #{0}"
else
  IO.puts "Ratio: #{cpu_time/clock_time}"
end