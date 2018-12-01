defmodule Proj4.BlockTest do
  use ExUnit.Case
  @moduledoc """
  This module defines unit tests for the Block module
  """
  setup do
    transactions = (for _n <- 1..20, do: Transaction.test(:rand.uniform(10), :rand.uniform(10)))
    block = Block.new(transactions, :crypto.strong_rand_bytes(32), <<0x20ffffff::32>>)
    %{
      transactions: transactions,
      block:        block
    }
  end
  
  test "Verify a block", data do
    assert :ok == Block.verify(data.block)
  end
end