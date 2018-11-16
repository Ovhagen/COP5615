defmodule Block do
    @moduledoc """
  This module defines a full block in the bitcoin protocol. Blocks are
  created by miners. Full nodes in the network will store whole blocks.

  The member Magic number is omitted in this implementation.
  """

  defstruct [:block_size, :block_header, :tx_counter, :transactions]

  @typedoc """
  The total size calculated on the block.
  """
  @type block_size :: non_neg_integer
  @typedoc """
  An array containing all the transactions included in the block.
  """
  @type block_header :: Block.BlockHeader.t
  @typedoc """
  A counter for the amount of transactions included in the block.
  """
  @type tx_counter :: non_neg_integer
  @typedoc """
  An list containing all the transactions included in the block.
  """
  @type transactions :: [String.t, ...]
  @type t :: %Block{
      block_size: block_size, 
      block_header: block_header, 
      tx_counter: tx_counter, 
      transactions: transactions
  }

end