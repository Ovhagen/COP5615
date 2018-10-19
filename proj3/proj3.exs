[numNodes, numRequests] = Enum.map(System.argv, &String.to_integer(&1))

{:ok, _sup} = Proj3.ChordSupervisor.start_link()
{:ok, chord} = Proj3.ChordSupervisor.initialize_chord(numNodes)
:ok = Proj3.ChordSupervisor.index_assist(chord, trunc(numNodes * :math.log(numNodes)))
(for _n <- 1..numRequests, do: :rand.uniform(Proj3.ChordNode.max_id()) - 1)
  |> Enum.chunk_every(numNodes)
  |> Enum.map(&Enum.zip(chord, &1))
  |> Enum.map(fn msgs ->
       Process.sleep(1000) # One second delay between rounds
       Task.async_stream(msgs, fn {n, id} -> Proj3.ChordNode.find_successor(n, id) |> elem(2) end)
         |> Enum.reduce(0, fn {:ok, count}, sum -> sum + count end)
     end)
  |> Enum.sum()
  |> Kernel./(numRequests)
  |> IO.inspect