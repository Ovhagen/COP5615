defmodule Proj4.BlockTest do
  use ExUnit.Case
  @moduledoc """
  This module defines unit tests for the Block module
  """
  setup do
    transactions = (for _n <- 1..2, do: Transaction.test(:rand.uniform(3), :rand.uniform(3)))
    block = Block.new(transactions, :crypto.strong_rand_bytes(32), <<0x20ffffff::32>>)
    %{
      transactions: transactions,
      block:        block
    }
  end
  
  @doc """
  This test verifies that properly constructed blocks pass verification, and
  improperly constructd blocks are rejected with the proper error code.
  """
  test "Verify block", data do
    # Valid block passes verification
    assert :ok == Block.verify(data.block)
    
    # Block version 1 is the only valid version number
    assert {:error, :version} == Block.verify(Map.put(data.block, :header, Map.put(data.block.header, :version, 2)))
    
    # Blocks must not have a timestamp more than 2 hours in the future
    future = DateTime.utc_now |> DateTime.to_unix |> Kernel.+(8_000) |> DateTime.from_unix!
    assert {:error, :timestamp} == Block.verify(Map.put(data.block, :header, Map.put(data.block.header, :timestamp, future)))
    
    # The merkle root hash generated from the transaction data must match the merkle root hash stored in the block header.
    assert {:error, :merkle} == Block.verify(Map.put(data.block, :header, Map.put(data.block.header, :merkle_root, :crypto.strong_rand_bytes(32))))
    
    # The block header must hash to a value below the difficulty target specified in the block header.
    assert {:error, :hash} == Block.verify(Map.put(data.block, :header, Map.put(data.block.header, :target, <<0x10100000::32>>)))
  end
  
  @doc """
  This test verifies that blocks can be recovered from serialized form (raw bytes).
  """
  test "Serialize and deserialize block", data do
    assert data.block == Block.deserialize(Block.serialize(data.block))
  end
  
  @doc """
  This test verifies that the length of a block in raw bytes is calculated correctly.
  """
  test "Byte size is calculated correctly", data do
    assert Block.bytes(data.block) == byte_size(Block.serialize(data.block))
  end
end