defmodule Bitcoin.Wallet do
  @moduledoc """
  This module defines the Wallet actor, which represents a user of the Bitcoin network.
  """
  
  use GenServer
  
  defstruct [:pubkey, :privkey, :pkh]
  
  @type t :: %Bitcoin.Wallet{
    pubkey:  KeyAddress.pubkey,
    privkey: KeyAddress.privkey,
    pkh:     KeyAddress.pkh,
    utxo:    Blockchain.UTXO.t
  }
  
  # Client interface
  
  def start_link(seed \\ nil), do: GenServer.start_link(__MODULE__, [seed])
  
  def join(wallet, node), do: GenServer.call(wallet, {:join, node})
  
  def get_pkh(wallet), do: GenServer.call(wallet, :get_pkh)
  
  # Server callbacks
  
  @impl true
  def init(seed) do
    {:ok,
      %{
        node:   nil,
        wallet: new(seed)
      }
    }
  end
  
  @impl true
  def handle_call({:join, node}, _from, state) do
    with :ok <- Bitcoin.Node.add_neighbor(node, self()) do
      {:reply, :ok, Map.put(state, :node, node)}
    else
      error -> {:reply, error, state}
    end
  end
  
  def handle_call(:get_pkh, _from, state), do: {:reply, state.wallet.pkh, state}
  
  @impl true
  def handle_cast({:relay_tx, raw_tx}, state) do
    wallet = Map.put(state.wallet, :utxo,
      Transaction.deserialize(raw_tx)
      |> Blockchain.UTXO.from_tx
      |> Map.delete(:index)
      |> Enum.filter(fn {key, %{vout: vout}} -> vout.pkh == state.wallet.pkh)
      |> Map.new
      |> Map.merge(state.wallet.utxo)
    )
    {:noreply, Map.put(state, :wallet, wallet)}
  end
  
  # Ignore blocks for now, we aren't checking for transaction confirmation.
  def handle_cast({:relay_block, _raw_block}, state), do: {:noreply, state}
  
  # Helper functions

  defp new(seed) do
    {pubkey, privkey} = if(seed == nil, do: KeyAddress.keypair, else: KeyAddress.keypair(seed))
    %Bitcoin.Wallet{
      pubkey:  pubkey,
      privkey: privkey,
      pkh:     KeyAddress.pubkey_to_pkh(pubkey),
      utxo:    %{}
    }
  end
end