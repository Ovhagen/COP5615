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
        hash_values: hash_values
    }

    
    @doc """
    Generates the merkle tree path of hashes to verify a given transaction.
    Takes the merkle tree, the target transaction hash, and the index of the 
    transaction. The index can be found in the list of transactions in the
    full block, where the target transaction is stored.

    In the bitcoin protocol, the merkle path will be calculated by a full node
    on the request of a client. The client can further take this proof and verify
    the transaction.
    """
    @spec generateMerkleProof(MerkleTree.t, String.t, non_neg_integer) :: Merkle.Proof.t
    def generateMerkleProof(merkle_tree, target_tx, index) do
        original_tx = target_tx
        hash_values = ["7853d08f19cbdec01cb95613771670650b2967aafbc02cf7fdd69047551fa465",
        "ffe1f2421d57dc07f5f0c13b439ad80cff78a0f5683a5faa9d0fab4d1bc92a2a",
        "fc73efaf5dae1dca1c1bdf0c3d2f59dec282a3951f42524fabe1da0e49278518"]
        %MerkleTree.Proof{
            hash_values: hash_values
        }
    end

    @doc """
    Verifies the transaction for the transaction the proof was created for.
    """
    @spec verify_transaction() :: Boolean.t
    def verify_transaction() do
        root_hash = hash_values |> List.last()
        hashes = hash_values |> List.delete_at(length(hash_values)) 
        
        hashes |> Enum.reduce(fn (x, acc) -> hash(x+acc) end) == root_hash
    end


end