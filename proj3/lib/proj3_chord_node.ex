defmodule Proj3.ChordNode do
  @moduledoc """

  """
  use GenServer

  ## Client API

  @doc """
  Starting and linking the GenServer process.
  node_hash: The hash of the node.
  fingers: Local routing table of the node. A finger consists is {hash, pid}.
  predecessor: Reference to the previous node in the chord ring. (just the hash?)
  data: A hash table with data stored at the node.
  """
  def start_link([]), do: GenServer.start_link(__MODULE__, [])

  @doc """
  Join n to an existing Chord c.
  """
  def join(n, c) when n != c, do: GenServer.call(n, {:join, c})

  def stabilize()

  def notify()

  def fix_fingers()

  def check_predecessor()

  @doc """
  Asks node n to find the successor of id.
  If successful returns a tuple with :ok, the pid of the successor, and the number of calls needed to complete the request.
  """
  def find_successor(n, id) do
    if get_id(n) == id do
      {:ok, n, 0}
    else
      try do
        GenServer.call(n, {:successor, id})
      catch
        :exit, _ -> {:error, "Call failed: no response from node"}
      end
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
    id = get_id(inspect(pid))
    IO.puts "Child_Init: #{inspect(pid)} with id #{id}"
    {
      :ok,
      %{
        nid: id,
        predecessor: nil,
        fingers: List.duplicate(%{pid: pid, id: id}, id_bits()),
        next_finger = 0,
        data: %{}
      }
    }
  end

  @doc """
  Handles call for find_successor.
  The 2-arity version is used for calls coming directly from the client, and responds directly if the successor is found immediately.
  The 4-arity version is used for forwarded calls along the Chord, so that the node which eventually resolves the call can respond to the original client.
  This structure allows the call to proceed without blocking every node along the path, and ensures that timeouts due to failed nodes are caught correctly.
  
  Since both versions may need to forward a request, that code is moved into a :continue handler.
  """
  def handle_call({:successor, client, id, count}, _from, %{nid: nid, fingers: fingers} = state) do
    if between?(id, nid, get_in(hd(fingers), :id)) do
      # Reply to original client with successor
      GenServer.reply(client, {:ok, hd(fingers), count})
      {:reply, :ok, state}
    else
      # Forward request along the chord
      {:reply, :ok, state, {:continue, {:successor, client, id, count}}}
    end
  end

  def handle_call({:successor, id}, from, %{nid: nid, fingers: fingers} = state) do
    if between?(id, nid, get_in(hd(fingers), :id)) do
      # Reply with successor
      {:reply, {:ok, hd(fingers), 0}, state}
    else
      # Forward request along the chord
      {:noreply, state, {:continue, {:successor, from, id, 0}}}
    end
  end
  
  def handle_call({:join, c}, _from, %{nid: nid, fingers: fingers} = state) do
    case find_successor(c, nid) do
      {:ok, s, _} ->
        {
          :reply,
          :ok,
          state |> Map.put(:fingers, update_fingers(fingers, s, nid))
            |> Map.put(:next_finger, get_id(s)-nid+max_id() |> mod(max_id()) |> :math.log2() |> trunc()),
          {:continue, :stabilize}
        }
      {:error, _} ->
        # The node did not respond, so the join failed
        {:reply, {:error, "Join failed: no response from node"}, state}
    end
  end

  @doc """
  Handles forwarding of find_successor requests.
  If the recipient of the forwarded request fails to respond, the forward attempt is repeated with the next best predecessor.
  """
  def handle_continue({:successor, client, id, count}, %{nid: nid, fingers: fingers} = state) do
    # Find the closest predecessor in the finger table
    n = closest_preceding_node(fingers, id, nid)
    try do
      if get_in(n, :id) == nid do
        # We are the closest predecessor, so just reply to the client and do not forward the request. This should only happen if every other node has failed.
        GenServer.reply(client, {:ok, n, count})
      else
        # Call the node with the successor request. If the node responds, we can safely exit.
        :ok = GenServer.call(get_in(n, :pid), {:successor, client, id, count+1})
      end
      {:noreply, state}
    catch
      :exit, _ ->
        # The call failed so we assume the node has failed and remove it from the finger table, then recurse to try the next best predecessor.
        {
          :noreply,
          # Replace all occurrences of the failed node with its successor
          Map.update!(state, :fingers, &remove_finger(&1, n, nid)),
          # Callback to continue the search
          {:continue, {:successor, client, id, count}}
        }
    end
  end
  
  @doc """
  Handles fix_fingers requests.
  Searches for a successor for the next finger, then 
  """
  def handle_continue(:fix_fingers, %{nid: nid, fingers: [s | fingers], next_finger: next} = state) do
    case find_successor(get_in(s, :pid), nid + :math.pow(2, next)) do
      {:ok, f, _} ->
        {
          :noreply,
          state
            |> Map.put(:next_finger, next_finger?(get_in(f, :id), nid))
            |> Map.update!(:fingers, fn fs ->
                 e = Enum.at(fs, next)
                 # If the new finger is further than the old finger, then the old finger must have failed. Remove it first, then add the new finger.
                 if between?(e, nid, f), do: remove_finger(fs, e, nid), else: fs
                   |> add_finger(f, nid)
               end)
        }
      {:error, _} ->
        # The successor has failed. Remove it from the finger table, notify our new successor, and try again.
        fingers = remove_finger([s] ++ fingers, s)
        :ok = notify(get_in(hd(fingers), :pid), self())
        {
          :noreply,
          Map.put(state, :fingers, fingers),
          {:continue, :fix_fingers}
        }
    end
  end
  
  ## Private implementation functions
  
  # Retreives the value of the :id_bits configuration parameter.
  defp id_bits(), do: Application.get_env(:proj3, :id_bits)
  
  # Returns the modulus of the Chord ids, equal to 2^m where m is the number of id bits.
  defp max_id(), do: :math.pow(2, id_bits())
  
  # Returns true if id is in the interval (n, s]. Otherwise returns false.
  # For convenience, you can pass a map containing an :id key for any of the parameters.
  defp between?(id, n, s) when is_map(id), do: between?(get_in(id, :id), n, s)
  defp between?(id, n, s) when is_map(n),  do: between?(id, get_in(n, :id), s)
  defp between?(id, n, s) when is_map(s),  do: between?(id, n, get_in(s, :id))
  defp between?(id, n, s) when n >= s do
    between?(id, n, max_id()-1)
      or between?(id, -1, s)
  end
  defp between?(id, n, s), do: id > n and id <= s

  # Generates a unique, random id by SHA hashing the input string and truncating to the configured bit length
  defp get_id(n) do
    bits = id_bits()
    <<id::integer-size(bits), _::binary>> = :crypto.hash(:sha, n)
    id
  end

  # Searches fingers for the furthest node that precedes the id
  defp closest_preceding_node(fingers, id, nid) do
    Enum.reverse(fingers)
      |> Enum.reduce_while(self(), fn n, f ->
           if between?(n, nid, id-1) do
             {:halt, n}
           else
             {:cont, f}
           end end)
  end
  
  # Determines the next finger to check, based on the id of the last finger found.
  defp next_finger?(fid, nid), do: fid-nid+max_id()+1 |> rem(max_id()) |> :math.log2() |> Float.ceil() |> trunc() |> rem(id_bits())
  
  # Updates the finger table with a new node.
  # Replaces each entry of the table where n is a closer successor than the existing finger.
  defp add_finger(fingers, n, nid) do
    Enum.map_reduce(fingers, 1, fn f, acc ->
      if between?(n, rem(nid+acc, max_id()), f) do
        {n, acc*2}
      else
        {f, acc*2}
      end
    end)
  end
  
  # Removes a node from the finger table, replacing all occurrences with its next known successor.
  defp remove_finger(fingers, n, nid) do
    fingers
      |> Enum.reverse()
      |> Enum.map_reduce(fingers, %{pid: self(), id: nid}, &(if &1 == n, do: {&2, &2}, else: {&1, &1}))
      |> elem(0)
  end
end
