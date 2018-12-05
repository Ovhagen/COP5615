defmodule JBOK do
  defstruct [:pub_key, :pkh, :addr]
  @type priv_key :: <<_::256>>
  @type pub_key :: <<_::520>>
  @type pkh :: <<_::160>>
  @type addr :: String.t
  
  use Agent
  
  def start_link(_), do: Agent.start_link(fn -> %{} end)
  
  def generate_key(pid) do
    {pub_key, priv_key} = KeyAddress.keypair
    pkh = KeyAddress.compress_pubkey(pub_key)
      |> KeyAddress.pubkey_to_pkh
    addr = KeyAddress.pkh_to_address(pkh)
    :ok = Agent.update(pid, Map, :put, [priv_key, %JBOK{pub_key: pub_key, pkh: pkh, addr: addr}])
    priv_key
  end
end