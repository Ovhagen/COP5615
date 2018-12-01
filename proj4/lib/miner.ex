defmodule Miner do
  @moduledoc """
  This module defines functions to use when operating a miner in the bitcoin protocol.
  """

  import Crypto
  import KeyAddress

  @doc """
  Constructs a coinbase transaction based on the blockchain and mempool provided.
  The full coinbase output is directed to the address provided.
  """
  @spec coinbase(Blockchain.t, Mempool.t, KeyAddress.pkh, binary) :: Transaction.t
  def coinbase(bc, mempool, pkh, msg \\ 0) do
    value =
      Map.values(mempool)
      |> Enum.map(&Map.get(&1, :fee))
      |> Enum.sum()
      |> Kernel.+(Blockchain.subsidy(bc))
    Transaction.coinbase(msg, [Transaction.Vout.new(value, pkh)])
  end

  @doc """
  Constructs a new unverified block on the given blockchain containing the transactions in the given mempool.
  The full coinbase output is directed to the address provided.
  """
  @spec build_block(Blockchain.t, Mempool.t, KeyAddress.pkh, binary) :: Block.t
  def build_block(bc, mempool, pkh, msg \\ 0) do
    transactions = [coinbase(bc, mempool, pkh, msg)]
      ++ Enum.map(Map.values(mempool), &Map.get(&1, :tx))
    Block.new(transactions, bc.tip.hash, Blockchain.next_target(bc))
  end

  @doc """
  Mines a new block on the given blockchain containing the transactions in the given mempool.
  The full coinbase output is directed to the address provided.
  """
  @spec mine_block(Blockchain.t, Mempool.t, KeyAddress.pkh, binary) :: Block.t
  def mine_block(bc, mempool, pkh, msg \\ 0) do
    block = build_block(bc, mempool, pkh, msg)
    <<stub::binary-76, _::binary>> = Block.Header.serialize(block.header)
    {:ok, nonce} = find_valid_hash(stub, Block.calc_target(block.header.target), 0)
    Block.update_nonce(block, nonce)
  end

  @doc """
  Iteratively searches for a valid block hash given a header stub, a difficulty target and a starting nonce.
  A header stub is a serialized header without the nonce bytes (final 4 bytes).
  Returns the nonce that produces the first valid hash.
  """
  @spec find_valid_hash(binary, pos_integer, non_neg_integer) :: {:ok, non_neg_integer} | :error
  def find_valid_hash(_, _, nonce) when nonce > 0xffffffff, do: :error
  def find_valid_hash(stub, target, nonce) do
    if sha256x2(stub <> <<nonce::32>>) < target do
      {:ok, nonce}
    else
      find_valid_hash(stub, target, nonce+1)
    end
  end
end
