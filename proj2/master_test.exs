algorithm = hd(System.argv)

Proj2.NetworkManager.start_link()
Proj2.Observer.start_link(self())

(for n <- 3..13, do: trunc(:math.pow(2, n)))
  |> Enum.flat_map(fn n ->
       (for t <- ["full", "3D", "sphere", "imp2D"], do: [t, algorithm, 10])
         |> Enum.map(fn tail -> [n] ++ tail end)
	 end)
  |> Enum.map(fn [numNodes, topology, algorithm, repeat] ->
    results = Proj2.repeat_test(numNodes, topology, algorithm, repeat)
    case algorithm do
      "gossip"   ->
        msg = Enum.reduce(results, 0, fn {:ok, n}, m -> n+m end)
        IO.puts "#{numNodes} @ #{topology}: #{trunc(msg/repeat)} messages"
      "push-sum" ->
        {msg, min, max} = Enum.reduce(results, {0, :infinity, 0}, fn {:ok, a, {b, c}}, {msg, min, max} -> {msg+a, min(min, b), max(max, c)} end)
        IO.puts "#{numNodes} @ #{topology}: #{trunc(msg/repeat)} messages, deviation [#{min-(numNodes+1)/2}, #{max-(numNodes+1)/2}]"
    end
  end)