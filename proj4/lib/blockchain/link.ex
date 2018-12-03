defmodule Blockchain.Link do
  import Crypto

  defstruct block: %Block{}, prev: %Block{}, height: 0, hash: 0

  @type t :: %Blockchain.Link{
    block:  Block.t,
    hash:   Crypto.hash256,
    prev:   Block.t | nil,
    height: non_neg_integer
  }
end
