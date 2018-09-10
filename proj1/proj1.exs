# Read in the command line arguments.
# First argument is size of the search space,
# second argument is the length of each sum.
[space, length] = Enum.map_every(System.argv, 1, fn(arg) -> String.to_integer(arg) end)

# Connect to remote nodes
Enum.map(Application.get_env(:proj1, :nodes), fn node -> Node.connect(node) end)

# Determine how many chunks to break the total search space into.
# At a minimum, use the number of cores available.
# If the search space is large then cap each chunk to avoid running out of memory.
chunks = System.schedulers_online

# Perform all calculations and gather the results.
# 1. Wrap everything in a timer to keep track of clock time.
# 2. Divide the search space into equal chunks based on the number of available cores.
# 3. Send each chunk to a separate process, wrapped in a timer to keep track of CPU time.
# 4. Find all perfect square sums within the chunk using a linear time algorithm
# 5. Add up all of the CPU times returned by each process, and concatenate all of the results into a single list.
{clock_time, {cpu_time, results}} = :timer.tc(fn ->
  (for n <- 0..chunks-1, do: {round(n*space/chunks + 1), round((n+1)*space/chunks), length})
    |> Proj1.calc_with_timer()
  end)

# Print each result on a separate line, then print the elapsed CPU time and clock time.
Enum.each(results, fn x -> IO.puts x end)
IO.puts "CPU time:   #{cpu_time |> Kernel./(1000) |> round()} ms"
IO.puts "Clock time: #{clock_time |> Kernel./(1000) |> round()} ms"
if clock_time == 0 do
  IO.puts "Ratio: #{0}"
else
  IO.puts "Ratio: #{cpu_time/clock_time}"
end