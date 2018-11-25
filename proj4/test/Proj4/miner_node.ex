defmodule Proj2.MinerNode do
  @moduledoc """
  """
  use GenServer

  ## Client API

  @doc """
  Starting and linking the GenServer process.

  """
  def start_link(state, opts \\ []) do
    GenServer.start_link(__MODULE__, state, opts)
  end



  @doc """
  Send gossip to a GossipNode.
  """
  def gossip(node, gossip) do
    GenServer.cast(node, {:gossip, gossip})
  end

  @doc """
  Retrieve a value from a GossipNode. Can handle a single key or a list of keys.
  """
  def get(node, key, timeout \\ 5000) do
    GenServer.call(node, {:get, key}, timeout)
  end

  ## Server Callbacks

  @doc """
  GenServer initialization.
  """
  @impl true
  def init(state) do
    {:ok, state}
  end


  @impl true
  def handle_call({:update, key_fun}, _from, state) when is_list(key_fun) do
    {:reply, :ok, Enum.reduce(key_fun, state, &(Map.update!(&2, elem(&1, 0), elem(&1, 1))))}
  end



  def handle_info(:transmit, %{mode: mode, data: data, neighbors: neighbors, sent: sent, tx_fn: tx_fn, mode_fn: mode_fn} = state) do
    {data, gossip} = tx_fn.(data)
    gossip(Enum.random(neighbors), gossip)
	Process.send_after(self(), :transmit, get_delay())
	{:noreply,
      state
	   |> Map.put(:mode, mode_fn.(:send, mode, data))
	   |> Map.put(:data, data)
	   |> Map.put(:sent, sent+1),
	  {:continue, mode}}
  end

  @doc """
  Handle incoming gossip.
  Changes the current state based on the received gossip, updates the operating mode, and calls handle_continue to check for convergence.
  Nodes that receive gossip will become active and start transmitting.
  """
  @impl true
  def handle_cast(_, %{mode: :stopped} = state), do: {:noreply, state}

  def handle_cast({:gossip, gossip}, %{mode: mode, data: data, rcv_fn: rcv_fn, mode_fn: mode_fn} = state) do
	if mode == :passive, do: send(self(), :transmit)
	{:noreply,
	  state
	    |> Map.put(:mode, mode_fn.(:receive, (if mode == :passive, do: :active, else: mode), data))
	    |> Map.put(:data, rcv_fn.(data, gossip)),
	  {:continue, mode}}
  end


end
