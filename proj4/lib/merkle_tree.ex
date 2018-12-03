defmodule MerkleTree do
  @moduledoc """
  This module represents a merkle tree which produces the root hash stored in a
  block in the bitcoin bloackchain. A merkle tree is a data structure represented
  as a binary tree with hashes. The merkle tree consists of the hashes of transactions
  as leaf nodes, which in turn are hashed to create internal nodes in the tree structure.
  The root hash of the tree resides on the top-level of the tree. Transactions can be
  validated as a part of the tree through building the merkle path up to the root hash.
  """

  import Crypto

  defstruct root: %MerkleTree.Node{}, leaves: 0

  @type merkle_proof :: [{:left | :right, Crypto.hash256}, ...]
  @type t :: %MerkleTree{
    root:   MerkleTree.Node.t | MerkleTree.Leaf.t,
    leaves: non_neg_integer
  }

  @doc """
  Builds a merkle tree from a list of transactions.
  """
  @spec build_tree([Transaction.t, ...]) :: t
  def build_tree(txs) do
    %MerkleTree{
      root: build_tree(txs, ceil2(length(txs))),
      leaves: length(txs)
    }
  end
  defp build_tree([], _size), do: nil
  defp build_tree(txs, 1), do: MerkleTree.Leaf.new(hd(txs))
  defp build_tree(txs, size) do
    half = div(size, 2)
    {left_txs, right_txs} = Enum.split(txs, half)
    MerkleTree.Node.new(build_tree(left_txs, half), build_tree(right_txs, half))
  end

  @doc """
  Replaces the transaction at the specified index with a different transaction, and rehashes the path up to the root.
  Primarily used to update the coinbase transaction when mining.
  """
  @spec update_tx(t, Transaction.t, non_neg_integer) :: t
  def update_tx(%MerkleTree{root: root, leaves: leaves}, tx, index) when index < leaves do
    %MerkleTree{
      root: update_tx(root, tx, index, div(ceil2(leaves), 2)),
      leaves: length(tx)
    }
  end
  defp update_tx(_leaf, tx, index, pos) when index == pos, do: MerkleTree.Leaf.new(tx)
  defp update_tx(%MerkleTree.Node{hash: hash, left: left, right: right} = node, tx, index, pos) do
    if index < pos do
      MerkleTree.Node.new(update_tx(left, tx, index, div(pos, 2)), right)
    else
      MerkleTree.Node.new(left, update_tx(right, tx, index, pos + div(pos, 2)))
    end
  end

  @doc """
  Trims a transaction from the tree, and removes any internal nodes which are no longer needed to prove the remaining transactions.
  This is used to remove already-spent UTXOs and reduce the memory required for the blockchain.
  """
  @spec trim_tx(t, Crypto.hash256) :: t
  def trim_tx(%MerkleTree{root: root, leaves: leaves}, index) do
    %MerkleTree{
      root:   trim_tx(root, index, div(ceil2(leaves), 2)),
      leaves: leaves
    }
  end
  defp trim_tx(%MerkleTree.Node{} = node, index, pos) when index < pos do
    Map.put(node, :left, trim_tx(node.left, index, div(pos, 2)))
    |> stubify
  end
  defp trim_tx(%MerkleTree.Node{} = node, index, pos) do
    Map.put(node, :right, trim_tx(node.right, index, pos + div(pos, 2)))
    |> stubify
  end
  defp trim_tx(%MerkleTree.Leaf{hash: hash}, index, pos) when index == pos, do: %MerkleTree.Leaf{hash: hash}
  defp trim_tx(nil, _index, _pos), do: nil

  # Turns a node into a stub if both children are stubs. Otherwise, just returns the original node.
  defp stubify(node) do
    if stub?(node.left) and stub?(node.right) do
      %MerkleTree.Node{hash: node.hash}
    else
      node
    end
  end

  # Checks if a node/leaf is a stub (all children are nil).
  defp stub?(nil), do: true
  defp stub?(%MerkleTree.Node{left: nil, right: nil}), do: true
  defp stub?(%MerkleTree.Leaf{tx: nil}), do: true
  defp stub?(_), do: false

  @doc """
  Returns a merkle proof, which is a sequence of hash values that prove a particular transaction is contained within the block with the given merkle root.
  To follow the proof, sequentially concatenate (to the left or right as indicated) and hash each value in the list.
  """
  @spec proof(t | MerkleTree.Node.t | nil, Crypto.hash256 | Transaction.t) :: merkle_proof | :error
  def proof(tree, %Transaction{} = tx), do: proof(tree, Transaction.hash(tx))
  def proof(%MerkleTree{root: root}, txid), do: proof(root, txid)
  def proof(%MerkleTree.Node{} = node, txid) do
    case proof(node.left, txid) do
      {:ok, hashes} ->
        {
          :ok,
          hashes ++ [{:right, (if node.right == nil, do: node.left.hash, else: node.right.hash)}]
        }
      :error ->
        case proof(node.right, txid) do
          {:ok, hashes} ->
            {
              :ok,
              hashes ++ [{:left, (if node.left == nil, do: node.right.hash, else: node.left.hash)}]
            }
          :error -> :error
        end
    end
  end
  def proof(%MerkleTree.Leaf{hash: hash} = leaf, txid), do: (if hash == txid, do: {:ok, [hash]}, else: :error)
  def proof(nil, _txid), do: :error

  @doc """
  Solves a merkle proof by sequentially hashing the values until the merkle root is produced.
  Return true if the sequence of hashes is equal to the root, false otherwise.
  """
  @spec solve_proof(merkle_proof, Crypto.hash256) :: boolean
  def solve_proof([leaf | nodes], root) do
    root == Enum.reduce(nodes, leaf, fn
        {:right, hash}, proof -> sha256x2(proof <> hash)
        {:left, hash}, proof -> sha256x2(hash <> proof)
      end)
  end

  # Rounds n up to a power of 2.
  defp ceil2(n), do: :math.pow(2, n |> :math.log2 |> :math.ceil) |> trunc
end
