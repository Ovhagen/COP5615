defmodule MerkleTree.ProofError do
@moduledoc """
This module defines a failure for trying to create a merkle proof with
a transaction not present by the merkle tree leafs.
"""
    defexception message: "The target transaction is not present in the merkle tree."

    def full_message(error) do
        "Proof verification error: #{error.message}"
    end
end
