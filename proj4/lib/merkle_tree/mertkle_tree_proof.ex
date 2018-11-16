defmodule MerkleTree.Proof do
@moduledoc """
This module defines operations for proving the inclusion of transaction
"""

defstruct [:hash_values]

@type hash_values :: [String.t, ...]
@type t :: %MerkleTree.Proof{
    hash_values: hash_values
}

@doc """
Helper function which checks if input data is a power of two.
"""
def verify_transaction(tx_hash) do
    
end

@doc """
Generates the merkle tree path of hashes to verify a given transaction.

In the bitcoin protocol, the merkle path will be calculated by a full node
on the request of a client. The client can further take this proof and verify
the transaction.
"""
def generateMerklePath() do
    
end

end