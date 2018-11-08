defmodule MerkleTree do
  @moduledoc """
  This module represents a merkle tree which produces the root hash stored in a
  block in the bitcoin bloackchain. A merkle tree is a data structure represented
  as a binary tree with hashes. The merkle tree consists of the hashes of transactions
  as leaf nodes, which in turn are hashed to create internal nodes in the tree structure.
  The root hash of the tree resides on the top-level of the tree. Transactions can be
  validated as a part of the tree through building the merkle path up to the root hash.

  """

  defstruct [:root]

  @spec hash(String.t) :: String.t
  defp hash(data) do
    :crypto.hash(:sha, data) |> Base.encode16(case: :lower)
  end

  @spec makeMerkle([String.t]) :: %{non_neg_integer => [String.t]}
  def makeMerkle(transactions) do
    tree = %{}
    transactions
    |> Enum.chunk_every(2)
    |> Enum.map(fn [t1,t2] -> hash(t1 <> t2) end)
  end


end
