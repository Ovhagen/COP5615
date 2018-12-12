defmodule Blockchain.UTXO do
  
  defmodule Index do
    defstruct [:block, :pos, :vout]
    @type t :: %Index{
      block: non_neg_integer,
      pos:   non_neg_integer,
      vout:  [non_neg_integer]
    }
  end
  
  defstruct vout: %Transaction.Vout{}, spent_by: nil
  
  @type utxo :: %Blockchain.UTXO{
    vout:     Transaction.Vout.t,
    spent_by: Crypto.hash256 | nil
  }
  @type key :: {Crypto.hash256, non_neg_integer} | :index
  @type index :: %{required(Crypto.hash256) => Index.t}
  @type t :: %{required(key) => utxo | index}
  
  @spec new() :: t
  def new(), do: %{index: %{}}
  
  @doc """
  Takes a transaction or list of transactions and generates an indexed map of UTXOs
  """
  @spec from_tx(Transaction.t | [Transaction.t, ...], non_neg_integer, non_neg_integer) :: t
  def from_tx(txs, block \\ 0, pos \\ 0)
  def from_tx(txs, block, pos) when is_list(txs) do
    Stream.with_index(txs)
    |> Enum.reduce(%{}, fn {tx, index}, utxo -> merge(utxo, from_tx(tx, block, index+pos)) end)
  end
  def from_tx(tx, block, pos), do: from_vout(tx.vout, 0, block, pos, Transaction.hash(tx), %{})
  defp from_vout([], count, block, pos, txid, utxo) do
    Map.put(utxo, :index, %{txid => %Index{
      block: block,
      pos:   pos,
      vout:  (for n <- 0..count-1, do: n)
    }})
  end
  defp from_vout([vout | tail], count, block, pos, txid, utxo) do
    from_vout(tail, count+1, block, pos, txid, Map.put(utxo, {txid, count}, %Blockchain.UTXO{vout: vout}))
  end

  @spec key(Transaction.t, non_neg_integer) :: key
  def key(tx, vout), do: {Transaction.hash(tx), vout}
  @spec key(Transaction.Vin.t) :: key
  def key(vin), do: {vin.txid, vin.vout}
  
  @doc """
  Updates a UTXO pool based on a list of transactions, and returns the updated UTXO pool as well as the spent outputs.
  The index for the spent outputs will also contain fully-spent transactions, to facilitate transaction pruning.
  """
  @spec update(t, non_neg_integer, [Transaction.t, ...]) :: {t, t}
  def update(utxo, block, txs) do
    # 1. Add the new outputs
    # 2. Mark the spent outputs
    # 3. Split the unspent and spent outputs
    merge(utxo, from_tx(txs, block))
    |> split_spent(txs)
  end
  
  @doc """
  Merges two UTXO pools. Duplicate elements are okay and will be collapsed into a single entry.
  """
  @spec merge(t, t) :: t
  def merge(utxo1, utxo2) do
    Map.merge(utxo1, utxo2, fn
      :index, a, b -> Map.merge(a, b, fn _, c, d -> Map.update!(c, :vout, &Enum.uniq(&1 ++ d.vout)) end)
      _key,   a, _ -> a
    end)
  end
  
  def spend(utxo, tx) when not is_list(tx), do: spend(utxo, [tx])
  def spend(utxo, txs) do
    Enum.map(txs, fn tx ->
      {Transaction.hash(tx), vins_to_keys(tx.vin)}
    end)
    |> Enum.reduce(utxo, fn {txid, keys}, m ->
         Enum.reduce(keys, m, fn key, n ->
           Map.update!(n, key, &Map.put(&1, :spent_by, txid))
         end)
       end)
  end
  
  defp split_spent(utxo, txs) do
    # Extract the spent outputs into a new map
    {stxo, utxo} = Map.split(utxo, txs_to_keys(txs))
    # Update the indexes for both lists through the following steps:
    #   1. Initialize the spent index with the empty entries
    #   2. For each entry in the spent list, remove it from the unspent index and add it to the spent index
    {uindex, sindex} = Enum.reduce(
      stxo,
      Enum.split_with(utxo.index, fn {_txid, %Index{vout: vout}} -> length(vout) > 0 end)
        |> remap,
      fn {{txid, vout}, _}, {u, s} ->
        {
          Map.update!(u, txid, &Map.update!(&1, :vout, fn list -> List.delete(list, vout) end)),
          Map.update(
            s,
            txid,
            Map.get(u, txid) |> Map.put(:vout, [vout]),
            &Map.update!(&1, :vout, fn list -> list ++ [vout] end)
          )
        }
      end)
    # Put the updated indexes in the respective maps
    {Map.put(utxo, :index, uindex), Map.put(stxo, :index, sindex)}
  end
  
  @doc """
  Resets the :spent_by field to nil for all outputs.
  """
  @spec unspend(t) :: t
  def unspend(stxo) do
    Enum.map(stxo, fn
      {:index, index} -> {:index, index}
      {txid, utxo} ->
        {txid, Map.put(utxo, :spent_by, nil)}
    end)
    |> Map.new
  end
  
  @spec trim(t) :: {t, t}
  def trim(utxo) do
    spent = Enum.filter(Map.to_list(utxo.index), fn {_txid, %Index{vout: vout}} -> length(vout) == 0 end)
      |> Map.new
    {Map.update!(utxo, :index, &Map.drop(&1, Map.keys(spent))), spent}
  end
  
  def txs_to_keys(txs), do: Enum.flat_map(txs, fn tx -> vins_to_keys(tx.vin) end)
  def vins_to_keys(vins), do: Enum.map(vins, &key/1)
  
  # Takes a tuple of lists and turns it into a tuple of maps
  defp remap(t), do: Tuple.to_list(t) |> Enum.map(&Map.new/1) |> List.to_tuple
end