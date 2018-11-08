# [numNodes, numRequests] = Enum.map(System.argv, &String.to_integer(&1))
#
# {:ok, _sup} = Proj3.ChordSupervisor.start_link()
# {:ok, chord} = Proj3.Chord.initialize_chord(numNodes)
# :ok = Proj3.Chord.index_assist(chord, trunc(numNodes * :math.log(numNodes)))
