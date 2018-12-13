defmodule BlocktreeTest do
  use ExUnit.Case
  @moduledoc """
  This module defines unit tests for the Blocktree module.
  """

  defp blockstream(bc, msg) do
    Stream.unfold(bc, fn bc ->
      {:ok, block} = Miner.build_mine_block(bc, elem(KeyAddress.keypair(1337), 0) |> KeyAddress.pubkey_to_pkh, msg)
      {
        block,
        Blockchain.add_block(bc, block) |> elem(1)
      }
    end)
  end
  
  defp blockstream(bc, {pubkey, privkey}, msg) do
    Stream.unfold({bc, {pubkey, privkey}}, fn {bc, {pubkey, privkey}} ->
      {:ok, bc} = Blockchain.add_to_mempool(bc, Transaction.sign(build_tx(bc), pubkey, privkey))
      keypair = KeyAddress.keypair
      {:ok, block} = Miner.build_mine_block(bc, elem(keypair, 0) |> KeyAddress.pubkey_to_pkh, msg)
      {
        block,
        {Blockchain.add_block(bc, block) |> elem(1), keypair}
      }
    end)
  end
  
  defp build_tx(bc) do
    tx = Block.transactions(bc.tip.block) |> hd
    value = tx.vout |> hd |> Map.get(:value) |> Kernel.-(500)
    Transaction.new(
      [Transaction.Vin.new(Transaction.hash(tx), 0)],
      [Transaction.Vout.new(value, :crypto.strong_rand_bytes(20))]
    )
  end
  
  setup do
    bt = Blocktree.genesis
    keypair = KeyAddress.keypair(1337)
    %{
      bt:      bt,
      keypair: keypair,
      chain1:  blockstream(bt.mainchain, keypair, "test1"),
      chain2:  blockstream(bt.mainchain, keypair, "test2"),
      chain3:  blockstream(bt.mainchain, keypair, "test3")
    }
  end
  
  @doc """
  This test verifies that the mainchain is updated correctly when a longer chain is found.
  """
  test "Update mainchain", data do
    chain1 = Stream.take(data.chain1, 3) |> Enum.to_list
    {:ok, bt} = Blocktree.add_block(data.bt, hd(chain1))
    assert Blocktree.forked?(bt) == false
    assert bt.mainchain.tip.block == hd(chain1)
    
    chain2 = Stream.take(data.chain2, 3) |> Enum.to_list
    chain3 = Stream.take(data.chain3, 3) |> Enum.to_list
    {:ok, bt} = Blocktree.add_block(bt, hd(chain2))
    {:ok, bt} = Blocktree.add_block(bt, hd(chain3))
    assert length(bt.forks) == 3
    assert bt.mainchain.tip.block == hd(chain1)
    
    {:ok, bt} = Blocktree.add_block(bt, Enum.at(chain2, 1))
    assert bt.mainchain.tip.block == Enum.at(chain2, 1)
    
    bt = Enum.reduce(tl(chain3), bt, &(Blocktree.add_block(&2, &1) |> elem(1)))
    assert bt.mainchain.tip.block == Enum.at(chain3, -1)
    
    bt = Enum.reduce(tl(chain1), bt, &(Blocktree.add_block(&2, &1) |> elem(1)))
    assert bt.mainchain.tip.block == Enum.at(chain3, -1)
  end
  
  @doc """
  This test verifies that old forks are dropped once a certain depth is reached.
  """
  test "Purge old forks", data do
    chain1 = Stream.take(data.chain1, 1) |> Enum.to_list
    chain2 = Stream.take(data.chain2, 3) |> Enum.to_list
    chain3 = Stream.take(data.chain3, 10) |> Enum.to_list
    {:ok, bt} = Blocktree.add_block(data.bt, hd(chain1))
    bt = Enum.reduce(chain2, bt, &(Blocktree.add_block(&2, &1) |> elem(1)))
    bt = Enum.reduce(Enum.take(chain3, 1), bt, &(Blocktree.add_block(&2, &1) |> elem(1)))
    assert length(bt.forks) == 3
    bt = Enum.reduce(Enum.take(chain3, 8) |> tl, bt, &(Blocktree.add_block(&2, &1) |> elem(1)))
    assert length(bt.forks) == 2
    bt = Enum.reduce(Enum.take(chain3, -2), bt, &(Blocktree.add_block(&2, &1) |> elem(1)))
    assert length(bt.forks) == 1
  end
  
  @doc """
  This test verifies that orphaned or duplicate blocks are identified correctly.
  """
  test "Identify orphan and duplicate blocks", data do
    chain1 = Stream.take(data.chain1, 8) |> Enum.to_list
    bt = Enum.reduce(chain1, data.bt, &(Blocktree.add_block(&2, &1) |> elem(1)))
    chain2 = Stream.take(data.chain2, 4) |> Enum.to_list
    {:orphan, bt} = Blocktree.add_block(bt, hd(chain2))
    {:orphan, bt} = Blocktree.add_block(bt, hd(tl(chain2)))
    
    {:error, :duplicate} = Blocktree.add_block(bt, Enum.at(chain1, -1))
  end
  
  @doc """
  This test verifies that forks are created correctly, by "rewinding" the transactions from the parent chain.
  """
  test "Create forks correctly", data do
    bt = blockstream(data.bt.mainchain, "test1")
      |> Stream.take(2)
      |> Enum.to_list
      |> Enum.reduce(data.bt, &(Blocktree.add_block(&2, &1) |> elem(1)))
    chain1 = blockstream(bt.mainchain, "test1") |> Stream.take(3) |> Enum.to_list
    chain2 = blockstream(bt.mainchain, "test2") |> Stream.take(2) |> Enum.to_list
    bt = Enum.concat(chain1, chain2)
      |> Enum.reduce(bt, &(Blocktree.add_block(&2, &1) |> elem(1)))
    assert length(bt.forks) == 2
    fork = Enum.at(bt.forks, 1)
    assert map_size(bt.mainchain.utxo) == 7
    assert map_size(fork.utxo) == 6
  end
  
  @doc """
  This test verifies that transactions can be added to mempools correctly.
  """
  test "Add transactions to mempools", data do
    {:error, :orphan} = Blocktree.add_to_mempool(data.bt, Transaction.test(1, 2))
    
    bt = blockstream(data.bt.mainchain, "test1")
      |> Stream.take(2)
      |> Enum.to_list
      |> Enum.reduce(data.bt, &(Blocktree.add_block(&2, &1) |> elem(1)))
    chain1 = blockstream(bt.mainchain, "test1") |> Stream.take(3) |> Enum.to_list
    chain2 = blockstream(bt.mainchain, "test2") |> Stream.take(2) |> Enum.to_list
    bt = Enum.concat(chain1, chain2)
      |> Enum.reduce(bt, &(Blocktree.add_block(&2, &1) |> elem(1)))
    
    tx = build_tx(data.bt.mainchain) |> Transaction.sign(elem(data.keypair, 0), elem(data.keypair, 1))
    {:ok, bt} = Blocktree.add_to_mempool(bt, tx)
    bc0 = Enum.at(bt.forks, 0)
    bc1 = Enum.at(bt.forks, 1)
    assert map_size(bc0.mempool) == 1
    assert map_size(bc1.mempool) == 1
    
    tx = build_tx(bt.mainchain) |> Transaction.sign(elem(data.keypair, 0), elem(data.keypair, 1))
    {:ok, bt} = Blocktree.add_to_mempool(bt, tx)
    bc0 = Enum.at(bt.forks, 0)
    bc1 = Enum.at(bt.forks, 1)
    assert map_size(bc0.mempool) == 2
    assert map_size(bc1.mempool) == 1
    
    {:error, :orphan} = Blocktree.add_to_mempool(bt, Transaction.test(1, 2))
  end
end