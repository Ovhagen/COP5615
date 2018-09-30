defmodule Proj2.NetworkManagerTest do
  use ExUnit.Case
  
  setup do
    start_supervised!(Proj2.NetworkManager)
    %{
	  tx_fn:      (fn x -> {x, 1} end),
	  rcv_fn:     (fn x, y -> x+y end),
	  mode_fn:    (fn x -> if x < 10, do: {:ok, x}, else: {:kill, x} end),
	  topology_fn: &Proj2.Topology.full/1
	}
  end

  test "starts and kills children", %{tx_fn: tx_fn, rcv_fn: rcv_fn, mode_fn: mode_fn} do
    {:ok, pid} = Proj2.NetworkManager.start_child(0, tx_fn, rcv_fn, mode_fn)
	assert Map.get(DynamicSupervisor.count_children(Proj2.NetworkManager), :active) == 1
	Proj2.NetworkManager.start_children((for _n <- 1..10, do: 0), tx_fn, rcv_fn, mode_fn)
	assert Map.get(DynamicSupervisor.count_children(Proj2.NetworkManager), :active) == 11
	DynamicSupervisor.terminate_child(Proj2.NetworkManager, pid)
	assert Map.get(DynamicSupervisor.count_children(Proj2.NetworkManager), :active) == 10
  end
  
  test "sets up network", %{tx_fn: tx_fn, rcv_fn: rcv_fn, mode_fn: mode_fn, topology_fn: topology_fn} do
    {:ok, [node1 | nodes]} = Proj2.NetworkManager.start_children(List.duplicate(0, 1000), tx_fn, rcv_fn, mode_fn)
	assert Proj2.NetworkManager.set_network(topology_fn) == :ok
	Proj2.GossipNode.get(node1, :neighbors)
	  |> Enum.each(fn node -> assert node in nodes end)
  end
end