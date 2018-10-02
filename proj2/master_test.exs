algorithm = hd(System.argv)

{:ok, log} = File.open("results_#{algorithm}.txt", [:write, :append, :utf8])

Proj2.NetworkManager.start_link()
Proj2.Observer.start_link(self())

(for n <- 13..14, do: trunc(:math.pow(2, n)))
  |> Enum.flat_map(fn n ->
       (for t <- ["full", "3D", "rand2D", "sphere", "line", "imp2D"], do: [t, algorithm, 10])
         |> Enum.map(fn tail -> [n] ++ tail end)
	 end)
  |> Enum.reject(fn [n, t, _, _] -> (t == "rand2D" and n < 256) or (t == "line" and n > 512) or (t == "full" and n > 4096) end)
  |> Enum.map(fn [numNodes, topology, algorithm, repeat] ->
    results = Proj2.repeat_test(numNodes, topology, algorithm, repeat)
    case algorithm do
      "gossip"   ->
        msg = Enum.reduce(results, 0, fn {:ok, n}, m -> n+m end)
        IO.puts(log, "#{topology}, #{numNodes}, #{trunc(msg/repeat)}")
		IO.puts "#{topology}, #{numNodes}, #{trunc(msg/repeat)}"
      "push-sum" ->
        {msg, min, max} = Enum.reduce(results, {0, :infinity, 0}, fn {:ok, a, {b, c}}, {msg, min, max} -> {msg+a, min(min, b), max(max, c)} end)
        IO.puts(log, "#{topology}, #{numNodes}, #{trunc(msg/repeat)} messages, #{min-(numNodes+1)/2}, #{max-(numNodes+1)/2}")
		IO.puts "#{topology}, #{numNodes}, #{trunc(msg/repeat)} messages, #{min-(numNodes+1)/2}, #{max-(numNodes+1)/2}"
    end
  end)
:ok = File.close(log)