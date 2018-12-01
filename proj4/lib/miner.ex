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

  import Crypto
  import KeyAddress

  @spec coinbase(Blockchain.t, Mempool.t, KeyAddress.pkh, binary) :: Transaction.t
  def coinbase(bc, mempool, pkh, msg \\ 0) do
    value =
      Map.values(mempool)
      |> Enum.map(&Map.get(&1, :fee))
      |> Enum.sum()
      |> Kernel.+(Blockchain.subsidy(bc))
    Transaction.coinbase(msg, [Transaction.Vout.new(value, pkh)])
  end

  @spec build_block(Blockchain.t, Mempool.t, KeyAddress.pkh, binary) :: Block.t
  def build_block(bc, mempool, pkh, msg \\ 0) do
    transactions = [coinbase(bc, mempool, pkh, msg)]
      ++ Enum.map(Map.values(mempool), &Map.get(&1, :tx))
    Block.new(transactions, bc.tip.hash, Blockchain.next_target(bc))
  end

  @spec mine_block(Blockchain.t, Mempool.t, KeyAddress.pkh, binary) :: Block.t
  def mine_block(bc, mempool, pkh, msg \\ 0) do
    block = build_block(bc, mempool, pkh, msg)
    {:ok, nonce} = find_valid_hash(Block.Header.serialize(block.header), Blockchain.next_target(bc), 0)
    Block.update_nonce(block, nonce)
  end

  @spec find_valid_hash(binary, binary, non_neg_integer) :: {:ok, non_neg_integer} | :error
  def find_valid_hash(header, target, nonce) do end


end
