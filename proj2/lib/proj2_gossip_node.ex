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
  def handle_info(:transmit, %{neighbors: neighbors, data: data, tx_fn: fun, kill_fn: kfun} = state) when length(neighbors) > 0 do
    {data, gossip} = fun.(data)
	IO.puts "#{inspect(self())}: Sending gossip"
    gossip(Enum.random(neighbors), gossip)
	case kfun.(data) do
	  {:ok, data} ->
	    Process.send_after(self(), :transmit, get_delay())
	    {:noreply,
		  state
		    |> Map.put(:mode, :active)
			|> Map.put(:data, data)}
	  {:kill, data} ->
	    {:stop, :converged, data}
	end
  end
  
  @doc """
  Handle incoming gossip.
  Changes the current state based on the received gossip, then checks for kill condition.
  Nodes that receive gossip will become active and start transmitting.
  """
  @impl true
  def handle_cast({:gossip, gossip}, %{mode: mode, data: data, rcv_fn: fun} = state) do
    IO.puts "#{inspect(self())}: Received gossip"
	if mode == :passive, do: (send self(), :transmit)
	{:noreply,
	  state
	    |> Map.put(:mode, :active)
	    |> Map.put(:data, fun.(data, gossip))}
  end
  
  defp get_delay() do
    :rand.uniform()
	  |> :math.exp()
	  |> Kernel.*(Application.get_env(:proj2, :delay))
	  |> trunc()
  end
end