defmodule Blockchain do
  import Crypto
  
  @coin 1_000_000
  
  @type utxo :: %{required(<<_::264>>) => Transaction.Vout.t}
  @type mempool :: %{required(<<Crypto.hash256>>) => Transaction.t}
  
  defstruct tip: %Blockchain.Link{}, utxo: %{}, mempool%{}
  
  def verify_tx(bc, tx) do
    Transaction.verify(tx)
    case get_utxo(bc.utxo, tx.vin) do
      :error -> false
      vout   -> verify_pkh(vout, tx.vin) and tx_fee(vout, tx.vout) > 0
    end
  end
  
  def get_utxo(utxo, vin) do
    Enum.reduce_while(vin, [], fn vin, acc ->
      case Map.fetch(utxo, vin.txid <> <<vin.vout::8>>) do
        {:ok, vout} -> {:cont, acc ++ [vout]}
        :error      -> {:halt, :error}
      end
    end)
  end
  
  def verify_pkh(vout, vin) do
    Enum.zip(vout, vin)
    |> Enum.reduce_while(true, fn {vo, vi}, valid ->
         if vo.pkh == KeyAddress.pubkey_to_pkh(vi.witness.pubkey) do
           {:cont, true}
         else
           {:halt, false}
         end
       end)
  end
  
  def tx_fee(vin, vout), do: sum_value(vin) - sum_value(vout)
  
  defp sum_value(vout), do: Enum.reduce(vout, 0, &(&2 + &1.value))
  
  def verify_block(%Blockchain{} = bc, %Block{} = b) do
    # 1. Block points to tip of current blockchain
    # 2. Block is internally valid (merkle root and hash value)
    # 3. Difficulty target is correct
    # 4. All transactions are in the mempool (or could be added to the mempool)
    # 5. Coinbase transaction is correct (structure, fees and reward correct)
  end
  
  
  
  def block_subsidy(_height) do
    50 * @coin # constant block reward for now
  end
  
  def next_target(_chain, t) do
    t # just keep current target
  end
end