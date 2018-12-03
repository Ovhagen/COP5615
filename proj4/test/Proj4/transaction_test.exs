defmodule Proj4.TransactionTest do
  use ExUnit.Case
  @moduledoc """
  This module defines unit tests for the Transaction module
  """
  setup do
    tx = Transaction.test(1, 2)
    coinbase = Transaction.coinbase(tx.vout)
    %{
      tx:       tx,
      coinbase: coinbase
    }
  end

  @doc """
  This test verifies that a properly signed transaction can be verified,
  and that improperly signed transactions fail verification.
  """
  test "Verify a signed transaction", data do
    # Valid signature
    assert Transaction.verify(data.tx)
    
    # Invalid signature (public and private keys don't match)
    {pubkey, _} = KeyAddress.keypair
    {_, privkey} = KeyAddress.keypair
    assert Transaction.verify(Transaction.sign(data.tx, [pubkey], [privkey])) == false
    
    # Valid signature, but wrong signed message
    tx = Transaction.test(1, 2) |> Map.put(:vin, data.tx.vin)
    assert Transaction.verify(tx) == false
  end

  @doc """
  This test verifies that both regular and coinbase transactions can be recovered from serialized form (raw bytes).
  """
  test "Serialize and deserialize transaction", data do
    # Serialize and deserialize a regular transaction
    assert data.tx == Transaction.deserialize(Transaction.serialize(data.tx))
    
    # Serialize and deserialize a coinbase transaction
    assert data.coinbase == Transaction.deserialize(Transaction.serialize(data.coinbase))
  end

  @doc """
  This test verifies that the length of a transaction in raw bytes is calculated correctly.
  """
  test "Byte size is calculated correctly", data do
    assert Transaction.bytes(data.tx) == byte_size(Transaction.serialize(data.tx))
  end

  @doc """
  This test verifies that a properly constructed coinbase transaction can be identified,
  and that improperly constructed coinbase transactions are rejected.
  """
  test "Verify coinbase transaction structure", data do
    # Verify a proper coinbase transaction
    assert {:ok, -Transaction.fee([], data.coinbase.vout)} == Transaction.verify_coinbase(data.coinbase)

    # Transaction must have at least one output
    no_outputs = Map.put(data.coinbase, :vout, [])
    assert {:error, :io_count} == Transaction.verify_coinbase(no_outputs)
    
    # Transaction must have exactly one input
    no_inputs = Map.put(data.coinbase, :vin, [])
    assert {:error, :io_count} == Transaction.verify_coinbase(no_inputs)
    excess_inputs = Map.update!(data.coinbase, :vin, &(&1 ++ &1))
    assert {:error, :io_count} == Transaction.verify_coinbase(excess_inputs)

    # Transaction input must follow coinbase format exactly
    assert {:error, :vin} == Transaction.verify_coinbase(data.tx)
  end
end
