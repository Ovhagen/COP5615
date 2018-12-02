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
  
  test "Verify genesis block", data do
    assert data.bc.tip.height == 0
  end
end