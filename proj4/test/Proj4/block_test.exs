defmodule Proj4.BlockTest do
  use ExUnit.Case
  @moduledoc """
  This module defines unit tests for the Block module
  """
  setup do
    {pubkey1, privkey1} = KeyAddress.keypair
    {pubkey2, privkey2} = KeyAddress.keypair
    pkh = KeyAddress.pubkey_to_pkh(pubkey2)
    tx = %Transaction{
      vin: [
        %Transaction.Vin{
          txid: :crypto.strong_rand_bytes(32),
          vout: 0
        }],
      vout: [
        %Transaction.Vout{
          value: 100_000_000,
          pkh:   pkh
        }]
    }
    tx = Transaction.sign(tx, [pubkey1], [privkey1])
    coinbase = Transaction.coinbase(tx.vout)
    %{
      pubkey1:  pubkey1,
      privkey1: privkey1,
      pubkey2:  pubkey2,
      privkey2: privkey2,
      tx:       tx,
      coinbase: coinbase
    }
  end
  
  test "Verify a signed transaction", data do
    assert Transaction.verify(data.tx)
    assert Transaction.verify(Transaction.sign(data.tx, [data.pubkey1], [data.privkey2])) == false
  end
    
  test "Serialize and deserialize transaction", data do
    assert data.tx == Transaction.deserialize(Transaction.serialize(data.tx))
    assert data.coinbase == Transaction.deserialize(Transaction.serialize(data.coinbase))
  end
  
  test "Byte size is calculated correctly", data do
    assert Transaction.bytes(data.tx) == byte_size(Transaction.serialize(data.tx))
  end
  
  test "Verify coinbase transaction structure", data do
    assert {:ok, 100_000_000} == Transaction.verify_coinbase(data.coinbase)
    
    no_outputs = Map.put(data.coinbase, :vout, [])
    assert {:error, :io_count} == Transaction.verify_coinbase(no_outputs)
    no_inputs = Map.put(data.coinbase, :vin, [])
    assert {:error, :io_count} == Transaction.verify_coinbase(no_inputs)
    excess_inputs = Map.update!(data.coinbase, :vin, &(&1 ++ &1))
    assert {:error, :io_count} == Transaction.verify_coinbase(excess_inputs)
    
    assert {:error, :vin} == Transaction.verify_coinbase(data.tx)
  end
end