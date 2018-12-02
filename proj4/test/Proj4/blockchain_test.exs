defmodule Proj4.BlockchainTest do
  use ExUnit.Case
  @moduledoc """
  This module defines unit tests for the Blockchain module
  """
  setup do
    %{
      bc: Blockchain.genesis
    }
  end
  
  test "Verify block", data do
    assert :ok == Block.verify(data.block)
    
    assert {:error, :version} == Block.verify(Map.put(data.block, :header, Map.put(data.block.header, :version, 2)))
    
    future = DateTime.utc_now |> DateTime.to_unix |> Kernel.+(8_000) |> DateTime.from_unix!
    assert {:error, :timestamp} == Block.verify(Map.put(data.block, :header, Map.put(data.block.header, :timestamp, future)))
    
    assert {:error, :merkle} == Block.verify(Map.put(data.block, :header, Map.put(data.block.header, :merkle_root, :crypto.strong_rand_bytes(32))))
    
    assert {:error, :hash} == Block.verify(Map.put(data.block, :header, Map.put(data.block.header, :target, <<0x10100000::32>>)))
  end
  
  test "Serialize and deserialize block", data do
    assert data.block == Block.deserialize(Block.serialize(data.block))
  end
  
  test "Byte size is calculated correctly", data do
    assert Block.bytes(data.block) == byte_size(Block.serialize(data.block))
  end
end