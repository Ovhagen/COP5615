defmodule Base58Check do

  @doc """
  Encodes data as a Base58Check string, which appends a checksum to the data to protect against errors.
  """
  @spec encode(binary, binary) :: String.t
  def encode(version, data) do
    version <> data <> checksum(version, data)
    |> Base58.encode
  end
  
  @doc """
  Decodes a Base58Check string. Returns a tuple with {version, data, checksum}.
  """
  @spec decode(String.t) :: {binary, binary, binary}
  def decode(code) do
    [<<version::binary-size(1), data::binary>>, checksum] = code
      |> Base58.decode
      |> :binary.bin_to_list
      |> Enum.split(-4)
      |> Tuple.to_list
      |> Enum.map(&:binary.list_to_bin(&1))
    {version, data, checksum}
  end
  
  @doc """
  Checks if code is a valid Base58Check string.
  """
  @spec validate(String.t) :: boolean
  def validate(code) when is_binary(code), do: Base58.validate(code) and validate(decode(code))
  @spec validate({binary, binary, binary}) :: boolean
  def validate({version, data, checksum}), do: checksum == checksum(version, data)
  
  # Generates a four-byte checksum for a Base58Check formatted string.
  defp checksum(version, data) do
    version <> data
    |> sha256
    |> sha256
    |> :binary.bin_to_list
    |> Enum.take(4)
    |> :binary.list_to_bin
  end
  
  # Hashes data using SHA256.
  defp sha256(data), do: :crypto.hash(:sha256, data)
end