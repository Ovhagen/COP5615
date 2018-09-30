defmodule Proj2.GossipNode do
  @moduledoc """
  Documentation for Proj2.GossipNode
  """
  use GenServer
  
  ## Client API
  
  @doc """
  Starting and linking the GenServer process.
  Initializing a node in the network.
  The state holds three elements: the convergence number, number of received messages
  at the start and the neighbors of a node.
  """
  def start_link(state, opts \\ []) do
    GenServer.start_link(__MODULE__, state, opts)
  end
  
  @doc """
  Tell a GossipNode to transmit its gossip to a random neighbor.
  """
  def transmit(node) do
    send node, :transmit
  end
  
  @doc """
  Tell a GossipNode to stop gossiping.
  """
  def stop(node) do
    update(node, :mode, fn _ -> :stopped end)
  end
  
  @doc """
  Send gossip to a GossipNode.
  """
  def gossip(node, gossip) do
    GenServer.cast(node, {:gossip, gossip})
  end
  
  def get(node, key) do
    GenServer.call(node, {:get, key})
  end
  
  def update(node, key, fun) do
    GenServer.call(node, {:update, key, fun})
  end
  
  ## Server Callbacks

  @doc """
  GenServer initialization.
  """
  @impl true
  def init(state) do
    {:ok, state}
  end
  
  @doc """
  Handle requests for state.
  """
  def handle_call({:get, key}, _from, state) do
    {:reply, Map.get(state, key), state}
  end
  
  @doc """
  Handle updates to state.
  """
  @impl true
  def handle_call({:update, key, fun}, _from, state) do
    {:reply, :ok, Map.update!(state, key, fun)}
  end
  
  @doc """
  Handle requests to transmit state to a neighbor.
  Generates the gossip based on the current state and casts it to a random neighbor. Then, checks for the kill condition.
  """
  @impl true
  def handle_info(_, %{mode: :stopped} = state), do: {:noreply, state}
  
  def handle_info(:transmit, %{mode: :converged} = state) do
    :ok = GenServer.call(Proj2.Observer, :converged)
    {:noreply, state}
  end
  
  def handle_info(:transmit, %{neighbors: neighbors} = state) when length(neighbors) == 0, do: {:noreply, Map.put(state, :mode, :stopped)}
  
  def handle_info(:transmit, %{neighbors: neighbors, data: data, tx_fn: tx_fn, mode_fn: mode_fn} = state) do
    {data, gossip} = tx_fn.(data)
    gossip(Enum.random(neighbors), gossip)
	Process.send_after(self(), :transmit, get_delay())
	{:noreply,
      state
		|> Map.put(:mode, mode_fn.(:send, data))
		|> Map.put(:data, data)}
  end
  
  @doc """
  Handle incoming gossip.
  Changes the current state based on the received gossip, then checks for kill condition.
  Nodes that receive gossip will become active and start transmitting.
  """
  @impl true
  def handle_cast(_, %{mode: :stopped} = state), do: {:noreply, state}
  
  def handle_cast(_, %{mode: :converged} = state), do: {:noreply, state}
  
  def handle_cast({:gossip, gossip}, %{mode: mode, data: data, rcv_fn: rcv_fn, mode_fn: mode_fn} = state) do
	if mode == :passive, do: Process.send_after(self(), :transmit, get_delay())
	{:noreply,
	  state
	    |> Map.put(:mode, mode_fn.(:receive, data))
	    |> Map.put(:data, rcv_fn.(data, gossip))}
  end
  
  defp get_delay() do
    :rand.uniform()
	  |> :math.exp()
	  |> Kernel.*(Application.get_env(:proj2, :delay))
	  |> trunc()
  end
end