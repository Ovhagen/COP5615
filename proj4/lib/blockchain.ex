defmodule Blockchain do
  @coin 1_000_000

  defmodule Link do
    defstruct block: %Block{}, prev: %Block{}, height: 0

    @type t :: %Link{
      block:  Block.t,
      prev:   Block.t,
      height: non_neg_integer
    }
  end

  defstruct tip: %Block{}, utxo: %{}, mempool: %{}

  def verify(%Blockchain{} = bc, %Transaction{} = tx), do: Transaction.verify(tx) and verify_value(bc, tx)
  defp verify_value(%Blockchain{utxo: utxo}, %Transaction{vin: vin, vout: vout}) do
    q_in = Enum.reduce_while(vin, 0, fn %Transaction.Vin{txid: txid, vout: vout, witness: %Transaction.Witness{pubkey: pubkey}}, total ->
        case Map.fetch(utxo, txid <> <<vout::8>>) do
          {:ok, %Transaction.Vout{value: value, pkh: pkh}} ->
            if KeyAddress.pubkey_to_pkh(pubkey) == pkh do
              {:cont, total + value}
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
    # do stuff
  end

  def block_subsidy(_height) do
    50 * @coin # constant block reward for now
  end

  def next_target(_chain, t) do
    t # just keep current target
  end
end
