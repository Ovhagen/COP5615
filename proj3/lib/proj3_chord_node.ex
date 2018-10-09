defmodule Proj3.ChordNode do
  @moduledoc """
  
  """
  use GenServer
  
  ## Client API
  
  @doc """
  Starting and linking the Agent process.
  """
  def start_link() do
    GenServer.start_link(__MODULE__, %{fingers: List.duplicate(0, 160), data: %{}})
  end
  
  def get()
  
  def put()
  
  def create()
  
  def join()
  
  def stabilize()
  
  def notify()
  
  def fix_fingers()
  
  def check_predecessor()
  
  def find_successor(n, id) do
    case GenServer.call(n, {:successor, id}) do
	  {:ok, node}       -> node
	  {:continue, node} -> find_successor(node, id)
	end
  end
  
  def closest_preceding_node()
  
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