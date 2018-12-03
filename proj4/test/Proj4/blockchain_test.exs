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
          bc.tip.block.transactions |> hd |> Transaction.hash,
          0
        )],
      vout
    )
    tx = Transaction.sign(tx, [genesis_pubkey], [genesis_privkey])
    %{
      bc:              bc,
      tx:              tx,
      genesis_pubkey:  genesis_pubkey,
      genesis_privkey: genesis_privkey,
      miner_pubkey:    miner_pubkey,
      miner_privkey:   miner_privkey,
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
    # Mempool contains a UTXO, valid transaction is added which uses the UTXO, then the UTXO is removed
    assert data.bc.utxo != %{}
    {:ok, bc} = Blockchain.add_to_mempool(data.bc, data.tx)
    assert bc.utxo == %{}
    
    # The transaction must have a valid signature
    {:error, :sig}  = Blockchain.add_to_mempool(data.bc, Transaction.sign(data.tx, [data.genesis_pubkey], [data.miner_privkey]))
    
    # Each input must be signed by the private key corresponding to the public key hash from the UTXO
    {:error, :pkh}  = Blockchain.add_to_mempool(data.bc, Transaction.sign(data.tx, [data.miner_pubkey], [data.miner_privkey]))
    
    # All inputs must correspond to unspent outputs (UTXOs) from the blockchain
    {:error, :utxo} = Blockchain.add_to_mempool(bc, data.tx)
    
    # The transaction fee (inputs - outputs) must be greater than 0
    tx = Map.update!(data.tx, :vout, &(&1 ++ &1)) |> Transaction.sign([data.genesis_pubkey], [data.genesis_privkey])
    {:error, :fee} = Blockchain.add_to_mempool(data.bc, tx)
  end
end