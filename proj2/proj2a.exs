numNodes = String.to_integer(hd(System.argv))

IO.puts "Starting network manager and observer..."
Process.flag :trap_exit, true
Proj2.NetworkManager.start_link()
Proj2.Observer.start_link([])

IO.puts "Starting #{numNodes} gossip nodes..."
{:ok, [node | _nodes]} = Proj2.NetworkManager.start_children(
                           (for _n <- 1..numNodes, do: {[], 0}),
						   &Proj2.Messenger.tx_fn/1,
						   &Proj2.Messenger.rcv_fn/2,
						   &Proj2.Messenger.kill_fn/1)

IO.puts "Setting network topology..."
:ok = Proj2.Observer.monitor_network(Proj2.NetworkManager)
:ok = Proj2.NetworkManager.set_network(&Proj2.Topology.full/1)

IO.puts "Starting gossip..."
{time, _} = :timer.tc(fn ->
  Proj2.GossipNode.gossip(node, [:hello])
  receive do
    {:EXIT, _from, :normal} -> IO.puts "Network has achieved convergence."
  end
end)

IO.puts "Network achieved convergence in #{trunc(time/1000)}ms"