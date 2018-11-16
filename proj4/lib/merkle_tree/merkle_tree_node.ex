defmodule MerkleTree.Node do

  defstruct [:hash_value, :height, :children]

  @typedoc """
  A custom type that represents a node in the merkle tree.
  """
  @type t :: %MerkleTree.Node{
    hash_value: String.t,
    height: Integer.t,
    children: %{:left => MerkleTree.Node.t, :right => MerkleTree.Node.t}
  }
end