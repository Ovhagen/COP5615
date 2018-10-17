{numNodes, numRequests} = {String.to_integer(hd(System.argv)), Enum.at(System.argv, 1)}

#Process.flag :trap_exit, true
Proj3.ChordSupervisor.start_link([])
Proj3.ChordObserver.start_link([self(), numRequests |> String.to_integer()])

Proj3.ChordSupervisor.initialize_chord(numNodes)

:ok = Proj3.ChordObserver.monitor_network(Proj3.ChordSupervisor)

#Proj3.
