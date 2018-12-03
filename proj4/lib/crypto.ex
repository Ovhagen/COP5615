defmodule Crypto do
  @type hash256 :: <<_::256>>
  @type hash160 :: <<_::160>>

  @doc """
  Hashes the input using the SHA256 algorithm.
  """
  @spec sha256(binary) :: hash256
  def sha256(data), do: :crypto.hash(:sha256, data)
  
  @doc """
  Hashes the input using the SHA256 algorithm, then hashes the result again using SHA256.
  """
  @spec sha256x2(binary) :: hash256
  def sha256x2(data), do: data |> sha256 |> sha256
  
  @doc """
  Hashes the input using the RIPEMD160 algorithm.
  """
  @spec ripemd160(binary) :: hash160
  def ripemd160(data), do: :crypto.hash(:ripemd160, data)
end
