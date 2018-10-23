{n, failure_rate} = {String.to_integer(hd(System.argv)), String.to_float(hd(tl(System.argv)))}

{:ok, _sup} = Proj3.ChordSupervisor.start_link()
{:ok, chord} = Proj3.Chord.initialize_chord(n)
:ok = Proj3.Chord.index_assist(chord, trunc(2 * n * :math.log(n)))

# Allow time for finger tables to index further
:math.log10(n)
  |> Kernel.*(Proj3.ChordNode.env(:delay)[:ff])
  |> trunc()
  |> Process.sleep()

kv = Proj3.Chord.seed_keys(chord, 20)

Enum.take_random(tl(chord), trunc(n * failure_rate))
  |> Enum.each(&Proj3.ChordNode.failure(&1))
# Wait for failed nodes to get removed from successor positions
:math.log10(n)
  |> Kernel.*(5 * Proj3.ChordNode.env(:delay)[:ff])
  |> trunc()
  |> Process.sleep()

IO.write "Data loss: "
Map.keys(kv)
  |> Enum.reduce(0, fn key, x -> x + if(Proj3.ChordNode.get(hd(chord), key) == nil, do: 1, else: 0) end)
  |> Kernel./(n * 20)
  |> IO.inspect