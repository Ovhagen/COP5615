defmodule MerkleTree.PowerError do
@moduledoc """
This module defines a failure for trying to initialize a merkle tree
with the number of input transactions not equal to a power of two.
"""
    defexception message: "Given number of input transactions are not a power of two."

    def full_message(error) do
        "Power arity failure: #{error.message}"
    end
end