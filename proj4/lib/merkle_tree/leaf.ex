defmodule MerkleTree.Leaf do
  import Crypto
  @moduledoc """
  This module specifies a merkle tree leaf which is an edge node in the merkle tree.
  """
  defstruct [:hash, :tx]

  @type t :: %MerkleTree.Leaf{
    hash: Crypto.hash256,
    tx:   Transaction.t
  }

  def new(nil), do: nil
  def new(tx), do: %MerkleTree.Leaf{hash: Transaction.hash(tx), tx: tx}
end
