defmodule Miner do
  @moduledoc """
  This module defines functions to use when operating a miner in the bitcoin protocol.
  """

  import Crypto
  @tx_buffer 200
  
  @doc """
  Selects transactions from the mempool for inclusion in the new block. If all transactions cannot
  fit in a single block, then transactions are selected in descending fee density (fee/byte).
  """
  @spec select_txs(Mempool.t) :: Mempool.t
  def select_txs(mempool) when mempool == %{}, do: %{}
  def select_txs(mempool) do
    limit = Blockchain.block_size - @tx_buffer
    total = Map.values(mempool) |> Enum.map(fn item -> Transaction.bytes(item.tx) + 2 end) |> Enum.sum
    if total < limit do
      mempool
    else
      Map.to_list(mempool)
      |> Enum.sort_by(fn {_txid, item} -> item.fee/(Transaction.bytes(item.tx) + 2) end, &>=/2)
      |> knapsack(limit)
    end
  end
  defp knapsack(mempool, limit), do: knapsack(mempool, limit, %{})
  defp knapsack(_mempool, 0, items), do: items
  defp knapsack([], _limit, items), do: items
  defp knapsack([{txid, item} | tail], limit, items) do
    size = Transaction.bytes(item.tx) + 2
    if size <= limit do
      knapsack(tail, limit-size, Map.put(items, txid, item))
    else
      knapsack(tail, limit, items)
    end
  end

  @doc """
  Constructs a coinbase transaction based on the blockchain and mempool provided.
  The full coinbase output is directed to the address provided.
  """
  @spec coinbase(Blockchain.t, Mempool.t, KeyAddress.pkh, binary) :: Transaction.t
  def coinbase(bc, mempool, pkh, msg \\ <<>>) do
    value =
      Map.values(mempool)
      |> Enum.map(&Map.get(&1, :fee))
      |> Enum.sum()
      |> Kernel.+(Blockchain.subsidy(bc))
    Transaction.coinbase([Transaction.Vout.new(value, pkh)], msg)
  end

  @doc """
  Constructs a new unverified block on the given blockchain containing the transactions in the given mempool.
  The full coinbase output is directed to the address provided.
  """
  @spec build_block(Blockchain.t, Mempool.t, KeyAddress.pkh, binary) :: Block.t
  def build_block(bc, mempool, pkh, msg \\ <<>>) do
    transactions = [coinbase(bc, mempool, pkh, msg)]
      ++ Enum.map(Map.values(mempool), &Map.get(&1, :tx))
    Block.new(transactions, bc.tip.hash, Blockchain.next_target(bc))
  end

  @doc """
  Mines a new block on the given blockchain containing the transactions in the given mempool.
  The full coinbase output is directed to the address provided.
  """
  @spec build_mine_block(Blockchain.t, KeyAddress.pkh, binary) :: Block.t
  def build_mine_block(bc, pkh, msg \\ <<>>) do
    build_block(bc, select_txs(bc.mempool), pkh, msg)
    |> mine_block(0, 0xffffffff)
  end
  
  @spec mine_block(Block.t, non_neg_integer, pos_integer) :: {:ok, Block.t} | :none
  def mine_block(block, start \\ 0, increment \\ 0xffff) do
    <<stub::binary-76, _::binary>> = Block.Header.serialize(block.header)
    case find_valid_hash(stub, Block.calc_target(block.header.target), start, increment) do
      {:ok, nonce} -> {:ok, Block.update_nonce(block, nonce)}
      :none        -> :none
    end
  end

  @doc """
  Iteratively searches for a valid block hash given a header stub, a difficulty target and a starting nonce.
  A header stub is a serialized header without the nonce bytes (final 4 bytes).
  Returns the nonce that produces the first valid hash.
  """
  @spec find_valid_hash(binary, pos_integer, non_neg_integer, pos_integer) :: {:ok, non_neg_integer} | :none
  def find_valid_hash(_, _, nonce, increment) when nonce > 0xffffffff or increment < 0, do: :none
  def find_valid_hash(stub, target, nonce, increment) do
    hash = sha256x2(stub <> <<nonce::32>>) |> :binary.decode_unsigned
    if hash < target do
      {:ok, nonce}
    else
      find_valid_hash(stub, target, nonce+1, increment-1)
    end
  end
  
  @doc """
  Repeatedly mines blocks until a :halt response is received from the server.
  """
  @spec mining_loop(pid, pid, binary) :: nil
  def mining_loop(node, wallet, msg) do
    with {:ok, bc}    <- Bitcoin.Node.get_mining_data(node),
         {:ok, pkh}   <- Bitcoin.Wallet.get_pkh(wallet),
         block        <- build_block(bc, select_txs(bc.mempool), pkh, msg),
         {:ok, block} <- mine_block(block, :rand.uniform(0xffff0000)-1)
    do
      :ok = GenServer.call(node, {:mined_block, block})
      mining_loop(node, wallet, msg)
    else
      :halt -> nil
      :none -> mining_loop(node, wallet, msg)
    end
  end
end
