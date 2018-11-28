defmodule MerkleTree.Leaf do
  import Crypto

  defstruct [:hash, :tx]

  @type t :: %MerkleTree.Leaf{
    hash: Crypto.hash256,
    tx:   Transaction.t
  }

  def new(nil), do: nil
  def new(tx), do: %MerkleTree.Leaf{hash: Transaction.hash(tx), tx: tx}
end
