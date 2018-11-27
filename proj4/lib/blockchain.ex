defmodule Blockchain do
  import Crypto
  
  @coin 1_000_000
  
  defmodule Link do
    defstruct block: %Block{}, prev: %Block{}, height: 0
    
    @type t :: %Link{
      block:  Block.t,
      prev:   Block.t,
      height: non_neg_integer
    }
  end
  
  @type utxo :: %{required(<<_::264>>) => Transaction.Vout.t}
  @type mempool :: %{required(<<Crypto.hash256>>) => Transaction.t}
  
  defstruct tip: %Link{}, utxo: %{}, mempool%{}
  
  def verify_tx(bc, tx) do
    Transaction.verify(tx)
    case get_utxo(bc.utxo, tx) do
      :error -> false
      utxo   ->
        
      and verify_pkh(bc.utxo, tx)
      and verify_

  end
  defp verify_utxo(utxo, %Transaction{vin: vin}) do
    q_in = Enum.reduce_while(vin, 0, fn vin, total ->
        case Map.fetch(utxo, vin.txid <> <<vin.vout::8>>) do
          {:ok, vout} ->
            if KeyAddress.pubkey_to_pkh(vout.pubkey) == pkh do
              {:cont, total + vout.value}
            else
              {:halt, -1}
            end
          :error -> {:halt, -1}
        end
      end)
    q_out = Enum.reduce(vout, 0, &(&2 + Map.get(&1, :value)))
    q_in >= 0 and q_in - q_out >= 0
  end
  
  def verify(%Blockchain{} = bc, %Block{} = b) do
    # 1. Block points to tip of current blockchain
    # 2. Block is internally valid (merkle root and hash value)
    # 3. Difficulty target is correct
    # 4. All transactions are in the mempool (or could be added to the mempool)
    # 5. Coinbase transaction is correct (structure, fees and reward correct)
  end
  
  def tx_fee(%Transaction{vin: vin, vout: vout}, utxo) do
    Enum.reduce(vin, 0, &(&2 + Map.get(utxo, &1.txid <> <<&1.vout::8>>)))
  end
  
  def block_subsidy(_height) do
    50 * @coin # constant block reward for now
  end
  
  def next_target(_chain, t) do
    t # just keep current target
  end
end