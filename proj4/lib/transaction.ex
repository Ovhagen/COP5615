defmodule Transaction do
  import Crypto
  
  @tx_version 1
  defstruct version: @tx_version, vin: [], vout: []
  
  def validate(%Transaction{} = tx) do
    # do stuff
  end
  
  def serialize(%Transaction{version: version, vin: vin, vout: vout}, sighash // false) do
    <<@tx_version::8>>
      <> <<length(vin)::8>>
      <> Vin.serialize(vin, sighash)
      <> <<length(vout)::8>>
      <> Vout.serialize(vout)
  end
  
  def deserialize(<<version::integer-8, data::binary>>), do: deserialize(data, nil, nil, %Transaction{version: version})
  defp deserialize(<<vins::integer-8, data::binary>>, nil, nil, tx), do: deserialize(data, vins, nil, tx)
  defp deserialize(<<vouts::integer-8, data::binary>>, 0, nil, tx), do: deserialize(data, 0, vouts, tx)
  defp deserialize(<<>>, 0, 0, tx), do: tx
  defp deserialize(data, vins, nil, tx) do
    <<_pubkey::33, 0x30>> = data
    deserialize(data, vins-1, vouts, Map.update!(tx, :vin, &(&1 ++ [Vin.deserialize(vin)])))
  defp deserialize(<<vout::vout, data::binary>>, 0, vouts, tx), do: deserialize(data, 0, vouts-1, Map.update!(tx, :vout, &(&1 ++ [Vout.deserialize(vout)])))
  
  def sighash(tx), do: serialize(tx, true) |> sha256 |> sha256
  
  def sign(tx, pubkeys, privkeys) do
    sighash = sighash(tx)
    Map.update!(tx, :vin, fn vin ->
      Enum.zip(vin, Enum.zip(pubkeys, privkeys))
      |> Enum.map(fn {vin, {pubkey, privkey}} -> 
           Map.put(vin, :witness, %Witness{pubkey: pubkey, sig: :crypto.sign(:ecdsa, :sha256, sighash, [privkey, :secp256k1])})
         end)
    end)
  end
end

defmodule Vin do
  defstruct txid: nil, vout: nil, witness: %Witness{}
  
  def serialize(vin, sighash // false)
  def serialize([vin | tail], sighash), do: serialize(vin, sighash) <> serialize(tail, sighash)
  def serialize(%Vin{txid: txid, vout: vout, witness: witness}, sighash) do:
    txid
      <> <<vout::8>>
      <> (if sighash, do: Witness.serialize(witness), else: <<>>)
  end
  def serialize([], _sighash), do: <<>>
  
  def deserialize(<<txid::256, vout::8, >>), do: 
end

defmodule Witness do
  defstruct [:pubkey, :sig]
  
  def serialize(%Witness{pubkey: pubkey, sig: sig}), do: pubkey <> sig
  
  def deserialize(<<pubkey::32, sig::binary>>) do
    
  end
end

defmodule Vout do
  defstruct [:value, :pkh]
  
  def serialize([vin | tail]), do: serialize(vin) <> serialize(tail)
  def serialize(%Vin{value: value, pkh: pkh}), do: <<value::32>> <> pkh
  def serialize([]), do: <<>>
  
  def deserialize(<<value::32, pkh::160>>), do: %Vout{value: value, pkh: pkh}
end