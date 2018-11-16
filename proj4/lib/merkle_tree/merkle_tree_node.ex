defmodule MerkleTree.Node do
    @moduledoc """
  This module represents a node in the merkle tree.
  """

  defstruct [:hash_value, :height, :children]

  @typedoc """
  A custom type that represents a node in the merkle tree.
  """
  @type t :: %MerkleTree.Node{
    hash_value: String.t,
    height: non_neg_integer,
    children: %{:left => MerkleTree.Node.t, :right => MerkleTree.Node.t}
  }
end