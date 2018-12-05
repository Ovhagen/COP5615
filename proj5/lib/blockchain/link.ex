defmodule Blockchain.Link do
  import Crypto

  defstruct block: %Block{}, prev: %Block{}, height: 0, hash: 0

  @type t :: %Blockchain.Link{
    block:  Block.t,
    hash:   Crypto.hash256,
    prev:   t | nil,
    height: non_neg_integer
  }
  
  @spec new(Block.t, t) :: t
  def new(block, prev) do
    %Blockchain.Link{
      block:  block,
      hash:   Block.hash(block),
      prev:   prev,
      height: prev.height+1
    }
  end
end
