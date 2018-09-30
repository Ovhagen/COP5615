{numNodes, [topology]} = {String.to_integer(hd(System.argv)), tl(System.argv)}

IO.puts "Starting network manager and observer..."
Process.flag :trap_exit, true
Proj2.NetworkManager.start_link()
Proj2.Observer.start_link()

IO.puts "Starting #{numNodes} gossip nodes..."
{:ok, [node | _nodes]} = Proj2.NetworkManager.start_children(Proj2.Messenger, List.duplicate([], numNodes))
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
  Proj2.GossipNode.gossip(node, [:hello])
  receive do
    {:EXIT, _from, :normal} -> IO.puts "Network has achieved convergence."
  end
end)

IO.puts "Network achieved convergence in #{trunc(time/1000)}ms"