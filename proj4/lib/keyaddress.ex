defmodule KeyAddress do
  @private_key "80"
  @public_key  "04"
  @cpk_even    "02"
  @cpk_odd     "03"
  @address     "00"
  
  def keypair() do
    with {public_key, private_key} <- :crypto.generate_key(:ecdh, :secp256k1),
      do: {Base.encode16(public_key), Base.encode16(private_key)}
  end
  def keypair(key) when is_binary(key), do: keypair(Base.decode16(key))
  def keypair(key) do
    with {public_key, private_key} <- :crypto.generate_key(:ecdh, :secp256k1, key),
      do: {Base.encode16(public_key), Base.encode16(private_key)}
  end
  
  def compress_pubkey(key) do
    <<_::binary-size(1), x::binary-size(32), _::binary-size(31), flag::integer>> = key
    (if rem(flag, 2) == 1, do: @cpk_odd, else: @cpk_even) <> x
  end
  
  def uncompress_pubkey(cpk) do
    # implement
  end
  
  def pubkey_to_pkh(key) when is_binary(key), do: pubkey_to_pkh(Base.decode16(key))
  def pubkey_to_pkh(key), do: :crypto.hash(:ripemd160, :crypto.hash(:sha256, key))
  
  def pkh_to_address(pkh) when is_binary(pkh), do: Base58Check.encode(<<0x00>>, pkh)
  
  def address_to_pkh(addr) when is_binary(addr), do: Base58Check.decode(addr) |> elem(1)
end