defmodule MerkleTree.Proof do
    @moduledoc """
    This module defines operations for proving the inclusion of transaction
    """
    import MerkleTree, only: [hash: 1]

    defstruct [:hash_values, :original_tx]

    @typedoc """
    The hashes of transactions needed to conduct the proof.
    """
    @type original_tx :: String.t
    @typedoc """
    The hashes of transactions needed to conduct the proof.
    """
    @type hash_values :: [String.t, ...]
    @type t :: %MerkleTree.Proof{
        original_tx: original_tx,
        hash_values: hash_values
    }

    @doc """
    Generates the merkle tree path of hashes to verify a given transaction.
    Takes the merkle tree, the target transaction, and the index of the
    transaction. The index can be found in the list of transactions in the
    full block, where the target transaction is stored.

    In the bitcoin protocol, the merkle path will be calculated by a full node
    on the request of a client. The client can further take this proof and verify
    the transaction.
    """
    @spec generateMerkleProof(MerkleTree.t, String.t, non_neg_integer, non_neg_integer, non_neg_integer) :: Merkle.Proof.t
    def generateMerkleProof(merkle_tree, target_tx, height, index, tx_count) do
        target_hash = MerkleTree.hash(target_tx)
        hash_values = traverseMerkleTree(merkle_tree.root, target_hash, height, index, tx_count, [])
        %MerkleTree.Proof{
            original_tx: target_tx,
            hash_values: Enum.concat(hash_values, [merkle_tree.root.hash_value])
        }
    end

    @doc """
    This function recursively extracts the nodes on the opposite path to traverse to reach
    the target hash of a transaction. Starting from the root, this function traverses
    either left or right subtree of a node depending on the index of the transaction.
    The function keeps an active list which it appends merkle path hashes to while running.
    """
    @spec traverseMerkleTree(MerkleTree.Node.t, String.t, non_neg_integer, non_neg_integer, non_neg_integer, [String.t, ...]) :: [String.t, ...]
    def traverseMerkleTree(merkle_node, target_hash, height, _, _, results) when height == 0, do: Enum.concat([target_hash], results)  #Base case, return the leaf hash
    def traverseMerkleTree(merkle_node, target_hash, height, index, tx_count, results) when div(tx_count, 2) <= index do  #Do right traversal
        traverseMerkleTree(
            merkle_node.children[:right],
            target_hash,
            height-1,
            index-div(tx_count, 2),
            div(tx_count, 2),
            Enum.concat([merkle_node.children[:left].hash_value], results))
    end
    def traverseMerkleTree(merkle_node, target_hash, height, index, tx_count, results) when div(tx_count, 2) > index do  #Do left traversal
        traverseMerkleTree(
            merkle_node.children[:left],
            target_hash,
            height-1,
            index,
            div(tx_count, 2),
            Enum.concat([merkle_node.children[:right].hash_value], results))
    end

    @doc """
    Verifies the transaction for the transaction the proof was created for.
    Concatenates hashes and builds hash from bottom of the tree to the top.
    Compares with the root hash. Should always return true since a proof can't
    be created for a transactions not present in the tree.
    """
    @spec verify_transaction(Merkle.Proof.t) :: Boolean.t
    def verify_transaction(proof) do
       root_hash = proof.hash_values |> List.last()
       hashes = proof.hash_values |> List.delete_at(length(proof.hash_values)-1)
       hashes |> Enum.reduce(fn (x, acc) -> hash(acc <> x) end) == root_hash
    end


end
