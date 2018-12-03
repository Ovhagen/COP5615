defmodule Proj4.MinerTest do
  use ExUnit.Case
  @moduledoc """
  This module defines unit tests for the Miner module.
  """
  setup do
    {genesis_pubkey, genesis_privkey} = KeyAddress.keypair(1337)
    {miner_pubkey, miner_privkey} = KeyAddress.keypair
    {pubkeys, privkeys} = (for _n <- 1..10, do: KeyAddress.keypair)
      |> Enum.unzip
    bc = Blockchain.genesis
    vout = (for n <- 0..9, do: Transaction.Vout.new(99_500_000, Enum.at(pubkeys, n) |> KeyAddress.pubkey_to_pkh))
    tx = Transaction.new(
      [Transaction.Vin.new(
          bc.tip.block.transactions |> hd |> Transaction.hash,
          0
        )],
      vout
    )
    tx = Transaction.sign(tx, [genesis_pubkey], [genesis_privkey])
    {:ok, bc} = Blockchain.add_to_mempool(bc, tx)
    %{
      bc:              bc,
      genesis_pubkey:  genesis_pubkey,
      genesis_privkey: genesis_privkey,
      miner_pubkey:    miner_pubkey,
      miner_privkey:   miner_privkey,
      pubkeys:         pubkeys,
      privkeys:        privkeys
    }
  end
  
  @doc """
  This test verifies that the miner can mine a new block, and the block is accepted as valid by the blockchain.
  The test also verifies that invalid mined blocks are rejected.
  """
  test "Mine new block", data do
    # Mine a valid block
    block = Miner.mine_block(data.bc, data.bc.mempool, KeyAddress.pubkey_to_pkh(data.miner_pubkey), "test")
    :ok = Blockchain.verify_block(data.bc, block)
    
    # Block hash does not meet difficulty target
    {:error, :hash} = Blockchain.verify_block(data.bc, Map.update!(block, :header, &Map.put(&1, :nonce, 1)))
    
    # Previous block hash does not match highest block in the blockchain
    block2 = Miner.mine_block(Map.update!(data.bc, :tip, &Map.put(&1, :hash, <<0::256>>)), data.bc.mempool, KeyAddress.pubkey_to_pkh(data.miner_pubkey), "test")
    {:error, :tip} = Blockchain.verify_block(data.bc, block2)
    
    # Difficulty target does not match expected target for the blockchain
    bc = Map.update!(data.bc, :tip, fn x -> Map.update!(x, :block, fn y -> Map.update!(y, :header, &Map.put(&1, :target, <<0x20001000::32>>)) end) end)
    {:error, :target} = Blockchain.verify_block(bc, block)
    
    # Block contains transactions which are not in the mempool
    tx = Transaction.test(2, 2)
    block = Miner.mine_block(data.bc, Map.new([{Transaction.hash(tx), %{tx: tx, fee: 10}}]), KeyAddress.pubkey_to_pkh(data.miner_pubkey), "test")
    {:error, :mempool} = Blockchain.verify_block(data.bc, block)
  end
end