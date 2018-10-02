defmodule Proj2.GossipNode do
  @moduledoc """
  The GossipNode is the actor that sends and receives gossip.
  
  The GossipNode is implemented generically, so any arbitrary gossip-style algorithm can be run on top of it.
  A GossipNode requires four functions:
    - init:    Generates an initial data state to be used when starting a GossipNode. Any number of arguments as needed to generate the desired state.
    - tx_fn:   Function which is invoked on the current data to determine the data to send to neighboring nodes while gossiping.
               Must take one argument (the current data) and output a tuple with the new data and the data to send.
    - rcv_fn:  Function which is invoked on the current data and the data received during gossiping.
               Must take two arguments (current data and received data) and output the new data.
    - mode_fn: Function which is invoked after both transmitting and receiving to determine continuing mode of operation.
               Must take an atom (:send or :receive) and the current state as arguments, and return an atom representing the current mode of operation.
			   Acceptable modes of operation are :passive, :ac
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
  Resets a gossip node with the data specified and :passive mode.
  """
  def reset(node, data) do
    update(node,
	      [{:mode, fn _ -> :passive end},
		   {:data, fn _ -> data end}])
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
  
  @doc """
  Update a value in a GossipNode, using the provided function. Can handle a single key and function, or a list of {key, function} tuples.
  """
  def update(node, key_fun) when is_list(key_fun) do
    GenServer.call(node, {:update, key_fun})
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
  def handle_call({:get, keys}, _from, state) when is_list(keys) do
    {:reply, Enum.map(keys, &(Map.get(state, &1))), state}
  end
  
  def handle_call({:get, key}, _from, state), do: {:reply, Map.get(state, key), state}
  
  @doc """
  Handle updates to state.
  """
  @impl true
  def handle_call({:update, key_fun}, _from, state) when is_list(key_fun) do
    {:reply, :ok, Enum.reduce(key_fun, state, &(Map.update!(&2, elem(&1, 0), elem(&1, 1))))}
  end
  
  def handle_call({:update, key, fun}, _from, state), do: {:reply, :ok, Map.update!(state, key, fun)}
  
  @doc """
  Handle requests to transmit state to a neighbor.
  Generates the gossip based on the current state and casts it to a random neighbor. Then, updates the operating mode and calls handle_continue to check for convergence.
  """
  @impl true
  def handle_info(_, %{mode: :stopped} = state), do: {:noreply, state}
  
  def handle_info(:transmit, %{neighbors: neighbors} = state) when length(neighbors) == 0, do: {:noreply, Map.put(state, :mode, :stopped)}
  
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
  
  @doc """
  After sending or receiving gossip, this function is called to check if the node has converged or stopped.
  If the node has :converged, or :stopped before convergence, then the Observer is notified.
  """
  @impl true
  def handle_continue(prev_mode, %{mode: mode} = state) when mode == prev_mode, do: {:noreply, state}
  
  def handle_continue(prev_mode, %{mode: mode, data: data} = state)
  when mode == :converged
  or   mode == :stopped and prev_mode != :converged do
    :ok = GenServer.cast(Proj2.Observer, {:converged, self(), data})
	{:noreply, state}
  end
  
  def handle_continue(_, state), do: {:noreply, state}
  
  # Generates a random delay, according to an exponential distribution.

  defp get_delay() do
    :rand.uniform()
	  |> :math.exp()
	  |> Kernel.*(Application.get_env(:proj2, :delay))
	  |> trunc()
  end
end