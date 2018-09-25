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
  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end
  
  @doc """
  Tell a GossipNode to transmit its gossip to a random neighbor.
  """
  def transmit_gossip(node) do
    GenServer.cast(node, :transmit)
  end
  
  @doc """
  Send gossip to a GossipNode.
  """
  def receive_gossip(node, gossip) do
    GenServer.cast(node, {:gossip, gossip})
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
  Handle updates to the neighbor list.
  """
  @impl true
  def handle_call({:update_neighbors, neighbors}, _from, {state, _neighbors, tx_fn, rcv_fn, kill_fn}) do
    {:reply, :ok, {state, neighbors, tx_fn, rcv_fn, kill_fn}}
  end
  
  @doc """
  Handle requests to transmit state to a neighbor.
  Generates the gossip based on the current state and casts it to a random neighbor. Then, checks for the kill condition.
  """
  @impl true
  def handle_cast(:transmit, {state, neighbors, tx_fn, _rcv_fn, kill_fn}) do
    {state, gossip} = tx_fn.(state)
    GenServer.cast(Enum.random(neighbors), {:gossip, gossip})
	case kill_fn.(state) do
	  {:ok, state} ->
	    Task.start(fn ->
		  )
	    {:noreply, state}
	  {:kill, state} ->
	    {:stop, :converged, state}
	end
  end
  
  @doc """
  Handle incoming gossip.
  Changes the current state based on the received gossip, then checks for kill condition.
  """
  @impl true
  def handle_cast({:gossip, gossip}, {state, _neighbors, _tx_fn, rcv_fn, kill_fn}) do
    state = rcv_fn.(state, gossip)
	case kill_fn.(state) do
	  {:ok, state} ->
	    {:noreply, state}
	  {:kill, state} ->
	    {:stop, :converged, state}
	end
  end
end