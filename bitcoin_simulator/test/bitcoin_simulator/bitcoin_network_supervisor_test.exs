defmodule Bitcoin.NetworkSupervisorTest do
  use ExUnit.Case, async: false
  @moduledoc """
  This module defines unit tests for the Bitcoin.Node module.
  """
  
  setup do
    Bitcoin.NetworkSupervisor.start_link()
    :ok
  end
  
  test "Start a single node" do
    {:ok, node} = Bitcoin.NetworkSupervisor.start_node
    assert node in Bitcoin.NetworkSupervisor.node_list
    :ok = DynamicSupervisor.terminate_child(Bitcoin.NetworkSupervisor, node)
  end
  
  test "Start multiple nodes" do
    {:ok, nodes} = Bitcoin.NetworkSupervisor.start_nodes(5)
    Enum.each(nodes, &assert(&1 in Bitcoin.NetworkSupervisor.node_list))
    Enum.each(nodes, fn node -> :ok = DynamicSupervisor.terminate_child(Bitcoin.NetworkSupervisor, node) end)
  end
  
  test "Single node mining on a network" do
    {:ok, nodes} = Bitcoin.NetworkSupervisor.start_nodes(10)
    :ok = Bitcoin.Node.start_mining(hd(nodes))
    Process.sleep(5_000)
    Enum.each(nodes, fn node -> :ok = DynamicSupervisor.terminate_child(Bitcoin.NetworkSupervisor, node) end)
  end
  
  test "Every node mining on a network" do
    {:ok, nodes} = Bitcoin.NetworkSupervisor.start_nodes(10)
    Enum.each(nodes, &Bitcoin.Node.start_mining/1)
    Process.sleep(10_000)
    Enum.each(nodes, fn node -> :ok = DynamicSupervisor.terminate_child(Bitcoin.NetworkSupervisor, node) end)
  end
end