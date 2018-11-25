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
    data = data |> Enum.map(fn(x) -> endian_converter(x) end) |> Enum.reduce(fn(x,acc) -> acc <> x end)
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
      timestamp: Application.get_env(:proj4, :timestamp),#:os.system_time(:seconds),
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
  This function sets a new difficulty for the block and returns a new block.
  """
  @spec setDifficulty(Block.t, non_neg_integer) :: Block.t
  def setDifficulty(block, new_diff) do
    header = block.block_header
    newHeader = %Block.BlockHeader{
      version: header.version,
      previous_hash: header.previous_hash,
      merkle_root: header.merkle_root,
      timestamp: header.timestamp,
      difficulty: new_diff,
      nonce: header.nonce
    }
    newSize = integer_size(new_diff) - integer_size(header.difficulty)
    %Block{
      block_size: if newSize != 0 do block.block_size + newSize else block.block_size end,
      block_header: newHeader,
      tx_counter: block.tx_counter,
      transactions: block.transactions
    }
  end

  @spec setNonceInHeader(Block.BlockHeader.t, non_neg_integer) :: Block.BlockHeader.t
  def setNonceInHeader(header, new_nonce) do
    %Block.BlockHeader{
      version: header.version,
      previous_hash: header.previous_hash,
      merkle_root: header.merkle_root,
      timestamp: header.timestamp,
      difficulty: header.difficulty,
      nonce: new_nonce
    }
  end

  @doc """
  This function sets a new nonce for the block and returns a new block.
  """
  @spec setNonce(Block.t, non_neg_integer) :: Block.t
  def setNonce(block, new_nonce) do
    header = block.block_header
    newHeader = setNonceInHeader(header, new_nonce)
    newSize = integer_size(new_nonce) - integer_size(header.nonce)
    %Block{
      block_size: if newSize != 0 do block.block_size + newSize else block.block_size end,
      block_header: newHeader,
      tx_counter: block.tx_counter,
      transactions: block.transactions
    }
  end

  @doc """
  A function which verifies a block. This is done by computing the block hash with
  the nonce and compare with the provided block hash as well as comparing to set difficulty.
  Additionally, the merkle root is calculated for all the transactions included in the block
  and compared with. This functionality will mainly be used by full nodes in the network,
  namely miners. Caller can specify how many criterias are of interest for verification.
  A full node or miner would check all conditions.
  """
  @spec verifyBlock(Block.t, BLock.BlockHeader.t, String.t) :: Boolean.t
  def verifyBlock(block \\ nil, header, response_hash, mode \\ [:diff, :block, :merkle]) do
    if Enum.member?(mode, :diff) do
      difficulty = header.difficulty |> endian_converter() |> String.pad_trailing(64, "0")
      unless response_hash |> String.to_integer(16) <= difficulty |> String.to_integer(16), do: raise Block.DiffError
    end

    if Enum.member?(mode, :block) do
      calculated_hash = generate_block_hash(header)
      unless calculated_hash == response_hash, do: raise Block.BlockHashError
    end

    if Enum.member?(mode, :merkle) && block != nil do
      tree = MerkleTree.makeMerkle(block.transactions)
      unless tree.root.hash_value == header.merkle_root, do: raise Block.MerkleRootError
    end
    true
  end

end
