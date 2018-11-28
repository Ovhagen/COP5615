defmodule Blockchain.Link do
  defstruct block: %Block{}, prev: %Block{}, height: 0
  
  @type t :: %Blockchain.Link{
    block:  Block.t,
    prev:   Block.t,
    height: non_neg_integer
  }
end