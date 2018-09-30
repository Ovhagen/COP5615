defmodule Proj2.IntegrationTest do
  use ExUnit.Case
  
  setup do
    start_supervised!(Proj2.NetworkManager)
	start_supervised!(Proj2.Observer)
    %{
	  tx_fn:       &Proj2.Messenger.tx_fn/1,
	  rcv_fn:      &Proj2.Messenger.rcv_fn/2,
	  mode_fn:     &Proj2.Messenger.mode_fn/1,
	  topology_fn: &Proj2.Topology.full/1
	}
  end

  test "full network with monitoring", %{tx_fn: tx_fn, rcv_fn: rcv_fn, mode_fn: mode_fn, topology_fn: topology_fn} do
    Process.flag :trap_exit, true
	Process.monitor(Proj2.Observer)
    {:ok, [node | _nodes]} = Proj2.NetworkManager.start_children(List.duplicate({[], 0}, 1000), tx_fn, rcv_fn, mode_fn)
	:ok = Proj2.NetworkManager.set_network(topology_fn)
	:ok = Proj2.Observer.monitor_network(Proj2.NetworkManager)
	Proj2.GossipNode.gossip(node, [:hello])
	receive do
	  {:DOWN, _ref, :process, pid, :converged} -> assert {Proj2.Observer, _} = pid
	end
  end
end