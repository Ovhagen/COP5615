[space, length] = Enum.map_every(System.argv, 1, fn(arg) -> String.to_integer(arg) end)
processes = System.schedulers_online
time = :timer.tc( fn ->
  (for n <- 0..processes-1, do: {round(n*space/processes + 1), round((n+1)*space/processes), length})
    |> Task.async_stream(fn {a, b, c} ->
	  SqSum.square_sums(a, b, c)
        |> SqSum.find_squares(a) end, timeout: 60000)
    |> Enum.reduce([], fn {:ok, x}, acc -> acc ++ x end)
    |> Enum.each(fn x -> IO.puts x end)
  end)
  |> elem(0)
  |> Kernel./(1_000)
  |> round()
IO.puts "Running time: #{time} ms"