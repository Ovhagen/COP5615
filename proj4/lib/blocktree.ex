defmodule Blocktree do
  @moduledoc """
  This module defines data structures and functions to manage multiple blockchain branches
  originating from a single genesis block (i.e. forks).
  
  The mainchain is the longest chain; if two chains have equal height then the first one to reach that
  height is considered the mainchain. A fork is any other chain which shares the same genesis block but
  has a different tip. Forks are discarded once their height is a certain depth below the mainchain; the
  default depth is 6 blocks.
  """
  
  @active_depth 6
  
  defstruct mainchain: %Blockchain{}, forks: []
  
  @type t :: %Blocktree{
    mainchain: Blockchain.t,
    forks:     [Blockchain.t]
  }
  
  @doc """
  Creates a new Blocktree starting from the genesis block.
  """
  @spec genesis() :: t
  def genesis(), do: new(Blockchain.genesis)
  
  @doc """
  Creates a new Blocktree from the given mainchain.
  """
  @spec new(Blockchain.t) :: t
  def new(bc) do
    %Blocktree{
      mainchain: bc,
      forks:     [bc]
    }
  end
  
  @doc """
  Returns true if there are any active forks, false otherwise.
  """
  @spec forked?(t) :: boolean
  def forked?(bt), do: length(bt.forks) > 1
  
  @doc """
  Attempts to add a new block to each active fork (including the mainchain).
  Returns :ok if the block was successfully added to any chain, and an error otherwise.
  """
  @spec add_block(t | Blockchain.t | [Blockchain.t, ...], Block.t) :: t
  def add_block(%Blocktree{} = bt, block) do
    case add_block(bt.forks, block, bt.mainchain.tip.height-@active_depth) do
      {:ok, bc}   -> update_fork(bt, bc) |> purge_old_forks
      {:fork, bc} -> add_fork(bt, bc)
      error       -> error
    end
  end
  defp add_block([], _block, _limit), do: {:error, :orphan}
  defp add_block([bc | tail], block, limit) do
    case add_block(bc, block, limit) do
      {:error, :orphan}  -> add_block(tail, block, limit)
      {:error, error}    -> {:error, error}
      result             -> result
    end
  end
  defp add_block(bc, block, limit), do: add_block(bc, bc.tip, block, 0, bc.tip.height-limit)
  defp add_block(_bc, _link, _block, depth, limit) when depth > limit, do: {:error, :orphan}
  defp add_block(bc, link, block, depth, limit) do
    cond do
      link.hash == Block.hash(block)          -> {:error, :duplicate}
      link.hash == block.header.previous_hash ->
        with bc        <- rewind_blocks(bc, depth),
             {:ok, bc} <- Blockchain.add_block(bc, block)
        do
          bc = purge_mempool(bc)
          if depth == 0, do: {:ok, bc}, else: {:fork, bc}
        else
          error -> error
        end
      link.height == 0                        -> {:error, :orphan}
      true                                    -> add_block(bc, link.prev, block, depth+1, limit)
    end
  end
  
  defp rewind_blocks(bc, 0), do: bc
  defp rewind_blocks(bc, depth) do
    txs = Block.transactions(bc.tip.block)
    utxo_keys = Blockchain.UTXO.txs_to_keys(txs)
    Map.update!(bc, :utxo, fn utxo ->
        Map.drop(utxo, utxo_keys)
        |> Map.update!(:index, &Map.drop(&1, Transaction.hash(txs)))
        |> Blockchain.UTXO.merge(Blockchain.UTXO.unspend(bc.tip.stxo))
      end)
    |> Blockchain.add_to_mempool(tl(txs))
    |> elem(1)
    |> Map.update!(:tip, fn tip -> tip.prev end)
    |> rewind_blocks(depth-1)
  end
  
  defp purge_mempool(bc) do
    Map.put(bc, :mempool, Enum.filter(bc.mempool, fn {_txid, item} ->
        Enum.all?(Blockchain.UTXO.vins_to_keys(item.tx.vin), &(&1 in bc.utxo))
      end)
      |> Map.new)
  end
  
  defp update_fork(bt, bc) do
    bt = Map.update!(bt, :forks, &Enum.map(&1, fn fork ->
        if bc.tip.prev.hash == fork.tip.hash, do: bc, else: fork
      end))
    if bc.tip.height > bt.mainchain.tip.height, do: Map.put(bt, :mainchain, bc), else: bt
  end
  
  defp add_fork(bt, bc), do: Map.update!(bt, :forks, &(&1 ++ [bc]))
  
  defp purge_old_forks(bt) do
    Map.update!(bt, :forks, &Enum.reject(&1, fn bc -> bc.tip.height < bt.mainchain.tip.height - @active_depth end))
  end
end