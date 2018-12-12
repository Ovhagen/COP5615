defmodule Blockchain do
  import Bitwise
  
  @coin 1_000_000
  @interval_target 5
  @block_size 50_000

  defmodule Mempool do
    defstruct tx: %Transaction{}, fee: 0
    @type t :: %{required(Crypto.hash256) => %Mempool{}}

    @spec insert(t, Transaction.t, non_neg_integer) :: t
    def insert(mempool, tx, fee), do: Map.put(mempool, Transaction.hash(tx), %Mempool{tx: tx, fee: fee})
    
    @spec delete(t, Transaction.t | [Transaction.t, ...]| Crypto.hash256 | [Crypto.hash256, ...]) :: t
    def delete(mempool, txs) when is_list(txs), do: Enum.reduce(txs, mempool, &delete(&2, &1))
    def delete(mempool, tx) when not is_binary(tx), do: delete(mempool, Transaction.hash(tx))
    def delete(mempool, tx), do: Map.delete(mempool, tx)
  end

  defstruct tip: %Blockchain.Link{}, utxo: %{}, mempool: %{}

  @type t :: %Blockchain{
    tip:     Blockchain.Link.t,
    utxo:    Blockchain.UTXO.t,
    mempool: Mempool.t
  }

  @spec verify_tx(t, Transaction.t) :: {:ok, non_neg_integer} | {:error, atom}
  def verify_tx(bc, tx) do
    with true        <- Transaction.verify(tx),
         {:ok, vout} <- get_utxo(bc.utxo, tx.vin),
         :ok         <- verify_pkh(vout, tx.vin),
         fee         <- Transaction.fee(vout, tx.vout)
    do
      if fee > 0, do: {:ok, fee}, else: {:error, :fee}
    else
      false -> {:error, :sig}
      error -> error
    end
  end

  def get_utxo(utxo, vin) do
    Enum.reduce_while(vin, {:ok, []}, fn vin, {:ok, acc} ->
      case Map.fetch(utxo, {vin.txid, vin.vout}) do
        {:ok, %Blockchain.UTXO{vout: vout, spent_by: nil}} -> {:cont, {:ok, acc ++ [vout]}}
        {:ok, %Blockchain.UTXO{spent_by: _txid}}           -> {:halt, {:error, :spent}}
        :error                                             -> {:halt, {:error, :utxo}}
      end
    end)
  end

  def verify_pkh(vout, vin) do
    Enum.zip(vout, vin)
    |> Enum.reduce_while(:ok, fn {vo, vi}, _ ->
         if vo.pkh == KeyAddress.pubkey_to_pkh(vi.witness.pubkey) do
           {:cont, :ok}
         else
           {:halt, {:error, :pkh}}
         end
       end)
  end

  @spec add_to_mempool(t, Transaction.t | [Transaction.t]) :: {:ok, t} | {:error, atom}
  def add_to_mempool(bc, txs) when is_list(txs) do
    Enum.reduce(txs, {:ok, bc}, fn tx, {:ok, bc} ->
      case add_to_mempool(bc, tx) do
        {:ok, bc} -> {:ok, bc}
        _error     -> {:ok, bc}
      end
    end)
  end
  def add_to_mempool(bc, tx) do
    with {:ok, fee} <- verify_tx(bc, tx) do
      {
        :ok,
        Map.update!(bc, :utxo, &Blockchain.UTXO.spend(&1, tx))
          |> Map.update!(:mempool, &Mempool.insert(&1, tx, fee))
      }
    else
      error -> error
    end
  end
  
  @spec remove_from_mempool(t, Transaction.t | [Transaction.t, ...] | Crypto.hash256 | [Crypto.hash256, ...]) :: t
  def remove_from_mempool(bc, tx) when not is_list(tx), do: remove_from_mempool(bc, [tx])
  def remove_from_mempool(bc, txids) when is_binary(hd(txids)) do
    remove_from_mempool(bc, Enum.map(txids, &Map.get(Map.get(bc.mempool, &1), :tx)), txids)
  end
  def remove_from_mempool(bc, txs), do: remove_from_mempool(bc, txs, Enum.map(txs, &Transaction.hash/1))
  defp remove_from_mempool(bc, txs, txids) do
    {stxo, utxo} = Map.split(bc.utxo, Blockchain.UTXO.txs_to_keys(txs))
    utxo = Blockchain.UTXO.merge(utxo, Blockchain.UTXO.unspend(stxo))
    Map.put(bc, :utxo, utxo)
    |> Map.update!(:mempool, &Mempool.delete(&1, txids))
  end

  @doc """
  Adds a valid block to the chain.
  The block is verified with three possible outcomes:
    1. The block is valid and all transactions are in the mempool.
         In this case, the block is added to the chain, and the UTXO and mempool are updated.
    2. The block may be valid, but some transactions are not in the mempool.
         The transactions which are not in the mempool are checked for validity. If there are conflicts,
         then each conflicting transaction is checked and swapped into the mempool if possible. If each of these
         steps is completed without errors, then the block is checked from the beginning again.
    3. The block is not valid.
         An error is returned which indicates the type of error which invalidated the block.
  """
  @spec add_block(t, Block.t) :: {:ok, t} | {:error, atom}
  def add_block(bc, block) do
    with :ok <- verify_block(bc, block) do
      {utxo, stxo} = Blockchain.UTXO.update(bc.utxo, bc.tip.height+1, Block.transactions(block))
      link = Blockchain.Link.new(block, bc.tip, stxo)
      {
        :ok,
        Map.put(bc, :tip, link)
          |> Map.put(:utxo, utxo)
          |> Map.update!(:mempool, &Mempool.delete(&1, Block.transactions(block) |> tl))
      }
    else
      {:mempool, txs} ->
        with {:ok, bc, conflicts} <- update_with_conflicts(bc, txs),
             {:ok, bc}            <- resolve_conflicts(bc, block, conflicts)
        do
          add_block(bc, block)
        else
          error -> error
        end
      error -> error
    end
  end
  defp update_with_conflicts(bc, txs) do
    Enum.reduce_while(txs, {:ok, bc, []}, fn tx, {:ok, bc, conflicts} ->
      case add_to_mempool(bc, tx) do
        {:ok, bc}        -> {:cont, {:ok, bc, conflicts}}
        {:error, :spent} -> {:cont, {:ok, bc, [tx] ++ conflicts}}
        error            -> {:halt, error}
      end
    end)
  end
  defp resolve_conflicts(bc, _block, []), do: {:ok, bc}
  defp resolve_conflicts(bc, block, txs) do
    block_ids = Enum.map(Block.transactions(block), &Transaction.hash/1)
    with {:ok, conflicts} <- id_conflicts(bc.utxo, block_ids, txs),
         conflicts        <- Enum.uniq(conflicts)
    do
      remove_from_mempool(bc, conflicts) |> add_to_mempool(txs)
    else
      error -> error
    end
  end
  defp id_conflicts(utxo, ids, txs) do
    Enum.flat_map(txs, fn tx -> tx.vin end)
    |> Enum.reduce_while({:ok, []}, fn vin, {:ok, txids} ->
         utxo = Map.get(utxo, {vin.txid, vin.vout})
         cond do
           utxo.spent_by in ids -> {:halt, {:error, :double_spend}}
           utxo.spent_by == nil -> {:cont, {:ok, txids}}
           true                 -> {:cont, {:ok, [utxo.spent_by] ++ txids}}
         end
       end)
  end
  
  @spec verify_block(t, Block.t) :: :ok | {:error, atom}
  def verify_block(bc, block) do
    with :ok         <- Block.verify(block),
         :ok         <- verify_size(block),
         :ok         <- verify_tip(bc, block),
         :ok         <- verify_target(bc, block),
         {:ok, fees} <- verify_mempool(bc, block),
         :ok         <- verify_coinbase(bc, block, fees)
    do
      :ok
    else
      error -> error
    end
  end
  defp verify_size(block), do: (if block.bytes <= @block_size, do: :ok, else: {:error, :size})
  defp verify_tip(bc, block) do
    if block.header.previous_hash == bc.tip.hash, do: :ok, else: {:error, :tip}
  end
  defp verify_target(bc, block) do
    if block.header.target == next_target(bc), do: :ok, else: {:error, :target}
  end
  defp verify_mempool(bc, block) do
    Enum.reduce(tl(Block.transactions(block)), {:ok, 0}, fn
      tx, {:ok, fees} ->
        if Transaction.hash(tx) in Map.keys(bc.mempool) do
          fee = Map.get(bc.mempool, Transaction.hash(tx))
            |> Map.get(:fee)
          {:ok, fees + fee}
        else
          {:mempool, [tx]}
        end
      tx, {:mempool, txs} ->
        if Transaction.hash(tx) in Map.keys(bc.mempool), do: {:mempool, txs}, else: {:mempool, txs ++ [tx]}
    end)
  end
  defp verify_coinbase(bc, block, fees) do
    with coinbase      <- hd(Block.transactions(block)),
         {:ok, value}  <- Transaction.verify_coinbase(coinbase)
    do
      if value == fees + Blockchain.subsidy(bc), do: :ok, else: {:error, :value}
    else
      error -> error
    end
  end
  
  @spec trim_spent_tx(t) :: t
  def trim_spent_tx(bc) do
    {utxo, spent} = Blockchain.UTXO.trim(bc.utxo)
    txs = Map.values(spent)
      |> Enum.reduce(%{}, &Map.update(&2, Map.get(&1, :block), [Map.get(&1, :pos)], fn list -> [Map.get(&1, :pos)] ++ list end))
      |> Map.to_list
      |> Enum.sort_by(&elem(&1, 0), &>=/2)
    trim_spent_tx(bc, txs)
    |> Map.put(:utxo, utxo)
  end
  defp trim_spent_tx(%Blockchain{} = bc, txs), do: Map.put(bc, :tip, trim_spent_tx(bc.tip, txs))
  defp trim_spent_tx(%Blockchain.Link{height: h} = link, [{b, _} | _] = txs) when b < h, do: Map.put(link, :prev, trim_spent_tx(link.prev, txs))
  defp trim_spent_tx(%Blockchain.Link{height: h} = link, [{b, txs} | tail]) when b == h do
    Map.update!(link, :block, fn block ->
      Enum.reduce(txs, block.merkle_tree, &MerkleTree.trim_tx(&2, &1))
    end)
    |> Map.put(:prev, trim_spent_tx(link.prev, tail))
  end
  
  @spec get_block_by_height(t, non_neg_integer) :: Block.t
  def get_block_by_height(bc, height), do: get_relative_block(bc.tip, bc.tip.height - height)
  defp get_relative_block(tip, offset) when offset < 1, do: tip.block
  defp get_relative_block(tip, offset), do: get_relative_block(tip.prev, offset-1)
  
  @spec subsidy(t) :: non_neg_integer
  def subsidy(bc), do: trunc(50 * @coin * :math.exp(-bc.tip.height/6000))

  @spec next_target(t) :: <<_::32>>
  def next_target(%Blockchain{tip: %Blockchain.Link{height: h}} = bc) when h > 0 do
    <<exponent::8, mantissa::24>> = bc.tip.block.header.target
    interval = DateTime.diff(bc.tip.block.header.timestamp, bc.tip.prev.block.header.timestamp)
    mantissa = mantissa * (1 + 0.002 * (interval - @interval_target)) |> trunc
    shift = min(max(mantissa - (8 <<< 20), 0), 1) + max(min(mantissa - (8 <<< 4), 0), -1)
    exponent = exponent + shift
    mantissa = mantissa >>> (shift*8)
    <<exponent::8, mantissa::24>>
  end
  def next_target(bc), do: bc.tip.block.header.target

  @spec genesis() :: t
  def genesis() do
    {pubkey, _privkey} = KeyAddress.keypair(1337)
    msg = "01/Dec/2018 P Ovhagen and J Howes"
    coinbase = Transaction.coinbase([Transaction.Vout.new(1_000_000_000, KeyAddress.pubkey_to_pkh(pubkey))], msg)
    block = Block.new([coinbase], <<0::256>>, <<0x1f004000::32>>)
    %Blockchain{
      tip: %Blockchain.Link{
          block:  block,
          hash:   Block.hash(block),
          prev:   nil,
          height: 0,
          stxo:   Blockchain.UTXO.new
        },
      utxo: Blockchain.UTXO.from_tx(coinbase)
    }
  end
end
