defmodule Proj4.BlocktreeTest do
  use ExUnit.Case
  @moduledoc """
  This module defines unit tests for the Blocktree module.
  """

  def blockstream(bc, msg) do
    Stream.unfold(bc, fn bc ->
      block = Miner.mine_block(bc, bc.mempool, :crypto.strong_rand_bytes(32), msg)
      {
        block,
        Blockchain.add_block(bc, block) |> elem(1)
      }
    end)
  end
  
  setup do
    bt = Blocktree.genesis
    %{
      bt:     bt,
      chain1: blockstream(bt.mainchain, "test1"),
      chain2: blockstream(bt.mainchain, "test2"),
      chain3: blockstream(bt.mainchain, "test3")
    }
  end
  
  @doc """
  This test verifies that forks are properly tracked and the mainchain is updated correctly.
  """
  test "Update mainchain", data do
    chain1 = Stream.take(data.chain1, 3) |> Enum.to_list
    bt = Blocktree.add_block(data.bt, hd(chain1))
    assert Blocktree.forked?(bt) == false
    assert bt.mainchain.tip.block == hd(chain1)
    
    chain2 = Stream.take(data.chain2, 3) |> Enum.to_list
    chain3 = Stream.take(data.chain3, 3) |> Enum.to_list
    bt = Blocktree.add_block(bt, hd(chain2))
    bt = Blocktree.add_block(bt, hd(chain3))
    assert length(bt.forks) == 3
    assert bt.mainchain.tip.block == hd(chain1)
    
    bt = Blocktree.add_block(bt, Enum.at(chain2, 1))
    assert bt.mainchain.tip.block == Enum.at(chain2, 1)
    
    bt = Enum.reduce(tl(chain3), bt, &Blocktree.add_block(&2, &1))
    assert bt.mainchain.tip.block == Enum.at(chain3, -1)
    
    bt = Enum.reduce(tl(chain1), bt, &Blocktree.add_block(&2, &1))
    assert bt.mainchain.tip.block == Enum.at(chain3, -1)
  end
  
  @doc """
  This test verifies that old forks are dropped once a certain depth is reached.
  """
  test "Purge old forks", data do
    chain1 = Stream.take(data.chain1, 1) |> Enum.to_list
    chain2 = Stream.take(data.chain2, 3) |> Enum.to_list
    chain3 = Stream.take(data.chain3, 10) |> Enum.to_list
    bt = Blocktree.add_block(data.bt, hd(chain1))
    bt = Enum.reduce(chain2, bt, &Blocktree.add_block(&2, &1))
    bt = Enum.reduce(Enum.take(chain3, 1), bt, &Blocktree.add_block(&2, &1))
    assert length(bt.forks) == 3
    bt = Enum.reduce(Enum.take(chain3, 8) |> tl, bt, &Blocktree.add_block(&2, &1))
    assert length(bt.forks) == 2
    bt = Enum.reduce(Enum.take(chain3, -2), bt, &Blocktree.add_block(&2, &1))
    assert length(bt.forks) == 1
  end
end