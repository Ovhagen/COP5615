defmodule MerkleTree.Node do
  import Crypto
  @moduledoc """
  This module specifies a merkle tree node, which is an internal node in the merkle tree.
  """
  defstruct [:hash, :left, :right]

  @type t :: %MerkleTree.Node{
    hash:  Crypto.hash256,
    left:  t | Leaf.t | nil,
    right: t | Leaf.t | nil
  }

  def new(nil, right), do: %MerkleTree.Node{hash: right.hash, left: nil, right: nil}
  def new(left, nil) do
    if MerkleTree.stub?(left) do
      %MerkleTree.Node{hash: left.hash, left: nil, right: nil}
    else
      %MerkleTree.Node{hash: sha256x2(left.hash <> left.hash), left: left, right: nil}
    end
  end
  def new(left, right), do: %MerkleTree.Node{hash: sha256x2(left.hash <> right.hash), left: left, right: right}
  def new(hash), do: %MerkleTree.Node{hash: hash, left: nil, right: nil}
end
