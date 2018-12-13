defmodule Block do
  @moduledoc """
  This module defines a full block in the bitcoin protocol. Blocks are
  created by miners. Full nodes in the network will store whole blocks.
  """
  import Bitwise

  @version 1

  defstruct bytes: 0, header: %Block.Header{}, tx_counter: 0, merkle_tree: %MerkleTree{}

  @type t :: %Block{
    bytes:        non_neg_integer,
    header:       Block.Header.t,
    tx_counter:   non_neg_integer,
    merkle_tree:  MerkleTree.t
  }

  @doc """
  Creates a new Block with the provided data.
  Requires a list of transactions, the previous block hash, and a difficulty target. A nonce can also be provided (defaults to 0).
  """
  @spec new([Transaction.t, ...], Crypto.hash256, <<_::32>>, non_neg_integer) :: binary
  def new(transactions, previous_hash, target, nonce \\ 0) do
    merkle_tree = MerkleTree.build_tree(transactions)
    block = %Block{
      header:       Block.Header.new(previous_hash, merkle_tree.root.hash, target, nonce),
      tx_counter:   length(transactions),
      merkle_tree:  merkle_tree
    }
    Map.put(block, :bytes, Block.bytes(block))
  end
  
  @spec update_nonce(t, non_neg_integer) :: t
  def update_nonce(block, nonce), do: Map.update!(block, :header, &Map.put(&1, :nonce, nonce))
  
  @spec hash(t) :: Crypto.sha256
  def hash(block), do: Block.Header.hash(block.header)

  @spec transactions(t) :: [Transaction.t]
  def transactions(block), do: MerkleTree.list_leaves(block.merkle_tree)
  
  @doc """
  Verifies that a block is internally consistent by checking the version number, timestamp, merkle root, and header hash.
  This does NOT verify that a block is valid within a specific blockchain, only that it has been constructed correctly.
  """
  @spec verify(t) :: boolean
  def verify(block) do
    with :ok <- verify_version(block),
         :ok <- verify_timestamp(block),
         :ok <- verify_merkle(block),
         :ok <- verify_hash(block)
    do
      :ok
    else
      error -> error
    end
  end
  defp verify_version(block), do: (if block.header.version == @version, do: :ok, else: {:error, :version})
  defp verify_timestamp(block), do: (if DateTime.diff(block.header.timestamp, DateTime.utc_now) < 5, do: :ok, else: {:error, :timestamp})
  defp verify_merkle(block), do: (if block.merkle_tree.root.hash == block.header.merkle_root, do: :ok, else: {:error, :merkle})
  defp verify_hash(block), do: (if :binary.decode_unsigned(Block.hash(block)) < calc_target(block.header.target), do: :ok, else: {:error, :hash})

  @doc """
  Turns a Block data structure into raw bytes for transmitting and writing to disk.
  """
  @spec serialize(t) :: binary
  def serialize(block) do # This needs to be changed due to removal of transactions field
    Block.Header.serialize(block.header)
      <> <<block.tx_counter::32>>
      <> MerkleTree.serialize(block.merkle_tree)
  end

  @spec deserialize(binary) :: t
  def deserialize(<<header::binary-80, tx_counter::32, tx_data::binary>> = data) do
    %Block{
      bytes:       byte_size(data),
      header:      Block.Header.deserialize(header),
      tx_counter:  tx_counter,
      merkle_tree: MerkleTree.deserialize(tx_data, tx_counter)
    }
  end

  @doc """
  Calculates the difficulty target from the 4-byte representation in the block header. A valid block must have a block hash that is less than this value.
  """
  @spec calc_target(<<_::32>>) :: non_neg_integer
  def calc_target(<<e::8, c::24>>), do: c <<< (8 * (e - 3))
  
  @spec bytes(t) :: non_neg_integer
  def bytes(block), do: Block.Header.bytes + 4 + MerkleTree.bytes(block.merkle_tree)
end
