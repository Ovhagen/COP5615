defmodule Proj2.ObserverTest do
  use ExUnit.Case
  
  setup do
    start_supervised(Proj2.NetworkManager)
	start_supervised(Proj2.Observer)
    %{
	  tx_fn:      (fn x -> {x, 1} end),
	  rcv_fn:     (fn x, y -> x+y end),
	  kill_fn:    (fn x -> if x >= 10, do: {:ok, x}, else: {:kill, x} end),
	  topology_fn: &Proj2.Topology.full/1
	}
  end
  
  test "establishes network monitoring", %{tx_fn: tx_fn, rcv_fn: rcv_fn, kill_fn: kill_fn} do
    Proj2.NetworkManager.start_children(10, 0, tx_fn, rcv_fn, kill_fn)
	assert Proj2.Observer.monitor_network(Proj2.NetworkManager) == :ok
  end
end