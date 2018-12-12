defmodule Bitcoin.Node do
  @moduledoc """
  This module defines the Node actor, which serves as the fundamental unit of the Bitcoin network.
  Nodes maintain the full blockchain, and are able to validate new transactions and maintain a mempool
  of transactions which are awaiting confirmation.
  
  Each Node may also run a mining operation, in which new blocks are created and added to the blockchain.
  """
  use GenServer
  
  defstruct chain: %Blocktree{}, neighbors: [], mining: false
  
  @type t :: %Bitcoin.Node{
    chain:     Blocktree.t,
    neighbors: [pid],
    mining:    boolean
  }
  
  # Client interface
  
  def start_link(args \\ %Bitcoin.Node{}), do: GenServer.start_link(__MODULE__, args)
  
  def start_miner(pid), do: GenServer.cast(pid, :start_mining)
  
  def stop_miner(pid), do: GenServer.cast(pid, :stop_mining)
  
  def add_neighbor(pid, neighbor), do: GenServer.call(pid, {:neighbor, neighbor})
  
  def relay_tx(pid, tx), do: GenServer.call(pid, {:tx, Transaction.serialize(tx)})
  
  def relay_block(pid, block), do: GenServer.call(pid, {:block, Block.serialize(block)})
  
  def get_mining_data(pid), do: GenServer.call(pid, :mining_data)
  
  # Server callbacks
  
  def init(args), do: {:ok, args}
  
  def handle_call({:neighbor, pid}, _from, state) do
    {:reply, :ok, if(pid in state.neighbors, do: state, else: Map.update!(state, :neighbors, &List.insert_at(&1, 0, pid)))}
  end
  
  def handle_call({:tx, raw_tx}, _from, state) do
    tx = Transaction.deserialize(raw_tx)
    case Blocktree.add_to_mempool(state.chain, tx) do
      {:ok, bt} ->
        Task.start(__MODULE__, :relay, [{:tx, raw_tx}, state.neighbors])
        {:reply, :ok, Map.put(state, :chain, bt)}
      error     -> {:reply, error, state}
    end
  end
  
  def handle_call({:block, raw_block}, _from, state) do
    block = Block.deserialize(raw_block)
    case Blocktree.add_block(state.chain, block) do
      {:ok, bt}     ->
        Task.start(__MODULE__, :relay, [{:block, raw_block}, state.neighbors])
        {:reply, :ok, Map.put(state, :chain, bt)}
      {:orphan, bt} -> {:reply, :orphan, Map.put(state, :chain, bt)}
      error         -> {:reply, error, state}
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
      Task.start(__MODULE__, :relay, [{:block, Block.serialize(block)}, state.neighbors])
      {:reply, :ok, Map.put(state, :chain, bt)}
    else
      {:reply, :ok, state}
    end
  end
  
  def handle_cast(:start_mining, state) do
    if not state.mining do
      Task.start(Miner, :mining_loop, [self(), :crypto.strong_rand_bytes(20), "test"])
      {:noreply, Map.put(state, :mining, true)}
    else
      {:noreply, state}
    end
  end
  
  def handle_cast(:stop_mining, state), do: {:noreply, Map.put(state, :mining, false)}
  
  def relay(msg, neighbors), do: Enum.each(neighbors, &GenServer.call(&1, msg))
end