[space, length] = Enum.map_every(System.argv, 1, fn(arg) -> String.to_integer(arg) end)
processes = System.schedulers_online
{clock_time, {cpu_time, results}} = :timer.tc(fn ->
  (for n <- 0..processes-1, do: {round(n*space/processes + 1), round((n+1)*space/processes), length})
    |> Task.async_stream(fn {a, b, c} ->
	  :timer.tc(fn a, b, c ->
	    SqSum.square_sums(a, b, c)
          |> SqSum.find_squares(a) end,
		[a, b, c]) end,
	  timeout: 60000)
    |> Enum.reduce({0, []}, fn {:ok, {time, result}}, {cpu_time, results} ->
	  {cpu_time + time, results ++ result} end)
  end)
Enum.each(results, fn x -> IO.puts x end)
IO.puts "CPU time:   #{cpu_time |> Kernel./(1000) |> round()} ms"
IO.puts "Clock time: #{clock_time |> Kernel./(1000) |> round()} ms"