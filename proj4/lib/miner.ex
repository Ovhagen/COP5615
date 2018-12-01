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
  
  @spec coinbase(Mempool.t, ) :: Transaction.t
  def coinbase() do

  def hash_and_verify(header, nonce) do
    header = Block.setNonceInHeader(header, nonce)
    block_hash = Block.generate_block_hash(header)
    try do
      hash = Block.verifyBlock(nil, header, block_hash, [:diff])
      {:ok, nonce, hash}
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
    results = nonce..nonce+rounds
    |> Enum.to_list()
    |> Task.async_stream(&(hash_and_verify(block.block_header, &1))) |> Enum.map(fn x -> x end) |> Enum.map(fn ({:ok, p})-> if elem(p, 0) == :ok do {elem(p,1), elem(p,2)} end end)
  end

  def generate_block(transactions, prev_hash, nonce) do
    #Check that transactions have available balance
    #Collect fees
    #Include coinbase transaction
    tree = MerkleTree.makeMerkle(transactions)
    Block.createBlock(transactions, tree.root.hash_value, prev_hash, nonce)
  end

end
