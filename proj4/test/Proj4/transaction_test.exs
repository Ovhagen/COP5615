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

  test "Verify a signed transaction", data do
    assert Transaction.verify(data.tx)
    {pubkey, _} = KeyAddress.keypair
    {_, privkey} = KeyAddress.keypair
    assert Transaction.verify(Transaction.sign(data.tx, [pubkey], [privkey])) == false
  end

  test "Serialize and deserialize transaction", data do
    assert data.tx == Transaction.deserialize(Transaction.serialize(data.tx))
    assert data.coinbase == Transaction.deserialize(Transaction.serialize(data.coinbase))
  end

  test "Byte size is calculated correctly", data do
    assert Transaction.bytes(data.tx) == byte_size(Transaction.serialize(data.tx))
  end

  test "Verify coinbase transaction structure", data do
    assert {:ok, -Transaction.fee([], data.coinbase.vout)} == Transaction.verify_coinbase(data.coinbase)

    no_outputs = Map.put(data.coinbase, :vout, [])
    assert {:error, :io_count} == Transaction.verify_coinbase(no_outputs)
    no_inputs = Map.put(data.coinbase, :vin, [])
    assert {:error, :io_count} == Transaction.verify_coinbase(no_inputs)
    excess_inputs = Map.update!(data.coinbase, :vin, &(&1 ++ &1))
    assert {:error, :io_count} == Transaction.verify_coinbase(excess_inputs)

    assert {:error, :vin} == Transaction.verify_coinbase(data.tx)
  end
end
