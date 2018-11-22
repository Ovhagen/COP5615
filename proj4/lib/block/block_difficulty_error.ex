defmodule Block.DiffError do
@moduledoc """
This module defines a failure for failing with difficulty verification of a block hash.
"""
    defexception message: "Hash larger than target."

    def full_message(error) do
        "Difficulty verification error: #{error.message}"
    end
end
