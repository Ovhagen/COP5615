defmodule Proj4.IntegrationTest do
  use ExUnit.Case
  @moduledoc """
  This module defines an integration test incorporating all of the modules defined in this project.
  """

  @doc """
  This helper function conducts a testing round using the given blockchain.
  """
  @spec testing_round(Blockchain.t, map, float, float) :: {:ok, Blockchain.t}
  def testing_round(bc, keys, utxo_ratio, tx_ratio) do
    # Select UTXOs to use when creating new transactions
    # UTXOs for the same address are grouped together
    inputs = Map.delete(bc.utxo, :index)
      |> Enum.filter(fn {_key, utxo} -> utxo.spent_by == nil end)
      |> Enum.map(fn {key, item} -> {key, item.vout} end)
      |> Enum.take_random(Map.keys(bc.utxo) |> length |> Kernel.-(1) |> Kernel.*(utxo_ratio) |> trunc)
      |> Enum.sort_by(&Map.get(elem(&1, 1), :pkh))
      |> Enum.chunk_while([], fn vout, acc ->
             cond do
               acc == [] ->
                 {:cont, [vout]}
               Map.get(elem(vout, 1), :pkh) == Map.get(elem(hd(acc), 1), :pkh) ->
                 {:cont, acc ++ [vout]}
               true ->
                 {:cont, acc, [vout]}
             end
           end,
           fn acc -> {:cont, acc, nil} end)

    # Generate one random transaction for each unique UTXO
    # Each transaction has one output, plus a change output if there are coins left over
    txs = Enum.map(inputs, fn input ->
        from = hd(input) |> elem(1) |> Map.get(:pkh)
        to = Map.delete(keys, from) |> Map.keys |> Enum.random
        value = Enum.map(input, &Map.get(elem(&1, 1), :value)) |> Enum.sum |> Kernel.-(500)
        spent = max(:rand.uniform(value), 10_000)
        spent = (if spent-value < 10_000, do: value, else: spent)
        vin = Enum.map(input, fn x ->
            {txid, vout} = elem(x, 0)
            Transaction.Vin.new(txid, vout)
          end)
        vout = [Transaction.Vout.new(spent, to)]
        vout = (if spent-value > 0, do: vout ++ [Transaction.Vout.new(spent-value, from)], else: vout)
        tx = Transaction.new(vin, vout)
        %{pubkey: pubkey, privkey: privkey} = Map.get(keys, from)
        Transaction.sign(tx, List.duplicate(pubkey, length(vin)), List.duplicate(privkey, length(vin)))
      end)

    # Add the new transactions to the mempool
    bc = Enum.reduce(txs, bc, &(Blockchain.add_to_mempool(&2, &1) |> elem(1)))

    # Randomly select a portion of the mempool and mine a new block
    tx_count = Map.keys(bc.mempool) |> length |> Kernel.*(tx_ratio) |> trunc
    mempool = Map.to_list(bc.mempool) |> Enum.take_random(tx_count) |> Map.new
    block = Miner.mine_block(bc, mempool, Enum.random(Map.keys(keys)), "test block")
    Blockchain.add_block(bc, block)
  end
  
  @doc """
  This test simulates the construction of a blockchain by generating addresses, constructing random transactions
  between the addresses, and mining blocks containing these transactions.
  
  The test begins by creating a new blockchain from the genesis block, and then mining a block with a single
  transaction that distributes the genesis coins in random amounts to random addresses.
  
  Then, five new blocks are mined through the following process:
    1. Generate random transactions using a portion of the UTXOs available
    2. Add the transactions to the mempool
    3. Mine a block using a portion of the mempool
    4. Add the new block to the blockchain
  
  After the final round has completed successfully, the total coin supply is verified to make sure no coins were lost.
  """
  test "Transact bitcoins" do
    # Generate "wallet" of 500 random keys, plus the genesis key
    keys = (for _n <- 1..500, do: KeyAddress.keypair)
      |> Enum.map(fn {pubkey, privkey} -> {KeyAddress.pubkey_to_pkh(pubkey), %{pubkey: pubkey, privkey: privkey}} end)
      |> Map.new
    
    # Create genesis block
    bc = Blockchain.genesis
    
    # Build initial transaction to distribute genesis coins
    vout = Stream.unfold(1_000_000_000, fn coins ->
        if coins > 40_000_000 do
          value = :rand.uniform(30_000_000) + 10_000_000
          {value, coins - value}
        else
          nil
        end
      end)
      |> Enum.zip(Enum.shuffle(Map.keys(keys)))
      |> Enum.map(fn {coins, pkh} -> Transaction.Vout.new(coins, pkh) end)
    tx = Transaction.new(
      [Transaction.Vin.new(
          Block.transactions(bc.tip.block) |> hd |> Transaction.hash,
          0
        )],
      vout
    )
    {genesis_pubkey, genesis_privkey} = KeyAddress.keypair(1337)
    tx = Transaction.sign(tx, [genesis_pubkey], [genesis_privkey])
    
    # Add initial transaction to mempool and mine a block
    {:ok, bc} = Blockchain.add_to_mempool(bc, tx)
    block = Miner.mine_block(bc, bc.mempool, Enum.random(Map.keys(keys)), "test block")
    {:ok, bc} = Blockchain.add_block(bc, block)
    
    # Conduct five rounds of random transactions and mining
    {:ok, bc} = testing_round(bc, keys, 0.8, 0.8)
    {:ok, bc} = testing_round(bc, keys, 0.6, 0.6)
    {:ok, bc} = testing_round(bc, keys, 0.5, 0.6)
    {:ok, bc} = testing_round(bc, keys, 0.6, 0.8)
    {:ok, bc} = testing_round(bc, keys, 0.8, 1.0)
    
    # Verify that the total coin supply is correct
    coin_supply = Map.delete(bc.utxo, :index) |> Map.values |> Enum.map(&Map.get(Map.get(&1, :vout), :value)) |> Enum.sum
    expected_supply = 1_000_000_000 + Enum.sum(for n <- 0..5, do: trunc(50_000_000 * :math.exp(-n/6000)))
    assert coin_supply == expected_supply
  end
end
