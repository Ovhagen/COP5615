defmodule Proj4.BlockchainTest do
  use ExUnit.Case
  @moduledoc """
  This module defines unit tests for the Blockchain module.
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
          Block.transactions(bc.tip.block) |> hd |> Transaction.hash,
          0
        )],
      vout
    )
    tx = Transaction.sign(tx, [genesis_pubkey], [genesis_privkey])
    vout = (for n <- 0..9, do: Transaction.Vout.new(99_500_000, Enum.at(pubkeys, n) |> KeyAddress.pubkey_to_pkh))
    tx2 = Transaction.new(
      [Transaction.Vin.new(
          Block.transactions(bc.tip.block) |> hd |> Transaction.hash,
          0
        )],
      vout
    )
    tx2 = Transaction.sign(tx2, [genesis_pubkey], [genesis_privkey])
    %{
      bc:              bc,
      tx:              tx,
      tx2:             tx2,
      genesis_pubkey:  genesis_pubkey,
      genesis_privkey: genesis_privkey,
      miner_pubkey:    miner_pubkey,
      miner_privkey:   miner_privkey,
      miner_pkh:       KeyAddress.pubkey_to_pkh(miner_pubkey),
      pubkeys:         pubkeys,
      privkeys:        privkeys
    }
  end
  
  @doc """
  This test verifies that valid transactions can be added to the mempool. A valid transaction is a
  properly signed transaction with inputs that correspond to unspent outputs (UTXOs) on the blockchain.
  Once a transaction is added to the mempool, the UTXOs which were used in that transaction are then removed
  from the available UTXOs.
  This test also verifies that transactions which do not meet these requirements are rejected.
  """
  test "Add transaction to mempool", data do
    # Mempool contains a UTXO, valid transaction is added which uses the UTXO, then the UTXO is marked as spent
    assert data.bc.utxo != %{}
    {:ok, bc} = Blockchain.add_to_mempool(data.bc, data.tx)
    Enum.each(bc.utxo, fn
      {:index, _}   -> assert true
      {_txid, utxo} -> assert utxo.spent_by != nil
    end)
    
    # The transaction must have a valid signature
    {:error, :sig} = Blockchain.add_to_mempool(data.bc, Transaction.sign(data.tx, [data.genesis_pubkey], [data.miner_privkey]))
    
    # Each input must be signed by the private key corresponding to the public key hash from the UTXO
    {:error, :pkh} = Blockchain.add_to_mempool(data.bc, Transaction.sign(data.tx, [data.miner_pubkey], [data.miner_privkey]))
    
    # All inputs must correspond to unspent outputs (UTXOs) from the blockchain
    {:error, :utxo} = Blockchain.add_to_mempool(bc, Transaction.test(1, 2))
    {:error, :spent} = Blockchain.add_to_mempool(bc, data.tx)
    
    # The transaction fee (inputs - outputs) must be greater than 0
    tx = Map.update!(data.tx, :vout, &(&1 ++ &1)) |> Transaction.sign([data.genesis_pubkey], [data.genesis_privkey])
    {:error, :fee} = Blockchain.add_to_mempool(data.bc, tx)
  end
  
  @doc """
  This test verifies that the miner can mine a new block, and the block is accepted as valid by the blockchain.
  The test also verifies that invalid mined blocks are rejected.
  """
  test "Mine new block", data do
    # Mine a valid block
    block = Miner.mine_block(data.bc, data.bc.mempool, data.miner_pkh, "test")
    :ok = Blockchain.verify_block(data.bc, block)
    
    # Block hash does not meet difficulty target
    {:error, :hash} = Blockchain.verify_block(data.bc, Map.update!(block, :header, &Map.put(&1, :nonce, 1)))
    
    # Previous block hash does not match highest block in the blockchain
    block2 = Miner.mine_block(Map.update!(data.bc, :tip, &Map.put(&1, :hash, <<0::256>>)), data.bc.mempool, data.miner_pkh, "test")
    {:error, :tip} = Blockchain.verify_block(data.bc, block2)
    
    # Difficulty target does not match expected target for the blockchain
    bc = Map.update!(data.bc, :tip, fn x -> Map.update!(x, :block, fn y -> Map.update!(y, :header, &Map.put(&1, :target, <<0x20001000::32>>)) end) end)
    {:error, :target} = Blockchain.verify_block(bc, block)
    
    # Block contains transactions which are not in the mempool
    tx = Transaction.test(2, 2)
    block = Miner.mine_block(data.bc, Map.new([{Transaction.hash(tx), %{tx: tx, fee: 10}}]), data.miner_pkh, "test")
    {:mempool, [^tx]} = Blockchain.verify_block(data.bc, block)
    
    # Coinbase transaction has incorrect output value
    block = Miner.mine_block(data.bc, data.bc.mempool, data.miner_pkh, "test")
    {:ok, bc} = Blockchain.add_block(data.bc, block)
    bc2 = Map.update!(bc, :tip, fn tip -> Map.update!(tip, :height, &(&1 + 1)) end)
    block = Miner.mine_block(bc2, bc2.mempool, data.miner_pkh, "test")
    {:error, :value} = Blockchain.verify_block(bc, block)
  end
  
  @doc """
  This test verifies that newly mined blocks can be added to the blockchain, and that the mempool and
  UTXO index are correctly updated based on transactions from the new block.
  """
  test "Add valid blocks to blockchain", data do
    # Mine empty block and add it to the blockchain
    root = data.bc.tip
    block = Miner.mine_block(data.bc, data.bc.mempool, data.miner_pkh, "test")
    {:ok, bc} = Blockchain.add_block(data.bc, block)
    assert bc.tip.block == block
    assert bc.tip.height == 1
    assert bc.tip.prev.hash == root.hash
    assert length(Map.keys(bc.mempool)) == 0
    assert length(Map.keys(bc.utxo)) == 3
    assert length(Map.keys(bc.tip.stxo)) == 1
    
    # Mine block containing a transaction and add it to the blockchain
    {:ok, bc} = Blockchain.add_to_mempool(data.bc, data.tx)
    block = Miner.mine_block(bc, bc.mempool, data.miner_pkh, "test")
    {:ok, bc} = Blockchain.add_block(bc, block)
    assert length(Map.keys(bc.mempool)) == 0
    assert length(Map.keys(bc.utxo)) == 12
    assert length(Map.keys(bc.tip.stxo)) == 2
    
    # Mine block which doesn't include the full mempool and add it to the blockchain
    block = Miner.mine_block(data.bc, data.bc.mempool, data.miner_pkh, "test")
    {:ok, bc} = Blockchain.add_to_mempool(data.bc, data.tx)
    {:ok, bc} = Blockchain.add_block(bc, block)
    assert length(Map.keys(bc.mempool)) == 1
    assert length(Map.keys(bc.utxo)) == 3
    
    # Sequentially mine and add multiple empty blocks
    block = Miner.mine_block(data.bc, data.bc.mempool, data.miner_pkh, "test")
    {:ok, bc} = Blockchain.add_block(data.bc, block)
    block = Miner.mine_block(bc, bc.mempool, data.miner_pkh, "test2")
    {:ok, bc} = Blockchain.add_block(bc, block)
    block = Miner.mine_block(bc, bc.mempool, data.miner_pkh, "test3")
    {:ok, bc} = Blockchain.add_block(bc, block)
    block = Miner.mine_block(bc, bc.mempool, data.miner_pkh, "test4")
    {:ok, bc} = Blockchain.add_block(bc, block)
    assert bc.tip.height == 4
    assert bc.tip.prev.prev.prev.prev.hash == root.hash
    assert length(Map.keys(bc.utxo)) == 6
  end
  
  test "Add blocks which include transactions not in the mempool", data do
    txmatch = data.tx
    tx = {Transaction.hash(data.tx), %{tx: data.tx, fee: 5_000_000}}
    tx2 = {Transaction.hash(data.tx2), %{tx: data.tx2, fee: 5_000_000}}
    block = Miner.mine_block(data.bc, Map.new([tx]), data.miner_pkh, "test")
    {:mempool, [^txmatch]} = Blockchain.verify_block(data.bc, block)
    {:ok, _bc} = Blockchain.add_block(data.bc, block)
    
    block = Miner.mine_block(data.bc, Map.new([tx, tx2]), data.miner_pkh, "test")
    {:error, :double_spend} = Blockchain.add_block(data.bc, block)
    
    {:ok, bc} = Blockchain.add_to_mempool(data.bc, data.tx)
    block = Miner.mine_block(bc, Map.new([tx2]), data.miner_pkh, "test")
    {:ok, bc} = Blockchain.add_block(bc, block)
    assert length(Map.keys(bc.mempool)) == 0
  end
end