defmodule Block do
  @moduledoc """
  This module defines a full block in the bitcoin protocol. Blocks are
  created by miners. Full nodes in the network will store whole blocks.
  """
  import Crypto
  import Bitwise

  @version 1

  defstruct bytes: 0, header: %Block.Header{}, tx_counter: 0, transactions: [], merkle_tree: %MerkleTree{}

  @type t :: %Block{
    bytes:        non_neg_integer,
    header:       Block.Header.t,
    tx_counter:   non_neg_integer,
    transactions: [Transaction.t, ...],
    merkle_tree:  MerkleTree.t
  }

  @doc """
  Creates a new Block with the provided data.
  Requires a list of transactions, the previous block hash, and a difficulty target. A nonce can also be provided (defaults to 0).
  """
  @spec new([Transaction.t, ...], Crypto.hash256, <<_::32>>, non_neg_integer) :: binary
  def new(transactions, previous_hash, target, nonce \\ 0) do
    merkle_tree = MerkleTree.build_tree(transactions)
    %Block{
      bytes:        4 * (length(transactions) + 1) + Block.Header.bytes + Enum.reduce(transactions, 0, &(&2 + Transaction.bytes(&1))),
      header:       Block.Header.new(previous_hash, merkle_tree.root.hash, target, nonce),
      tx_counter:   length(transactions),
      transactions: transactions,
      merkle_tree:  merkle_tree
    }
  end

  @doc """
  Verifies that a block is internally consistent by checking the version number, timestamp, merkle root, and header hash.
  This does NOT verify that a block is valid within a specific blockchain, only that it has been constructed correctly.
  """
  @spec verify(t) :: boolean
  def verify(block) do
    verify_version(block)
      and verify_timestamp(block)
      and verify_merkle(block)
      and verify_hash(block)
  end
  defp verify_version(block), do: block.version == @version
  defp verify_timestamp(block), do: DateTime.diff(DateTime.utc_now, block.timestamp) > 7200
  defp verify_merkle(block), do: block.merkle_tree.root.hash == block.header.merkle_root
  defp verify_hash(block), do: Block.Header.block_hash(block.header) < calc_target(block.header.target)

  @doc """
  Turns a Block data structure into raw bytes for transmitting and writing to disk.
  """
  @spec serialize(t) :: binary
  def serialize(block) do
    Block.Header.serialize(block.header)
      <> <<block.tx_counter::32>>
      <> Enum.reduce(Enum.reverse(block.transactions), <<>>, fn tx, acc ->
           bytes = Transaction.bytes(tx)
           <<bytes::32>> <> Transaction.serialize(tx) <> acc
         end)
  end

  # To be implemented
  def deserialize(data)

  @doc """
  Calculates the difficulty target from the 4-byte representation in the block header. A valid block must have a block hash that is less than this value.
  """
  @spec calc_target(<<_::32>>) :: non_neg_integer
  def calc_target(<<e::8, c::24>>), do: c <<< (8 * (e - 3))
end
