defmodule Proj3.ChordNode do
  @moduledoc """

  """
  use GenServer

  ## Client API

  @doc """
  Starting and linking the Agent process.
  node_hash: The hash of the node.
  fingers: Local routing table of the node. A finger consists is {hash, pid}.
  predecessor: Reference to the previous node in the chord ring. (just the hash?)
  data: A hash table with data stored at the node.
  """
  def start_link() do
    GenServer.start_link(__MODULE__, [])
  end

  @doc """
  Gets a current value in the state.
  Keys define sequence of keys to access.
  """
  def get(keys) do
    state |> get_in(keys)
  end

  @doc """
  Updates the state with a new value.
  Keys define sequence of keys to access.
  Value is the new value to update with.
  """
  def put(keys, value) do
    state |> put_in(keys, value)
  end

  @doc """
  Creates a chord ring.
  Called by the first node in a new chord network.
  Sets the successor in fingers[1] to itself with corresponding hash.
  Maps the node's hash with its own pid as a tuple.
  """
  def create() do
    state = put([:fingers, 1], {get([:node_hash]), self()})
  end

  def join()

  def stabilize()

  def notify()

  def fix_fingers()

  def check_predecessor()

  @doc """
  Asks node n to find the successor of id.
  """
  def find_successor(n, id) do
    GenServer.call(n, {:successor, id})
  end

  @doc """
  Searches the local table for the highest predecessor of id.
  """
  def closest_preceding_node(id, i) when i == 0 do
    self()
  end

  def closest_preceding_node(id, i \\ get([:fingers]) |> length()) do
    n = get([:node_hash])
    finger_i = get([:fingers, i]) |> elem(0)
    if finger_i in (n+1)..id do
      #Return the pid of the finger
      finger_i |> elem(1)
    else
      closest_preceding_node(id, i-1)
    end
  end

  ## Server Callbacks

  @doc """
  ChordNode initialization.
  Sets the id to the SHA-1 hash of the node's PID.
  """
  @impl true
  def init(_args) do
    pid = self()
    {:ok,
      %{
        nid: get_id(inspect(pid)),
        predecessor: nil,
        fingers: List.duplicate(pid, Application.get_env(:proj3, :id_bits)),
        data: %{}
      }
    }
  end

  @doc """
  Handles call for find_successor.
  """
  def handle_call({:successor, client, id}, _from, %{nid: nid, fingers: fingers} = state) do
    if check_id(id, nid, get_id(hd(fingers))) do
      # Reply to original client with successor
      GenServer.reply(client, {:ok, hd(fingers)})
      {:reply, :ok, state}
    else
      # Forward request along the chord
      {:reply, :ok, state, {:continue, {:successor, client, id}}}
    end
  end
  
  def handle_call({:successor, id}, from, %{nid: nid, fingers: fingers} = state) do
    if id in (nid+1)..get_id(hd(fingers)) do
      # Reply with successor
      {:reply, {:ok, hd(fingers)}, state}
    else
      # Forward request along the chord
      {:noreply, state, {:continue, {:successor, from, id}}}
    end
  end
  
  def handle_continue({:successor, client, id}, %{fingers: fingers} = state) do
    node = closest_preceding_node(id)
    try do
      :ok = GenServer.call(node, {:successor, client, id})
      {:noreply, state}
    catch
      :exit, value ->
        # Node is dead; update the finger table and try again
        
    end
  end
  
  def check_id() do

  defp get_id(n) do
    bits = Application.get_env(:proj3, :id_bits)
    <<id::integer-size(bits), _::binary>> = :crypto.hash(:sha, n)
    id
  end
end
