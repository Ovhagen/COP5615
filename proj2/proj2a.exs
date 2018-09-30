{numNodes, topology, algorithm} = {String.to_integer(hd(System.argv)), Enum.at(System.argv, 1), Enum.at(System.argv, 2)}

IO.puts "Starting network manager and observer..."
Process.flag :trap_exit, true
Proj2.NetworkManager.start_link()
Proj2.Observer.start_link()

IO.puts "Starting #{numNodes} gossip nodes..."
{:ok, [node | _nodes]} =
  case algorithm do
    "gossip"   -> Proj2.NetworkManager.start_children(Proj2.Messenger, List.duplicate([], numNodes))
	"push-sum" -> Proj2.NetworkManager.start_children(Proj2.PushSum, (for n <- 1..numNodes, do: [n]))
  end
:ok = Proj2.Observer.monitor_network(Proj2.NetworkManager)

IO.puts "Setting network topology..."
:ok = Proj2.NetworkManager.set_network(
  case topology do
    "full"   -> &Proj2.Topology.full/1
    "3D"     -> &(Proj2.Topology.grid(&1, 3))
    "rand2D" -> &(Proj2.Topology.proximity(&1, 2, 0.1))
    "sphere" -> &(Proj2.Topology.grid(&1, 2, :true))
    "line"   -> &(Proj2.Topology.grid(&1, 1))
    "imp2D"  -> &(Proj2.Topology.grid(&1, 1, :false, :true))
  end)

IO.puts "Starting gossip..."
{time, _} = :timer.tc(fn ->
  case algorithm do
    "gossip"   -> Proj2.GossipNode.gossip(node, [:hello])
	"push-sum" -> Proj2.GossipNode.transmit(node)
  end
  receive do
    {:EXIT, _from, :normal} -> IO.puts "Network has achieved convergence."
  end
end)

IO.puts "Network achieved convergence in #{trunc(time/1000)}ms"