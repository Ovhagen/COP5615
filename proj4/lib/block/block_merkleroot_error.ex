defmodule Block.MerkleRootError do
@moduledoc """
This module defines a failure for miss-match of calculated merkle root against
the one stored in the block.
"""
    defexception message: "Failed merkle root verification."

    def full_message(error) do
        "Merkle root verification error: #{error.message}"
    end
end
