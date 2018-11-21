defmodule Base58Check do

  @doc """
  Encodes data as a Base58Check string, which appends a checksum to the data to protect against errors.
  """
  @spec encode(binary, binary) :: String.t
  def encode(version, data) do
    version <> data <> checksum(version, data)
    |> Base58.encode
  end
  
  defp checksum(version, data) do
    version <> data
    |> sha256
    |> sha256
    |> :binary.bin_to_list
    |> Enum.take(4)
    |> :binary.list_to_bin
  end
  
  defp sha256(data), do: :crypto.hash(:sha256, data)
end