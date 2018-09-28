defmodule Proj2.IntegrationTest do
  use ExUnit.Case
  
  setup do
    start_supervised!(Proj2.NetworkManager)
	start_supervised!(Proj2.Observer)
    %{
	  tx_fn:      (fn {x, n} -> {{x, n+1}, 1} end),
	  rcv_fn:     (fn {x, n}, y -> {x+y, n} end),
	  kill_fn:    (fn {x, n} -> if n < 10, do: {:ok, {x, n}}, else: {:kill, x} end),
	  topology_fn: &Proj2.Topology.full/1
	}
  end

  test "full network with monitoring", %{tx_fn: tx_fn, rcv_fn: rcv_fn, kill_fn: kill_fn, topology_fn: topology_fn} do
    Process.flag :trap_exit, true
	Process.monitor(Proj2.Observer)
    {:ok, [node | _nodes]} = Proj2.NetworkManager.start_children((for n <- 1..10, do: {0, 0}), tx_fn, rcv_fn, kill_fn)
	:ok = Proj2.NetworkManager.set_network(topology_fn)
	:ok = Proj2.Observer.monitor_network(Proj2.NetworkManager)
	Proj2.GossipNode.transmit(node)
	receive do
	  {:DOWN, ref, :process, pid, :converged} -> assert {Proj2.Observer, _} = pid
	end
  end
end