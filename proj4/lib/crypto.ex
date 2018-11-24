defmodule Crypto do
  def sha256(data), do: :crypto.hash(:sha256, data)
  def ripemd160(data), do: :crypto.hash(:ripemd160, data)
end