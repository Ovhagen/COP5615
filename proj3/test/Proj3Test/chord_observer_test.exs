defmodule Proj3.ObserverTest do
  use ExUnit.Case

  setup do
    start_supervised!(Proj3.ChordSupervisor)
	start_supervised!(Proj2.ChordObserver)
    %{

	}
  end

  test "establishes network monitoring", %{tx_fn: tx_fn, rcv_fn: rcv_fn, mode_fn: mode_fn} do
    Proj2.NetworkManager.start_children(List.duplicate(0, 1000), tx_fn, rcv_fn, mode_fn)
	assert Proj2.Observer.monitor_network(Proj2.NetworkManager) == :ok
  end
end
