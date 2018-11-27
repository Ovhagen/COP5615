defmodule Crypto do
  @type hash256 :: <<_256>>
  @type hash160 :: <<_160>>
  
  def sha256(data), do: :crypto.hash(:sha256, data)
  def sha256x2(data), do: data |> sha256 |> sha256
  def ripemd160(data), do: :crypto.hash(:ripemd160, data)
end