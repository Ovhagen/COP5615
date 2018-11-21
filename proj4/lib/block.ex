defmodule Block do
    @moduledoc """
  This module defines a full block in the bitcoin protocol. Blocks are
  created by miners. Full nodes in the network will store whole blocks.

  The member Magic number is omitted in this implementation.
  """

  defstruct [:block_size, :block_header, :tx_counter, :transactions]

  @typedoc """
  The total size calculated on the block.
  """
  @type block_size :: non_neg_integer
  @typedoc """
  An array containing all the transactions included in the block.
  """
  @type block_header :: Block.BlockHeader.t
  @typedoc """
  A counter for the amount of transactions included in the block.
  """
  @type tx_counter :: non_neg_integer
  @typedoc """
  An list containing all the transactions included in the block.
  """
  @type transactions :: [String.t, ...]
  @type t :: %Block{
      block_size: block_size,
      block_header: block_header,
      tx_counter: tx_counter,
      transactions: transactions
  }

  @doc """
  Hash function for creating block hashes from block data.
  Uses SHA256 hash alogrithm.
  """
  @spec hash(Block.t) :: String.t
  def hash(data) do
    :crypto.hash(:sha256, data) |> Base.encode16(case: :lower)
  end

  @doc """
  Outputs the size of an integer in bytes.
  """
  @spec integer_size(Integer.t) :: Integer.t
  defp integer_size(nbr) do
    byte_size(:binary.encode_unsigned(nbr))
  end

  @doc """
  Calculates the byte size of a block header
  """
  @spec calculate_header_size(Block.BlockHeader.t) :: Integer.t
  defp calculate_header_size(header) do
    header_size = 1 + 64 + 64 + integer_size(header.timestamp) + integer_size(header.difficulty) + integer_size(header.nonce)
    header_size
  end

  @doc """
  This function creates a block. In the bitcoin protocol
  blocks are explicitly created by miners. A block will then
  be accepted into the new chain if the block hash is validated
  by the rest of the network.
  """
  @spec createBlock([String.t, ...], String.t, String.t, non_neg_integer) :: Block.t
  def createBlock(transactions, merkle_root, prev_hash, nonce) do
    block_header = %Block.BlockHeader{
      version: Application.get_env(:proj4, :block_version),
      previous_hash: prev_hash,
      merkle_root: merkle_root,
      timestamp: :os.system_time(:seconds),
      difficulty: Application.get_env(:proj4, :block_difficulty),
      nonce: nonce
    }
    tx_counter = length(transactions)
    tx_size = transactions |> Enum.map(&(byte_size(&1))) |> Enum.sum()
    block_size = calculate_header_size(block_header) + integer_size(tx_counter) + tx_size
    %Block{
      block_size: block_size,
      block_header: block_header,
      tx_counter: tx_counter,
      transactions: transactions
    }
  end

  @doc """
  A function which verifies a block. This is done by computing the block hash with
  the nonce and compare with the provided block hash as well as comparing to set difficulty.
  Also, the time of creation can't be earlier than previous block. Additionally, the merkle
  root is calculated for all the transactions included in the block. This functionality will
  mainly be used by full nodes in the network or miners.
  """
  def verifyBlock() do

  end

end
