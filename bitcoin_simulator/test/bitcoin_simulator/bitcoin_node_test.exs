defmodule Bitcoin.NodeTest do
  use ExUnit.Case, async: false
  @moduledoc """
  This module defines unit tests for the Bitcoin.Node module.
  """
  
  setup do
    init = %Bitcoin.Node{
      chain:     Blocktree.genesis,
      neighbors: [],
      mining:    false
    }
    nodes = Stream.repeatedly(fn -> Bitcoin.Wallet.start_link |> elem(1) end)
      |> Enum.take(5)
      |> Enum.map(fn pid -> Map.put(init, :wallet, pid) |> Bitcoin.Node.start_link |> elem(1) end)
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
      {:"$gen_cast", {:relay_block, raw_header, pid}} ->
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
      {:"$gen_cast", {:relay_block, raw_header, pid}} ->
        assert pid == List.last(data.nodes)
        header = Block.Header.deserialize(raw_header)
        assert header.previous_hash == data.init.chain.mainchain.tip.hash
    after
      5000 -> assert false
    end
  end
  
  test "Relay a transaction across multiple nodes", data do
    {pubkey, privkey} = KeyAddress.keypair(1337)
    vout = Stream.repeatedly(fn -> Transaction.Vout.new(99_500_000, :crypto.strong_rand_bytes(20)) end)
      |> Enum.take(10)
    tx = Transaction.new(
      [Transaction.Vin.new(
          Block.transactions(data.init.chain.mainchain.tip.block) |> hd |> Transaction.hash,
          0
        )],
      vout
    )
    |> Transaction.sign(pubkey, privkey)
    
    Enum.zip(data.nodes, tl(data.nodes) ++ [self()])
    |> Enum.each(fn {node, neighbor} -> Bitcoin.Node.add_neighbor(node, neighbor) end)
    :ok = Bitcoin.Node.verify_tx(hd(data.nodes), tx)
    receive do
      {:"$gen_cast", {:relay_tx, raw_tx}} ->
        assert tx = Transaction.deserialize(raw_tx)
    after
      5000 -> assert false
    end
  end
end