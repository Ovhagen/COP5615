{numNodes, topology, algorithm, repeat} = {String.to_integer(hd(System.argv)), Enum.at(System.argv, 1), Enum.at(System.argv, 2), String.to_integer(Enum.at(System.argv, 3))}

Proj2.NetworkManager.start_link()
Proj2.Observer.start_link(self())

results = Proj2.repeat_test(numNodes, topology, algorithm, repeat)

case algorithm do
  "gossip"   ->
    msg = Enum.reduce(results, 0, fn {:ok, n}, m -> n+m end)
    IO.puts "Converged after an average of #{trunc(msg/repeat)} messages"
  "push-sum" ->
    {msg, min, max} = Enum.reduce(results, {0, :infinity, 0}, fn {:ok, a, {b, c}}, {msg, min, max} -> {msg+a, min(min, b), max(max, c)} end)
    IO.puts "Converged after an average of #{trunc(msg/repeat)} messages"
	IO.puts "Min value: #{min}"
	IO.puts "Max value: #{max}"
end