defmodule MerkleTree.PowerError do
    defexception message: "Given number of input transactions are not a power of two."

    def full_message(error) do
        "Power arity failure: #{error.message}"
    end
end