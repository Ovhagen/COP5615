defmodule Base58 do
  @alphabet '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'
  
  @doc """
  Encodes data as a Base58 string, which excludes the characters '0', 'I', 'O', and 'l'.
  """
  @spec encode(binary, String.t) :: String.t
  def encode(data, hash \\ "")
  def encode(data, hash) when is_binary(data), do: encode(:binary.bin_to_list(data), hash)
  def encode([0 | tail], hash), do: <<Enum.at(@alphabet, 0)>> <> encode(tail, hash)
  def encode(data, hash) when is_list(data), do: :binary.list_to_bin(data) |> :binary.decode_unsigned |> encode(hash)
  def encode(0, hash), do: hash
  def encode(data, hash) do
    c = <<Enum.at(@alphabet, rem(data, 58))>>
    encode(div(data, 58), c <> hash)
  end
end