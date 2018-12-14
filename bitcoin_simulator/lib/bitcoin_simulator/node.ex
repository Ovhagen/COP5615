defmodule Bitcoin.Node do
  @moduledoc """
  This module defines the Node actor, which serves as the fundamental unit of the Bitcoin network.
  Nodes maintain the full blockchain, and are able to validate new transactions and maintain a mempool
  of transactions which are awaiting confirmation.
  
  Each Node may also run a mining operation, in which new blocks are created and added to the blockchain.
  """
  use GenServer
  
  defstruct chain: %Blocktree{}, neighbors: [], wallet: nil, mining: false
  
  @type t :: %Bitcoin.Node{
    chain:     Blocktree.t,
    neighbors: [pid],
    wallet:    pid,
    mining:    boolean
  }
  
  # Client interface
  
  def start_link(args \\ %Bitcoin.Node{}), do: GenServer.start_link(__MODULE__, args)
  
  def child_spec(args) do
    %{
      id:    __MODULE__,
      start: {
        Bitcoin.Node,
        :start_link,
        [%Bitcoin.Node{
          chain:     Blocktree.genesis,
          neighbors: args.neighbors,
          wallet:    args.wallet,
          mining:    false
        }]}
    }
  end
  
  def start_mining(pid), do: GenServer.cast(pid, :start_mining)
  
  def stop_mining(pid), do: GenServer.cast(pid, :stop_mining)
  
  def add_neighbor(pid, neighbor), do: GenServer.call(pid, {:add_neighbor, neighbor})
  
  def verify_tx(pid, tx), do: GenServer.call(pid, {:verify_tx, Transaction.serialize(tx)})
  
  def relay_tx(pid, tx), do: GenServer.cast(pid, {:relay_tx, Transaction.serialize(tx)})
  
  def relay_block(pid, block), do: GenServer.cast(pid, {:relay_block, Block.Header.serialize(block.header), self()})
  
  def get_block(pid, hash), do: GenServer.cast(pid, {:get_block, hash, self()})
  
  def send_block(pid, raw_block), do: GenServer.cast(pid, {:block_data, raw_block})
  
  def get_mining_data(pid), do: GenServer.call(pid, :mining_data)
  
  # Server callbacks
  
  @impl true
  def init(args), do: {:ok, args}
  
  ## Handlers
  
  @impl true
  def handle_call({:add_neighbor, pid}, _from, state) do
    {:reply, :ok, if(pid in state.neighbors, do: state, else: Map.update!(state, :neighbors, &List.insert_at(&1, 0, pid)))}
  end
  
  def handle_call({:verify_tx, raw_tx}, _from, state) do
    with tx        <- Transaction.deserialize(raw_tx),
         {:ok, bt} <- Blocktree.add_to_mempool(state.chain, tx)
    do
      {:reply, :ok, Map.put(state, :chain, bt), {:continue, {:relay, {:relay_tx, tx}}}}
    else
      error -> {:reply, error, state}
    end
  end
  
  def handle_call(:mining_data, _from, state) do
    if state.mining do
      {:reply, {:ok, state.chain.mainchain}, state}
    else
      {:reply, :halt, state}
    end
  end
  
  def handle_call({:mined_block, block}, _from, state) do
    if block.header.previous_hash == state.chain.mainchain.tip.hash do
      {:ok, bt} = Blocktree.add_block(state.chain, block)
      {:reply, :ok, Map.put(state, :chain, bt), {:continue, {:relay, {:relay_block, block}}}}
    else
      {:reply, :ok, state}
    end
  end
  
  @impl true
  def handle_cast({:relay_tx, raw_tx}, state) do
    tx = Transaction.deserialize(raw_tx)
    case Blocktree.add_to_mempool(state.chain, tx) do
      {:ok, bt} -> {:noreply, Map.put(state, :chain, bt), {:continue, {:relay, {:relay_tx, tx}}}}
      _error    -> {:noreply, state}
    end
  end
  
  def handle_cast({:relay_block, raw_header, from}, state) do
    header = Block.Header.deserialize(raw_header)
    with :ok <- check_header(header, state.chain) do
      :ok = get_block(from, Block.Header.hash(header))
    end
    {:noreply, state}
  end
  
  def handle_cast({:get_block, hash, from}, state) do
    with {:ok, block} <- Blockchain.get_block_by_hash(state.chain.mainchain, hash),
         raw_block    <- Block.serialize(block)
    do
      :ok = send_block(from, raw_block)
    end
    {:noreply, state}
  end
  
  def handle_cast({:block_data, raw_block}, state) do
    with block            <- Block.deserialize(raw_block),
         {:ok, bt}        <- Blocktree.add_block(state.chain, block)
    do
      {:noreply, Map.put(state, :chain, bt), {:continue, {:relay, {:relay_block, block}}}}
    else
      {:orphan, bt}  -> {:noreply, Map.put(state, :chain, bt)}
      _error         -> {:noreply, state}
    end
  end
  
  def handle_cast(:start_mining, state) do
    if not state.mining do
      Task.start_link(Miner, :mining_loop, [self(), state.wallet, "test"])
      {:noreply, Map.put(state, :mining, true)}
    else
      {:noreply, state}
    end
  end
  
  def handle_cast(:stop_mining, state), do: {:noreply, Map.put(state, :mining, false)}
  
  @impl true
  def handle_continue({:relay, {relay_fun, arg}}, state) do
    :ok = Enum.each(state.neighbors, &apply(__MODULE__, relay_fun, [&1, arg]))
    {:noreply, state}
  end
  
  ## Support functions
  
  defp check_header(header, bt) do
    cond do
      Block.Header.hash(header) in Blocktree.get_tip_hashes(bt) ->
        :duplicate
      DateTime.diff(DateTime.utc_now, header.timestamp) > 60 ->
        :stale
      true ->
        :ok
    end
  end
end