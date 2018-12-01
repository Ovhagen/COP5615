defmodule Proj4.TransactionTest do
  use ExUnit.Case
  @moduledoc """
  This module defines unit tests for the Transaction module
  """
  setup do
    {pubkey1, privkey1} = KeyAddress.keypair
    {pubkey2, privkey2} = KeyAddress.keypair
    pkh = KeyAddress.pubkey_to_pkh(pubkey2)
    tx = %Transaction{
      vin: [
        %Transaction.Vin{
          txid: :crypto.strong_rand_bytes(32),
          vout: 1
        }],
      vout: [
        %Transaction.Vout{
          value: 100_000_000,
          pkh:   pkh
        }]
    }
    tx = Transaction.sign(tx, [pubkey1], [privkey1])
    %{
      pubkey1: pubkey1,
      privkey1: privkey1,
      pubkey2: pubkey2,
      privkey2: privkey2,
      tx: tx
    }
  end
  
  test "Verify a signed transaction", data do
    assert Transaction.verify(data.tx)
    assert Transaction.verify(Transaction.sign(data.tx, [data.pubkey1], [data.privkey2])) == false
  end
    
  test "Serialize and deserialize transaction", data do
    assert data.tx == Transaction.deserialize(Transaction.serialize(data.tx))
  end
  
  test "Byte size is calculated correctly", data do
    assert Transaction.bytes(data.tx) == byte_size(Transaction.serialize(data.tx))
  end
end
