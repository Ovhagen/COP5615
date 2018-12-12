defmodule Blockchain.Link do
  defstruct block: %Block{}, prev: %Block{}, height: 0, hash: 0, stxo: %{}

  @type t :: %Blockchain.Link{
    block:  Block.t,
    hash:   Crypto.hash256,
    prev:   t | nil,
    height: non_neg_integer,
    stxo:   Blockchain.UTXO.t
  }
  
  @spec new(Block.t, t, Blockchain.UTXO.t | nil) :: t
  def new(block, prev, stxo \\ nil)
  def new(block, prev, nil), do: new(block, prev, Blockchain.UTXO.new)
  def new(block, prev, stxo) do
    %Blockchain.Link{
      block:  block,
      hash:   Block.hash(block),
      prev:   prev,
      height: prev.height+1,
      stxo:   stxo
    }
  end
end
