defmodule Bitcoin.NodeTest do
  use ExUnit.Case
  @moduledoc """
  This module defines unit tests for the Bitcoin.Node module.
  """
  
  setup do
    init = %Bitcoin.Node{
      chain:     Blocktree.genesis,
      neighbors: [],
      mining:    false
    }
    nodes =
      Stream.repeatedly(fn -> Bitcoin.Node.start_link(init) |> elem(1) end)
      |> Enum.take(5)
    %{
      init:  init,
      nodes: nodes
    }
  end
  
  test "Start a solo node and mine a block", data do
    node = hd(data.nodes)
    :ok = Bitcoin.Node.add_neighbor(node, self())
    :ok = Bitcoin.Node.start_mining(node)
    receive do
      {:"$gen_call", {pid, _ref}, {:block_header, raw_header}} ->
        assert pid == node
        header = Block.Header.deserialize(raw_header)
        assert header.previous_hash == data.init.chain.mainchain.tip.hash
    after
      1000 -> assert false
    end
  end
  
  test "Relay a block across multiple nodes", data do
    Enum.zip(data.nodes, tl(data.nodes) ++ [self()])
    |> Enum.each(fn {node, neighbor} -> Bitcoin.Node.add_neighbor(node, neighbor) end)
    :ok = Bitcoin.Node.start_mining(hd(data.nodes))
    receive do
      {:"$gen_call", {pid, _ref}, {:block_header, raw_header}} ->
        assert pid == List.last(data.nodes)
        header = Block.Header.deserialize(raw_header)
        assert header.previous_hash == data.init.chain.mainchain.tip.hash
    after
      5000 -> assert false
    end
  end
end