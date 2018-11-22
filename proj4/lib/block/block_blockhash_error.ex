defmodule Block.BlockHashError do
@moduledoc """
This module defines a failure for a miss-match of the sent hash and calculated block hashes.
"""
    defexception message: "Hash of block not acceptable."

    def full_message(error) do
        "Block hash verification error: #{error.message}"
    end
end
