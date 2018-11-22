defmodule MerkleTree do
  @moduledoc """
  This module represents a merkle tree which produces the root hash stored in a
  block in the bitcoin bloackchain. A merkle tree is a data structure represented
  as a binary tree with hashes. The merkle tree consists of the hashes of transactions
  as leaf nodes, which in turn are hashed to create internal nodes in the tree structure.
  The root hash of the tree resides on the top-level of the tree. Transactions can be
  validated as a part of the tree through building the merkle path up to the root hash.

  In regards bitcoin, a merkle tree root is stored in the block header. Full nodes
  keep a copy of the merkle tree and can

  """

  defstruct [:root]

  @typedoc """
  The merkle root node of the merkle tree.
  """
  @type root :: MerkleTree.Node.t
  @type t :: %MerkleTree{
    root: root
  }

  @doc """
  Hash function for creating node hashes from data.
  Uses SHA256 hash alogrithm.
  """
  @spec hash(String.t) :: String.t
  def hash(data) do
    :crypto.hash(:sha256, data) |> Base.encode16(case: :lower)
  end

  @doc """
  Helper function which checks if input data is a power of two.
  """
  @spec is_correct_power([String.t, ...]) :: Boolean.t
  defp is_correct_power(data) do
    len = length(data)
    :math.ceil(:math.log2(len)) == :math.floor(:math.log2(len))
  end

  @doc """
  This function handles the main operations for generating a merkle tree.
  Key activities are: Check and throw errors if necessary, create the first
  leaf nodes for each transaction, call generate_tree() to recursively build
  the tree, and finally set the root node to be returned.
  """
  @spec makeMerkle([String.t, ...]) :: MerkleTree.Node.t
  def makeMerkle(transactions) do
    if (transactions == []), do: raise FunctionClauseError
    unless is_correct_power(transactions), do: raise MerkleTree.PowerError

    root = transactions
    |> Enum.map(fn (tx) ->
      %MerkleTree.Node{
        hash_value: hash(tx),
        height: 0,
        children: []
      } end) |> generate_tree(1)
      %MerkleTree{root: root}
  end

  @doc """
  Recursively build the tree until only root node is left.
  Builds the tree on a level by level basis; creates parent nodes
  by concatenating hashes and re-hash them, then passing them further
  up the tree to repeat the same process.
  """
  @spec generate_tree([MerkleTree.Node.t, ...], Integer.t) :: MerkleTree.Node.t
  defp generate_tree([root], _), do: root
  defp generate_tree(nodes, height) do
    parent_nodes = nodes
    |> Enum.chunk_every(2)
    |> Enum.map(fn(node_pair) ->
      concat_hash = node_pair |>
      Enum.map(&(&1.hash_value))
      |> List.flatten()
      |> Enum.chunk_every(2)
      |> Enum.map(fn [h1, h2] -> hash(h1 <> h2) end)
        %MerkleTree.Node{
          hash_value: List.to_string(concat_hash),
          height: height,
          children: %{:left => Enum.at(node_pair, 0), :right => Enum.at(node_pair, 1)}
        }
    end)
    generate_tree(parent_nodes, height+1)
  end


end
