defmodule Transaction do
  import Crypto
  
  @tx_version  1
  @coinbase    0xff
  @max_outputs 254
  
  defmodule Witness do
    defstruct pubkey: <<>>, sig: <<>>
    
    @type t :: %Witness{
      pubkey: KeyAddress.Pubkey.t,
      sig:    binary
    }
    
    @doc """
    Signs a transaction, creating a new witness from a key pair and a transaction hash.
    """
    @spec sign(binary, binary, Crypto.hash256) :: t
    def sign(pubkey, privkey, msg) do
      %Witness{
        pubkey: KeyAddress.compress_pubkey(pubkey),
        sig: :crypto.sign(:ecdsa, :sha256, msg, [privkey, :secp256k1])
      }
    end
    
    @doc """
    Verifies that the witness provided was produced using the same transaction hash with the private key corresponding to the public key.
    Returns true if the witness is valid, false otherwise.
    """
    @spec verify(t, Crypto.hash256) :: boolean
    def verify(%Witness{pubkey: pubkey, sig: sig}, msg) do
      :crypto.verify(:ecdsa, :sha256, msg, sig, [KeyAddress.uncompress_pubkey(pubkey), :secp256k1])
    end
    
    @doc """
    Turns the witness data into raw bytes for hashing, transmitting and writing to disk.
    For coinbase transactions, the coinbase data is stored in the witness location so it must be handled as well.
    """
    @spec serialize(t | binary) :: binary
    def serialize(%Witness{pubkey: pubkey, sig: sig}), do: pubkey <> sig
    def serialize(coinbase) when is_binary(coinbase), do: coinbase
    
    @doc """
    Reproduces the witness data structure from raw bytes.
    For coinbase transactions, the coinbase data is stored in the witness location so it must be handled as well.
    """
    @spec deserialize(binary) :: t | binary
    def deserialize(<<coinbase::binary-34, 0x00>>), do: coinbase
    def deserialize(<<pubkey::binary-33, sig::binary>>), do: %Witness{pubkey: pubkey, sig: sig}
    def deserialize(<<>>), do: %Witness{}
    
    @doc """
    Calculates the byte length of the raw witness data.
    """
    @spec bytes(t) :: pos_integer
    def bytes(%Witness{sig: sig}), do: 33 + byte_size(sig)
  end
  
  defmodule Vin do
    defstruct txid: <<>>, vout: 0, witness: %Witness{}
    
    @type t :: %Vin{
      txid:    Crypto.hash256,
      vout:    byte,
      witness: Witness.t | binary
    }
    
    @doc """
    Creates a new transaction input. Requires a transaction hash and output index corresponding to the UTXO.
    """
    @spec new(Crypto.hash256, byte) :: t
    def new(txid, vout) do
      %Vin{
        txid:    txid,
        vout:    vout,
        witness: %Witness{}
      }
    end
    
    @doc """
    Verifies the witness contained in this input. See Witness.verify/2 for more details.
    """
    @spec verify(t | [t], Crypto.hash256) :: boolean
    def verify([%Vin{witness: witness} | tail], msg), do: Vin.verify(witness, msg) && verify(tail, msg)
    def verify(%Vin{witness: witness}, msg), do: Witness.verify(witness, msg)
    def verify([], _msg), do: true
    
    @doc """
    Turns the input data into raw bytes for hashing, transmitting and writing to disk.
    The sighash option removes the witness data from the output, and should be set to true if the output will be used as a transaction hash for signing.
    """
    @spec serialize(t | [t], boolean) :: binary
    def serialize(vin, sighash \\ false)
    def serialize([vin | tail], sighash), do: serialize(vin, sighash) <> serialize(tail, sighash)
    def serialize(%Vin{txid: txid, vout: vout, witness: witness}, sighash) do
      txid
        <> <<vout::8>>
        <> (if sighash, do: <<>>, else: Witness.serialize(witness))
    end
    def serialize([], _sighash), do: <<>>
    
    @doc """
    Reproduces the input data structure from raw bytes.
    """
    @spec deserialize(binary) :: t
    def deserialize(<<txid::binary-32, vout::8, witness::binary>>) do
      %Vin{
        txid:    txid,
        vout:    vout,
        witness: Witness.deserialize(witness)
      }
    end
    
    @doc """
    Calculates the byte length of the raw input data.
    """
    @spec bytes(t) :: pos_integer
    def bytes(%Vin{witness: witness}) when is_binary(witness), do: 33 + byte_size(witness)
    def bytes(%Vin{witness: witness}), do: 33 + Witness.bytes(witness)
  end

  defmodule Vout do
    defstruct value: 0, pkh: <<>>
    
    @type t :: %Vout{
      value: non_neg_integer,
      pkh:   Crypto.hash160
    }
    
    def serialize([vout | tail]), do: serialize(vout) <> serialize(tail)
    def serialize(%Vout{value: value, pkh: pkh}), do: <<value::32>> <> pkh
    def serialize([]), do: <<>>
    
    def deserialize(<<value::32, pkh::binary-20>>), do: %Vout{value: value, pkh: pkh}
    
    def bytes(_vout), do: 24
  end
  
  defstruct version: @tx_version, vin: [], vout: []
  
  @type t :: %Transaction{
    version: non_neg_integer,
    vin:     [Vin.t, ...] | Coinbase.t,
    vout:    [Vout.t, ...]
  }
  
  def sign(tx, pubkeys, privkeys) do
    sighash = sighash(tx)
    Map.update!(tx, :vin, fn vin ->
      Enum.zip(vin, Enum.zip(pubkeys, privkeys))
      |> Enum.map(fn {vin, {pubkey, privkey}} -> 
           Map.put(vin, :witness, Witness.sign(pubkey, privkey, sighash))
         end)
    end)
  end
  
  def verify(%Transaction{vin: vins} = tx), do: Vin.verify(vins, sighash(tx))
  
  def sighash(tx), do: serialize(tx, true) |> sha256x2
  
  def hash(tx), do: serialize(tx, false) |> sha256x2
  
  def serialize(%Transaction{version: version, vin: vin, vout: vout}, sighash \\ false) do
    <<version::8>>
      <> <<length(vin)::8>>
      <> Vin.serialize(vin, sighash)
      <> <<length(vout)::8>>
      <> Vout.serialize(vout)
  end
  
  def deserialize(<<version::8, data::binary>>), do: deserialize(data, nil, nil, %Transaction{version: version})
  defp deserialize(<<vins::8, data::binary>>, nil, nil, tx), do: deserialize(data, vins, nil, tx)
  defp deserialize(<<vouts::8, data::binary>>, 0, nil, tx), do: deserialize(data, 0, vouts, tx)
  defp deserialize(<<>>, 0, 0, tx), do: tx
  defp deserialize(data, vins, nil, tx) do
    <<_::536, bytes::8, _::binary>> = data
    bytes = bytes + 68
    <<vin::binary-size(bytes), data::binary>> = data
    deserialize(data, vins-1, nil, Map.update!(tx, :vin, &(&1 ++ [Vin.deserialize(vin)])))
  end
  defp deserialize(<<vout::binary-24, data::binary>>, 0, vouts, tx), do: deserialize(data, 0, vouts-1, Map.update!(tx, :vout, &(&1 ++ [Vout.deserialize(vout)])))
  
  def bytes(%Transaction{vin: vin, vout: vout}) do
    Enum.reduce(vin, 0, &(&2 + Vin.bytes(&1)))
      + Enum.reduce(vout, 0, &(&2 + Vout.bytes(&1)))
      + 3
  end
end