defmodule Miner do
  @moduledoc """
  This module defines functions to use when operating a miner in the bitcoin protocol.
  Miners collect transactions, with free priority, and produces blocks by trying to reach a qualified block hash.
  A miner will only include transaction which has available balance on them. When a block hash has been found which
  matches the global difficulty, it will then broadcast the block to the rest of the network.
  When a block has been confirmed by the network, the miner will effectively have received some bitcoin due to the
  inclusion of his own coinbase transaction.
  """

  #TODO Implement hashing for mining with nonce incremental etc.
  # (needs to be able to stop in mid-calculations and return nonce. So miner can check other blocks in the network.)
  #TODO Implement transaction viability by confirming amounts available on wallets
  #TODO Implement further verification.
  #TODO A miner should hold active lists of block (as well as chains?) when it decides where to put its hashing power.
  #TODO fee priority

  def hash_and_verify(header, nonce) do
    header = Block.setNonceInHeader(header, nonce)
    block_hash = Block.generate_block_hash(header)
    try do
      Block.verifyBlock(header, [:diff])
      {:ok, nonce}
    rescue
      Block.DiffError -> {:failed, nonce}
    end
  end

  @doc """
  Starts process of mining by trying to create a valid block hash.
  Returns the
  """
  @spec mine_block(Block.t, non_neg_integer, non_neg_integer) :: {Boolean.t, Block.t, String.t}
  def mine_block(block, nonce, rounds) do
    nonce..nonce+rounds
    |> Enum.to_list()
    |> Task.async_stream(&(hash_and_verify(block.block_header, &1)), []) |> Enum.map(fn x -> x end) |> IO.inspect
  end

  def generate_block() do
    #Check that transactions have available balance
    #Include coinbase transaction
  end

end
