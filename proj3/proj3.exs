[numNodes, numRequests] = Enum.map(System.argv, &String.to_integer(&1))

{:ok, _sup} = Proj3.ChordSupervisor.start_link()
{:ok, chord} = Proj3.Chord.initialize_chord(numNodes)
:ok = Proj3.Chord.index_assist(chord, trunc(numNodes * :math.log(numNodes)))
# Allow time for finger tables to index further
:math.log10(numNodes)
  |> Kernel.*(Proj3.ChordNode.env(:delay)[:ff])
  |> trunc()
  |> Process.sleep()

# Send one request per second to every node each second until all requests are sent.
(for _n <- 1..numRequests*numNodes, do: :rand.uniform(Proj3.ChordNode.max_id()) - 1)
  |> Enum.chunk_every(numRequests)
  |> Enum.zip(chord)
  |> Task.async_stream(fn {ids, n} ->
         Enum.reduce(ids, 0, fn id, sum ->
           Process.sleep(1000) # One second delay between rounds
           Proj3.ChordNode.find_successor(n, id) |> elem(2) |> Kernel.+(sum)
         end)
       end,
       max_concurrency: numNodes,
       ordered: false,
       timeout: :infinity)
  |> Enum.unzip()
  |> elem(1)
  |> Enum.sum()
  |> Kernel./(numRequests*numNodes)
  |> IO.inspect