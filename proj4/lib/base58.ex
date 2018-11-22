defmodule Base58 do
  @alphabet '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'
  
  @doc """
  Encodes data as a Base58 string, which excludes the characters '0', 'I', 'O', and 'l'.
  """
  @spec encode(binary, String.t) :: String.t
  def encode(data, code \\ "")
  def encode(data, code) when is_binary(data), do: encode(:binary.bin_to_list(data), code)
  def encode([0 | tail], code), do: <<Enum.at(@alphabet, 0)>> <> encode(tail, code)
  def encode(data, code) when is_list(data), do: :binary.list_to_bin(data) |> :binary.decode_unsigned |> encode(code)
  def encode(0, code), do: code
  def encode(data, code) do
    c = <<Enum.at(@alphabet, rem(data, 58))>>
    encode(div(data, 58), c <> code)
  end
  
  @doc """
  Decodes a Base58 string. Returns nil if code is not a valid Base58 string.
  """
  @spec decode(String.t, integer) :: binary
  def decode(code, data \\ 0)
  def decode(code, data) when is_binary(code) do
    if validate(code), do: decode(:binary.bin_to_list(code), data), else: nil
  end
  def decode([49 | tail], 0), do: <<Enum.find_index(@alphabet, &(&1==49))>> <> decode(tail, 0)
  def decode([c | tail], data), do: decode(tail, data * 58 + Enum.find_index(@alphabet, &(&1==c)))
  def decode(_, data), do: :binary.encode_unsigned(data)
  
  @doc """
  Checks if code is a valid Base58 formatted string.
  """
  @spec validate(String.t) :: boolean
  def validate(code) when is_binary(code) do
    :binary.bin_to_list(code)
    |> Enum.reduce(true, &(&1 in @alphabet and &2))
  end
end