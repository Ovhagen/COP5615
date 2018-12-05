defmodule Proj4.MinerNode do
  @moduledoc """
  """
  use GenServer

  #TODO Periodically check messages and collect new blocks, new transactions.
  #TODO Mine asynchronously (or synchronous) then create block if block hash is found.
  #TODO Keep active list of blocks, transactions and neighbors
  #TODO Verify blocks and accept them. If failed send back failure message. (for future version?)
  #TODO Send out new blocks, merkle proofs, block requests for full nodes,
  #block header requests from clients.
  #TODO Have active wallet



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
