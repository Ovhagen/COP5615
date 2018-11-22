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
  A list containing all the transactions included in the block.
  """
  @type transactions :: [String.t, ...]
  @type t :: %Block{
      block_size: block_size,
      block_header: block_header,
      tx_counter: tx_counter,
      transactions: transactions
  }

  @spec double_hash(String.t) :: String.t
  def double_hash(data) do
    thedata = <<Integer.parse(data, 16)|> elem(0)::640>>
    h1 = :crypto.hash(:sha256, thedata)
    :crypto.hash(:sha256, h1) |> Base.encode16(case: :lower)
  end

  @doc """
  Generates the block hash with the block header. Each parameter is converted
  to little endian and concatenated to form a large string parameter. This
  parameter is the hashed twice and converted to little endian.
  """
  @spec generate_block_hash(Block.BlockHeader.t) :: String.t
  def generate_block_hash(header) do
    data = [
      header.version,
      header.previous_hash,
      header.merkle_root,
      header.timestamp,
      header.difficulty,
      header.nonce]
    data = data |> Enum.map(fn(x) -> endian_converter(x) end)  |> Enum.reduce(fn(x,acc) -> acc <> x end)
    double_hash(data) |> endian_converter()
  end

  @doc """
  Converts the input of either an integer or a string to a binary representation in little endian.
  """
  defp endian_converter(data) do
    if(is_integer(data)) do
      <<data::32>>
      |> :binary.decode_unsigned(:little)
      |> Integer.to_string(16)
      |> String.pad_leading(8, "0")
      |> String.downcase()
    else
      <<Integer.parse(data, 16) |> elem(0)::256>>
      |> :binary.decode_unsigned(:little)
      |> Integer.to_string(16)
      |> String.pad_leading(64, "0")
      |> String.downcase()
    end
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
      previous_hash: List.to_string(prev_hash),
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
  Additionally, the merkle root is calculated for all the transactions included in the block
  and compared with. This functionality will mainly be used by full nodes in the network,
  namely miners.
  Either a basic verification is done, which checks difficulty and the block hash.
  Or a full verification is performed, which further calculates and checks the merkle root. (only done by full nodes)
  """
  @spec verifyBlock(Block.t, String.t) :: Boolean.t
  def verifyBlock(block, response_hash, mode \\ :basic) do
    header = block.block_header
    difficulty = header.difficulty
    unless difficulty <= response_hash, do: raise Block.DiffError

    calculated_hash = generate_block_hash(header)
    unless calculated_hash == response_hash, do: raise Block.BlockHashError

    if mode == :full do
      tree = MerkleTree.makeMerkle(block.transactions)
      unless tree.root.hash_value == header.merkle_root, do: raise Block.MerkleRootError
    end
    true
  end

end
