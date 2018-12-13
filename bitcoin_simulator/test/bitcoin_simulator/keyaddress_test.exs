defmodule KeyAddressTest do
  use ExUnit.Case
  @moduledoc """
  This module defines unit tests for the KeyAddress module.
  """
  setup do
    {pubkey, privkey} = KeyAddress.keypair
    %{
      pubkey:  pubkey,
      privkey: privkey,
      pkh:     KeyAddress.pubkey_to_pkh(pubkey)
    }
  end
  
  @doc """
  This test verifies that a public key can be compressed and uncompressed successfully.
  """
  test "Compress and uncompress public key", data do
    assert data.pubkey == KeyAddress.uncompress_pubkey(KeyAddress.compress_pubkey(data.pubkey))
  end
  
  @doc """
  This test verifies that a public key hash can be recovered from an address.
  """
  test "Generate address from public key hash", data do
    assert data.pkh == KeyAddress.address_to_pkh(KeyAddress.pkh_to_address(data.pkh))
  end
end