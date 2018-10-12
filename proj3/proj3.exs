{numNodes, requests} = {String.to_integer(hd(System.argv)), Enum.at(System.argv, 1)}

#Process.flag :trap_exit, true
Proj3.ChordSupervisor.start_link()

{:ok, nodes} = Proj3.ChordSupervisor.initialize_chord(numNodes)

#Proj3.
