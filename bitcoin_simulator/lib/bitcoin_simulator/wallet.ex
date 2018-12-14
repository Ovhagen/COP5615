defmodule Bitcoin.Wallet do
  @moduledoc """
  This module defines the Wallet actor, which represents a user of the Bitcoin network.
  """
  
  use GenServer
  
  defstruct [:pubkey, :privkey, :pkh, :utxo]
  
  @type t :: %Bitcoin.Wallet{
    pubkey:  KeyAddress.pubkey,
    privkey: KeyAddress.privkey,
    pkh:     KeyAddress.pkh,
    utxo:    Blockchain.UTXO.t
  }
  
  # Client interface
  
  def start_link(seed \\ nil), do: GenServer.start_link(__MODULE__, seed)
  
  def join(wallet, node), do: GenServer.call(wallet, {:join, node})
  
  def get_pkh(wallet), do: GenServer.call(wallet, :get_pkh)
  
  def get_balance(wallet), do: GenServer.call(wallet, :get_balance)
  
  def request_payment(wallet, value, pkh), do: GenServer.call(wallet, {:payment, value, pkh})
  
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
  
  def handle_call(:get_pkh, _from, state), do: {:reply, {:ok, state.wallet.pkh}, state}
  
  def handle_call(:get_balance, _from, state), do: {:reply, {:ok, balance(state.wallet.utxo)}, state}
  
  def handle_call({:payment, value, pkh}, _from, state) do
    with {:ok, tx} <- build_tx(value, pkh, state.wallet),
         :ok       <- Bitcoin.Node.verify_tx(state.node, tx)
    do
      {:reply, :ok, Map.update!(state, :wallet, &Map.put(&1, :utxo, %{}))}
    else
      error -> {:reply, error, state}
    end
  end
  
  @impl true
  def handle_cast({:relay_tx, raw_tx}, state) do
    wallet = Map.put(state.wallet, :utxo,
      Transaction.deserialize(raw_tx)
      |> Blockchain.UTXO.from_tx
      |> Map.delete(:index)
      |> Enum.filter(fn {_key, %{vout: vout}} -> vout.pkh == state.wallet.pkh end)
      |> Map.new
      |> Map.merge(state.wallet.utxo)
    )
    {:noreply, Map.put(state, :wallet, wallet)}
  end
  
  # Ignore blocks for now, we aren't checking for transaction confirmation.
  def handle_cast({:relay_block, _raw_block, _from}, state), do: {:noreply, state}
  
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
  
  defp balance(utxo) do
    Map.values(utxo)
    |> Enum.map(fn %{vout: vout} -> vout.value end)
    |> Enum.sum
  end
  
  defp build_tx(value, pkh, wallet) do
    bal = balance(wallet.utxo)
    if bal < value do
      {:error, :balance}
    else
      vin = Enum.map(wallet.utxo, fn {{txid, pos}, _vout} -> Transaction.Vin.new(txid, pos) end)
      vout = if(bal-value-200 > 0, do: [Transaction.Vout.new(bal-value-200, wallet.pkh)], else: [])
        |> Enum.concat([Transaction.Vout.new(value, pkh)])
      {:ok, Transaction.new(vin, vout) |> Transaction.sign(wallet.pubkey, wallet.privkey)}
    end
  end
end