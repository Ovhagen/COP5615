defmodule Block.BlockHeader do
    @moduledoc """
    This module defines a block header which is the header stored
    in a full sized block on the blockchain. Block headers can be
    efficiently used to search and verify data. Additionally, they
    are considered the lightweight version of a block, frequently
    utilized by light clients on the network.
    """

    defstruct [:version, :previous_hash, :merkle_root, :timestamp, :difficulty, :nonce]

    @typedoc """
    Version number of protocol for block.
    """
    @type version :: non_neg_integer
    @typedoc """
    The previous block hash.
    """
    @type previous_hash :: String.t
    @typedoc """
    The merkle tree root.
    """
    @type merkle_root :: String.t
    @typedoc """
    A timestamp when the block was created. Calculated in seconds with Unix time.
    """
    @type timestamp :: non_neg_integer
    @typedoc """
    The difficulty target in bits to create the block.
    """
    @type difficulty :: non_neg_integer
    @typedoc """
    A 32-bit number showing the hash increments. Starts at 0.
    Set in the config file.
    """
    @type nonce :: non_neg_integer
    @type t :: %Block.BlockHeader{
        version: version,
        previous_hash: previous_hash,
        merkle_root: merkle_root,
        timestamp: timestamp,
        difficulty: difficulty,
        nonce: nonce
    }



end
