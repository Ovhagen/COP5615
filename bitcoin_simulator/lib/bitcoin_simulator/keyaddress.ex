defmodule KeyAddress do
  import Crypto
  
  @private_key 0x80
  @public_key  0x04
  @cpk_even    0x02
  @cpk_odd     0x03
  @address     0x00
  @wifc_suffix 0x01
  
  @type pubkey  :: <<_::264>> | <<_::520>>
  @type privkey :: <<_::264>>
  @type pkh     :: Crypto.hash160
  @type address :: String.t
  
  def keypair(), do: :crypto.generate_key(:ecdh, :secp256k1)
  def keypair(key) when is_binary(key), do: keypair(:binary.decode_unsigned(key))
  def keypair(key) when is_integer(key), do: :crypto.generate_key(:ecdh, :secp256k1, key)
  
  def wif(key) when is_binary(key), do: Base58Check.encode(<<@private_key>>, key)
  
  def wifc(key) when is_binary(key), do: Base58Check.encode(<<@private_key>>, key <> <<@wifc_suffix>>)
  
  def compress_pubkey(<<@public_key::8, x::256, y::256>>) do
    <<
      (if rem(y, 2) == 1, do: @cpk_odd, else: @cpk_even)::8,
      x::256
    >>
  end
  def compress_pubkey(<<pubkey::binary-33>>), do: pubkey
  
  def uncompress_pubkey(<<0x04, _::256>> = pubkey), do: pubkey
  def uncompress_pubkey(<<prefix::8, x::256>>) do
    {{_, <<p::integer-256>>}, {<<a::integer>>, <<b::integer>>, _}, _, _, _} = :crypto.ec_curve(:secp256k1)
    y = modpow(x, 3, p) + a * modpow(x, 2, p) + b
      |> rem(p)
      |> modpow(div(p+1, 4), p)
    <<
      @public_key::8,
      x::256,
      (if rem(y, 2) == rem(prefix, 2), do: y, else: p - y)::256
    >>
  end
  
  def pubkey_to_pkh(key) when is_binary(key), do: compress_pubkey(key) |> sha256 |> ripemd160
  
  def pkh_to_address(pkh) when is_binary(pkh), do: Base58Check.encode(<<@address>>, pkh)
  
  def address_to_pkh(addr) when is_binary(addr), do: Base58Check.decode(addr) |> elem(1)
  
  defp modpow(_n, 0, _p), do: 1
  defp modpow(n, k, p) when rem(k, 2) == 0, do: modpow(rem(n*n, p), div(k, 2), p)
  defp modpow(n, k, p), do: rem(n * modpow(n, k-1, p), p)
end