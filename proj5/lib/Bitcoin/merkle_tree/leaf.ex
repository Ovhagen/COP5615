defmodule MerkleTree.Leaf do
  @moduledoc """
  This module specifies a merkle tree leaf which is an edge node in the merkle tree.
  """
  defstruct [:hash, :tx]

  @type t :: %MerkleTree.Leaf{
    hash: Crypto.hash256,
    tx:   Transaction.t | nil
  }

  @spec new(Transaction.t | Crypto.hash256 | nil) :: t | nil
  def new(nil), do: nil
  def new(<<hash::binary-32>>), do: %MerkleTree.Leaf{hash: hash, tx: nil}
  def new(tx), do: %MerkleTree.Leaf{hash: Transaction.hash(tx), tx: tx}
  
  def get_data(leaf), do: leaf.tx
  
  def serialize(leaf), do: <<Transaction.bytes(leaf.tx)::16>> <> Transaction.serialize(leaf.tx)
  
  def bytes(leaf), do: 2 + Transaction.bytes(leaf.tx)
end
