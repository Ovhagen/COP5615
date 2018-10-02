defmodule Proj2 do
  @moduledoc """
  This module contains functions to support project specifications and batch processing.
  """

  @doc """
  Run a test gossip, and return the result
  """
  def test_run(nodes, topology, "gossip") do
    :ok = Proj2.NetworkManager.set_network(
      case topology do
        "full"   -> &Proj2.Topology.full/1
        "3D"     -> &(Proj2.Topology.grid(&1, 3))
        "rand2D" -> &(Proj2.Topology.proximity(&1, 2, 0.1))
        "sphere" -> &(Proj2.Topology.grid(&1, 2, :true))
        "line"   -> &(Proj2.Topology.grid(&1, 1))
        "imp2D"  -> &(Proj2.Topology.grid(&1, 1, :false, :true))
      end)
    Proj2.GossipNode.gossip(Enum.random(nodes), [:hello])
	receive do
      {:converged, _data, sent} -> {:ok, sent}
      :timeout -> :timeout
    end
  end
  
  def test_run(nodes, topology, "push-sum") do
    :ok = Proj2.NetworkManager.set_network(
      case topology do
        "full"   -> &Proj2.Topology.full/1
        "3D"     -> &(Proj2.Topology.grid(&1, 3))
        "rand2D" -> &(Proj2.Topology.proximity(&1, 2, 0.1))
        "sphere" -> &(Proj2.Topology.grid(&1, 2, :true))
        "line"   -> &(Proj2.Topology.grid(&1, 1))
        "imp2D"  -> &(Proj2.Topology.grid(&1, 1, :false, :true))
      end)
    Proj2.GossipNode.transmit(Enum.random(nodes))
	receive do
      {:converged, data, sent} ->
	    {:ok, sent, Enum.reduce(data, {:infinity, 0}, fn {_, _, r, _}, {min, max} -> {min(r, min), max(r, max)} end)}
      :timeout -> :timeout
    end
  end
  
  @doc """
  Run multiple tests and return the aggregated results.
  """
  def repeat_test(numNodes, topology, algorithm, n), do: repeat_test(numNodes, topology, algorithm, n, [])
  
  def repeat_test(_numNodes, _topology, _algorithm, n, results) when n == 0, do: results
  
  def repeat_test(numNodes, topology, algorithm, n, results) do
    :ok = Proj2.NetworkManager.kill_children()
    {:ok, nodes} =
      case algorithm do
        "gossip"   -> Proj2.NetworkManager.start_children(Proj2.Messenger, List.duplicate([], numNodes))
        "push-sum" -> Proj2.NetworkManager.start_children(Proj2.PushSum, (for n <- 1..numNodes, do: [n]))
      end
    :ok = Proj2.Observer.monitor_network(Proj2.NetworkManager)
	case test_run(nodes, topology, algorithm) do
      :timeout ->
	    IO.puts "Test timed out, retrying..."
	    repeat_test(numNodes, topology, algorithm, n, results)
	  result   ->
	    repeat_test(numNodes, topology, algorithm, n-1, [result] ++ results)
	end
  end
end
