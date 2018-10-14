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
  def start_link([]) do
    GenServer.start_link(__MODULE__, [])
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
  # def closest_preceding_node(id, i) when i == 0 do
  #   self()
  # end

  # def closest_preceding_node(id, i \\ get([:fingers]) |> length()) do
  #   n = get([:node_hash])
  #   finger_i = get([:fingers, i]) |> elem(0)
  #   if finger_i in (n+1)..id do
  #     #Return the pid of the finger
  #     finger_i |> elem(1)
  #   else
  #     closest_preceding_node(id, i-1)
  #   end
  # end

  ## Server Callbacks

  @doc """
  ChordNode initialization.
  Sets the id to the SHA-1 hash of the node's PID.
  """
  @impl true
  def init(_args) do
    pid = self()
    id = get_id(inspect(pid))
    IO.puts "Child_Init: #{inspect(pid)} with id #{id}"
    {:ok,
      %{
        nid: id,
        predecessor: nil,
        fingers: List.duplicate(%{pid: pid, id: id}, Application.get_env(:proj3, :id_bits)),
        data: %{}
      }
    }
  end

  @doc """
  Handles call for find_successor.
  
  
  """
  def handle_call({:successor, client, id}, _from, %{nid: nid, fingers: fingers} = state) do
    if check_id(id, nid, get_in(hd(fingers), :id)) do
      # Reply to original client with successor
      GenServer.reply(client, {:ok, get_in(hd(fingers), :pid)})
      {:reply, :ok, state}
    else
      # Forward request along the chord
      {:reply, :ok, state, {:continue, {:successor, client, id}}}
    end
  end

  def handle_call({:successor, id}, from, %{nid: nid, fingers: fingers} = state) do
    if check_id(id, nid, get_in(hd(fingers), :id)) do
      # Reply with successor
      {:reply, {:ok, get_in(hd(fingers), :pid)}, state}
    else
      # Forward request along the chord
      {:noreply, state, {:continue, {:successor, from, id}}}
    end
  end

  def handle_continue({:successor, client, id}, from, %{nid: nid, fingers: fingers} = state) do
    node = closest_preceding_node(id, nid, fingers)
    try do
      :ok = GenServer.call(node, {:successor, client, id})
      {:noreply, state}
    catch
      :exit, value ->
        # Node is dead; update the finger table and try again
        {
          :noreply,
          # Replace all occurrences of the dead node with its predecessor
          Map.update(state, :fingers, fn f ->
            Enum.map_reduce(f, self(), &(if get_in(&1, :pid) == node, do: {&2, &2}, else: {&1, &1}))
              |> elem(0)
            end),
          # Callback to continue the search
          {:continue, {:successor, from, id}}
        }
    end
  end
  
  # Returns true if id is in the interval (n, s]. Otherwise returns false.
  defp check_id(id, n, s) when n > s do
    check_id(id, n, :math.pow(2, Application.get_env(:proj3, :id_bits))
      or check_id(id, -1, s)
  end
  
  defp check_id(id, n, s), do: id > n and id <= s

  # Generates a unique, random id by SHA hashing the input string and truncating to the configured bit length
  defp get_id(n) do
    bits = Application.get_env(:proj3, :id_bits)
    <<id::integer-size(bits), _::binary>> = :crypto.hash(:sha, n)
    id
  end

  # Searches fingers for the furthest node that precedes the id
  defp closest_preceding_node(id, nid, fingers) do
    Enum.reverse(fingers)
      |> Enum.reduce_while(self(), fn n, f ->
           if check_id(get_in(n, :id), nid, id-1) do
             {:halt, get_in(n, :pid)}
           else
             {:cont, f}
           end end)
  end
end
