defmodule Proj4.TransactionTest do
  use ExUnit.Case
  @moduledoc """
  This module defines a test
  """
  @tag :tx
  test "Serialize and deserialize signed transaction" do
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
    tx = Transaction.sign(tx, [KeyAddress.compress_pubkey(pubkey1)], [privkey1])
    assert tx == Transaction.deserialize(Transaction.serialize(tx))
  end
end
